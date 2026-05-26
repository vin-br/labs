"""
Cancer Detection - Model Training Engine
"""
import matplotlib

matplotlib.use("Agg")

import logging
from pathlib import Path

import mlflow
import mlflow.sklearn
import optuna
import polars as pl
from sklearn import model_selection, neighbors, tree
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import StandardScaler

from common.visualizations import plot_mlp_loss_curve, plot_optuna_trials

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger(__name__)
optuna.logging.set_verbosity(optuna.logging.WARNING)
mlflow.sklearn.autolog(log_models=True, serialization_format="pickle")

ROOT = Path(__file__).parent.parent


def load_and_prepare_data(
    data_path: str = "data/breast_cancer.parquet",
) -> tuple:
    """Load parquet, split 80/20 train/test, scale features."""
    breast_cancer = pl.read_parquet(ROOT / data_path)

    feature_columns = breast_cancer.columns[
        breast_cancer.columns.index("radius_mean"):breast_cancer.columns.index("fractal_dimension_worst") + 1
    ]
    features = breast_cancer.select(feature_columns).to_numpy()
    target = breast_cancer["diagnosis"].to_numpy()

    features_train, features_test, target_train, target_test = train_test_split(
        features, target, test_size=0.2, random_state=42
    )

    scaler = StandardScaler()
    features_train = scaler.fit_transform(features_train)
    features_test = scaler.transform(features_test)

    return features_train, features_test, target_train, target_test, scaler


def train_decision_tree(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Train Decision Tree with 5-fold cross-validation, evaluate on test set."""
    with mlflow.start_run(run_name="decision_tree"):
        model = tree.DecisionTreeClassifier(random_state=42)

        cross_validation_scores = model_selection.cross_validate(
            model, features_train, target_train, cv=5, scoring=["accuracy"], return_train_score=True
        )
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        log.info("Decision Tree - Cross-validation Accuracy: %.4f", cross_validation_scores["test_accuracy"].mean())
        log.info("Decision Tree - Test Accuracy:             %.4f\n%s",
                 accuracy_score(target_test, test_predictions),
                 classification_report(target_test, test_predictions))

    return model, cross_validation_scores, test_predictions


def train_knn(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune KNN k via Optuna (5-fold cross-validation), retrain on full train set, evaluate on test."""
    with mlflow.start_run(run_name="knn"):

        def objective(trial: optuna.Trial) -> float:
            k = trial.suggest_int("n_neighbors", 2, 41)
            model = neighbors.KNeighborsClassifier(n_neighbors=k)
            return model_selection.cross_val_score(model, features_train, target_train, cv=5, scoring="accuracy").mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=40)

        model = neighbors.KNeighborsClassifier(n_neighbors=study.best_params["n_neighbors"])
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        mlflow.log_figure(plot_optuna_trials(study, "KNN"), "optuna_trials.html")

        log.info("KNN best k=%d (cross-validation accuracy: %.4f)\n%s",
                 study.best_params["n_neighbors"], study.best_value,
                 classification_report(target_test, test_predictions))

    return model, study, test_predictions


def train_mlp(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune MLP architecture via Optuna (5-fold cross-validation), retrain, evaluate on test set."""
    with mlflow.start_run(run_name="mlp"):

        def objective(trial: optuna.Trial) -> float:
            hidden_layer_sizes = tuple(
                trial.suggest_int(f"units_layer_{i}", 16, 128, step=16)
                for i in range(trial.suggest_int("n_layers", 1, 3))
            )
            model = MLPClassifier(
                hidden_layer_sizes=hidden_layer_sizes,
                alpha=trial.suggest_float("alpha", 1e-4, 1e-1, log=True),
                learning_rate_init=trial.suggest_float("learning_rate_init", 1e-4, 1e-1, log=True),
                max_iter=1200,
                random_state=42,
            )
            return model_selection.cross_val_score(model, features_train, target_train, cv=5, scoring="accuracy").mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=40)

        best = study.best_params
        hidden_layer_sizes = tuple(best[f"units_layer_{i}"] for i in range(best["n_layers"]))

        model = MLPClassifier(
            hidden_layer_sizes=hidden_layer_sizes,
            alpha=best["alpha"],
            learning_rate_init=best["learning_rate_init"],
            max_iter=1200,
            random_state=42,
        )
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        mlflow.log_figure(plot_mlp_loss_curve(model, "MLP"), "loss_curve.html")

        log.info("MLP best params: layers=%s, alpha=%.4f, lr=%.4f (cv accuracy: %.4f)\n%s",
                 hidden_layer_sizes, best["alpha"], best["learning_rate_init"], study.best_value,
                 classification_report(target_test, test_predictions))

    return model, study, test_predictions
