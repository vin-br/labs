"""
Cancer Detection - Model Training Engine
"""

import logging
from pathlib import Path

import joblib
import optuna
import polars as pl
from sklearn import model_selection, neighbors, tree
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger(__name__)
optuna.logging.set_verbosity(optuna.logging.WARNING)


def load_and_prepare_data(
    data_path: str = "data/breast_cancer.parquet",
) -> tuple:
    """Load parquet, split 80/20 train/test, scale features."""
    breast_cancer = pl.read_parquet(data_path)

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


def save_model(model: object, name: str, models_dir: str = "models") -> None:
    """Persist a trained model to disk via joblib."""
    path = Path(models_dir)
    path.mkdir(exist_ok=True)
    joblib.dump(model, path / f"{name}.joblib")
    log.info("Saved model → %s/%s.joblib", models_dir, name)


def train_decision_tree(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Train Decision Tree with 5-fold cross-validation, evaluate on test set."""
    model = tree.DecisionTreeClassifier(random_state=42)

    cross_validation_scores = model_selection.cross_validate(
        model, features_train, target_train, cv=5, scoring=["accuracy"], return_train_score=True
    )
    model.fit(features_train, target_train)
    test_predictions = model.predict(features_test)

    log.info("Decision Tree - Cross-validation Accuracy: %.4f", cross_validation_scores["test_accuracy"].mean())
    log.info("Decision Tree - Test Accuracy:             %.4f\n", accuracy_score(target_test, test_predictions))

    return model, cross_validation_scores, test_predictions


def train_knn(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune KNN k via Optuna (5-fold cross-validation), retrain on full train set, evaluate on test."""

    def objective(trial: optuna.Trial) -> float:
        k = trial.suggest_int("n_neighbors", 2, 41)
        model = neighbors.KNeighborsClassifier(n_neighbors=k)
        return model_selection.cross_val_score(model, features_train, target_train, cv=5, scoring="accuracy").mean()

    study = optuna.create_study(direction="maximize")
    study.optimize(objective, n_trials=40)

    model = neighbors.KNeighborsClassifier(n_neighbors=study.best_params["n_neighbors"])
    model.fit(features_train, target_train)
    test_predictions = model.predict(features_test)

    log.info("KNN best k=%d (cross-validation accuracy: %.4f)", study.best_params["n_neighbors"], study.best_value)
    log.info("\nTest Set Metrics:\n%s", classification_report(target_test, test_predictions))

    return model, study, test_predictions
