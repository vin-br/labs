"""Training engine with Optuna hyperparameter optimization and TensorBoard logging.

Orchestrates: preprocessing -> Optuna search -> final training -> evaluation.
"""

from pathlib import Path

import numpy as np
import optuna
import torch
import torch.nn as nn
from sklearn.metrics import accuracy_score, classification_report, f1_score
from torch.utils.tensorboard import SummaryWriter

from .model import CycloneClassifier, evaluate, get_device, make_loader, train_epoch
from .preprocessing import prepare_data

MODELS_DIR = Path(__file__).resolve().parent.parent / "models"
RUNS_DIR = Path(__file__).resolve().parent / "runs"


def _objective(
    trial: optuna.Trial,
    X_train: np.ndarray,
    y_train: np.ndarray,
    X_val: np.ndarray,
    y_val: np.ndarray,
    n_classes: int,
    device: torch.device,
    epochs: int,
    log_dir: Path,
) -> float:
    """Optuna objective: train a model with suggested hyperparameters and return val accuracy."""
    n_layers = trial.suggest_int("n_layers", 1, 4)
    hidden_dims = [trial.suggest_int(f"hidden_{i}", 64, 512) for i in range(n_layers)]
    dropout = trial.suggest_float("dropout", 0.05, 0.5)
    lr = trial.suggest_float("lr", 1e-4, 1e-2, log=True)
    batch_size = trial.suggest_categorical("batch_size", [64, 128, 256, 512])
    weight_decay = trial.suggest_float("weight_decay", 1e-6, 1e-3, log=True)

    model = CycloneClassifier(X_train.shape[1], n_classes, hidden_dims, dropout).to(
        device
    )
    optimizer = torch.optim.Adam(model.parameters(), lr=lr, weight_decay=weight_decay)
    criterion = nn.CrossEntropyLoss()

    train_loader = make_loader(X_train, y_train, batch_size)
    val_loader = make_loader(X_val, y_val, batch_size, shuffle=False)

    writer = SummaryWriter(log_dir=str(log_dir / f"trial_{trial.number}"))

    best_val_acc = 0.0
    for epoch in range(epochs):
        train_loss, train_acc = train_epoch(
            model, train_loader, criterion, optimizer, device
        )
        val_loss, val_acc, _, _ = evaluate(model, val_loader, criterion, device)

        writer.add_scalars("Loss", {"train": train_loss, "val": val_loss}, epoch)
        writer.add_scalars("Accuracy", {"train": train_acc, "val": val_acc}, epoch)
        best_val_acc = max(best_val_acc, val_acc)

        trial.report(val_acc, epoch)
        if trial.should_prune():
            writer.close()
            raise optuna.TrialPruned()

    writer.close()
    return best_val_acc


def run(
    data_path: Path | None = None,
    n_trials: int = 50,
    epochs: int = 50,
    device: str = "auto",
    augment: bool = False,
    log_dir: str = "runs",
) -> dict:
    """Full training pipeline: preprocess -> Optuna search -> retrain best -> evaluate.

    Returns dict with best_params, accuracy, f1, and model_path.
    """
    device_obj = get_device(device)
    output_dir = MODELS_DIR
    output_dir.mkdir(parents=True, exist_ok=True)
    log_path = RUNS_DIR if log_dir == "runs" else Path(log_dir)
    log_path.mkdir(parents=True, exist_ok=True)

    print(f"Device: {device_obj}")

    # Preprocess
    data = prepare_data(data_path, augment=augment)
    X_train, X_test = data["X_train"], data["X_test"]
    y_train, y_test = data["y_train"], data["y_test"]
    n_classes = data["n_classes"]

    print(f"Train: {X_train.shape[0]:,} samples | Test: {X_test.shape[0]:,} samples")
    print(f"Features: {X_train.shape[1]} | Classes: {n_classes}")

    # Optuna hyperparameter search
    study = optuna.create_study(
        direction="maximize",
        pruner=optuna.pruners.MedianPruner(n_warmup_steps=5),
    )
    study.optimize(
        lambda trial: _objective(
            trial,
            X_train,
            y_train,
            X_test,
            y_test,
            n_classes,
            device_obj,
            epochs,
            log_path,
        ),
        n_trials=n_trials,
    )

    best = study.best_trial
    print(f"\nBest trial #{best.number}: accuracy={best.value:.4f}")
    print(f"Params: {best.params}")

    # Retrain best model on full training data
    params = best.params
    hidden_dims = [params[f"hidden_{i}"] for i in range(params["n_layers"])]
    model = CycloneClassifier(
        X_train.shape[1],
        n_classes,
        hidden_dims,
        params["dropout"],
    ).to(device_obj)
    optimizer = torch.optim.Adam(
        model.parameters(),
        lr=params["lr"],
        weight_decay=params["weight_decay"],
    )
    criterion = nn.CrossEntropyLoss()

    train_loader = make_loader(X_train, y_train, params["batch_size"])
    test_loader = make_loader(X_test, y_test, params["batch_size"], shuffle=False)

    writer = SummaryWriter(log_dir=str(log_path / "best_model"))
    for epoch in range(epochs):
        train_loss, train_acc = train_epoch(
            model, train_loader, criterion, optimizer, device_obj
        )
        val_loss, val_acc, _, _ = evaluate(model, test_loader, criterion, device_obj)
        writer.add_scalars("Loss", {"train": train_loss, "val": val_loss}, epoch)
        writer.add_scalars("Accuracy", {"train": train_acc, "val": val_acc}, epoch)
    writer.close()

    # Final evaluation
    _, _, preds, targets = evaluate(model, test_loader, criterion, device_obj)
    acc = accuracy_score(targets, preds)
    f1 = f1_score(targets, preds, average="weighted")

    stage_names = [f"Stage {c}" for c in data["label_encoder"].classes_]

    print(f"\nTest Accuracy: {acc:.4f}")
    print(f"Test F1 (weighted): {f1:.4f}")
    print(f"\n{classification_report(targets, preds, target_names=stage_names)}")

    # Save model
    model_path = output_dir / "best_model.pt"
    torch.save(
        {
            "model_state_dict": model.state_dict(),
            "params": params,
            "n_classes": n_classes,
            "input_dim": X_train.shape[1],
            "hidden_dims": hidden_dims,
            "feature_names": data["feature_names"],
        },
        model_path,
    )

    print(f"Model saved to {model_path}")
    print(f"TensorBoard: tensorboard --logdir {log_path}")

    return {"accuracy": acc, "f1": f1, "params": params, "model_path": model_path}
