"""CycloneClassifier model definition and training utilities."""

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset


class CycloneClassifier(nn.Module):
    """Feedforward MLP for cyclone intensity stage classification.

    Architecture per hidden layer: Linear -> BatchNorm -> ReLU -> Dropout.
    Final layer: Linear (raw logits for CrossEntropyLoss).
    """

    def __init__(
        self,
        input_dim: int,
        n_classes: int,
        hidden_dims: list[int],
        dropout: float,
    ):
        super().__init__()
        layers: list[nn.Module] = []
        prev = input_dim
        for h in hidden_dims:
            layers.extend(
                [
                    nn.Linear(prev, h),
                    nn.BatchNorm1d(h),
                    nn.ReLU(),
                    nn.Dropout(dropout),
                ]
            )
            prev = h
        layers.append(nn.Linear(prev, n_classes))
        self.net = nn.Sequential(*layers)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)


def make_loader(
    X: np.ndarray,
    y: np.ndarray,
    batch_size: int,
    shuffle: bool = True,
) -> DataLoader:
    ds = TensorDataset(
        torch.from_numpy(X).float(),
        torch.from_numpy(y).long(),
    )
    return DataLoader(ds, batch_size=batch_size, shuffle=shuffle)


def train_epoch(
    model: nn.Module,
    loader: DataLoader,
    criterion: nn.Module,
    optimizer: torch.optim.Optimizer,
    device: torch.device,
) -> tuple[float, float]:
    """Run one training epoch. Returns (avg_loss, accuracy)."""
    model.train()
    total_loss, correct, total = 0.0, 0, 0
    for X, y in loader:
        X, y = X.to(device), y.to(device)
        optimizer.zero_grad()
        out = model(X)
        loss = criterion(out, y)
        loss.backward()
        optimizer.step()
        total_loss += loss.item() * X.size(0)
        correct += (out.argmax(1) == y).sum().item()
        total += X.size(0)
    return total_loss / total, correct / total


@torch.no_grad()
def evaluate(
    model: nn.Module,
    loader: DataLoader,
    criterion: nn.Module,
    device: torch.device,
) -> tuple[float, float, np.ndarray, np.ndarray]:
    """Evaluate model. Returns (avg_loss, accuracy, predictions, targets)."""
    model.eval()
    total_loss, correct, total = 0.0, 0, 0
    all_preds: list[np.ndarray] = []
    all_targets: list[np.ndarray] = []
    for X, y in loader:
        X, y = X.to(device), y.to(device)
        out = model(X)
        loss = criterion(out, y)
        total_loss += loss.item() * X.size(0)
        preds = out.argmax(1)
        correct += (preds == y).sum().item()
        total += X.size(0)
        all_preds.append(preds.cpu().numpy())
        all_targets.append(y.cpu().numpy())
    return (
        total_loss / total,
        correct / total,
        np.concatenate(all_preds),
        np.concatenate(all_targets),
    )


def get_device(requested: str = "auto") -> torch.device:
    if requested != "auto":
        return torch.device(requested)
    if torch.cuda.is_available():
        return torch.device("cuda")
    if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        return torch.device("mps")
    return torch.device("cpu")
