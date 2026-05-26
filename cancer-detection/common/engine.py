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
from catboost import CatBoostClassifier
from sklearn import ensemble, model_selection, svm
from sklearn.metrics import accuracy_score, classification_report
from sklearn.neural_network import MLPClassifier

from .visualizations import plot_mlp_loss_curve

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger(name=__name__)
optuna.logging.set_verbosity(verbosity=optuna.logging.WARNING)
mlflow.sklearn.autolog(log_models=True, serialization_format="pickle")

ROOT = Path(__file__).parent.parent


def train_random_forest(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Train Random Forest with default parameters, evaluate on test set."""
    with mlflow.start_run(run_name="random_forest"):
        model = ensemble.RandomForestClassifier(random_state=42)
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        log.info("Random Forest accuracy: %.4f\n%s",
                 accuracy_score(target_test, test_predictions),
                 classification_report(target_test, test_predictions))

    return model, None, test_predictions

def train_catboost(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Train CatBoost with default parameters, evaluate on test set."""
    with mlflow.start_run(run_name="catboost"):
        model = CatBoostClassifier(random_state=42, verbose=0)
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        log.info("CatBoost accuracy: %.4f\n%s",
                 accuracy_score(target_test, test_predictions),
                 classification_report(target_test, test_predictions))

    return model, None, test_predictions


def train_hist_gradient_boosting(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Train HistGradientBoosting with default parameters, evaluate on test set."""
    with mlflow.start_run(run_name="hist_gradient_boosting"):
        model = ensemble.HistGradientBoostingClassifier(random_state=42)
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        log.info("HistGradientBoosting accuracy: %.4f\n%s",
                 accuracy_score(target_test, test_predictions),
                 classification_report(target_test, test_predictions))

    return model, None, test_predictions


def train_svc(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Train SVC with default parameters, evaluate on test set."""
    with mlflow.start_run(run_name="svc"):
        model = svm.SVC(random_state=42)
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        log.info("SVC accuracy: %.4f\n%s",
                 accuracy_score(target_test, test_predictions),
                 classification_report(target_test, test_predictions))

    return model, None, test_predictions


def train_mlp(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune MLP architecture via Optuna (5-fold cross-validation), retrain, evaluate on test set."""
    with mlflow.start_run(run_name="mlp"):

        def objective(trial: optuna.Trial) -> float:
            hidden_layer_sizes = tuple(
                trial.suggest_int(f"units_layer_{i}", low=16, high=128, step=16)
                for i in range(trial.suggest_int(name="n_layers", low=1, high=3))
            )
            model = MLPClassifier(
                hidden_layer_sizes=hidden_layer_sizes,
                alpha=trial.suggest_float(name="alpha", low=1e-4, high=1e-1, log=True),
                learning_rate_init=trial.suggest_float(name="learning_rate_init", low=1e-4, high=1e-1, log=True), # noqa: E501
                max_iter=1200,
                random_state=42,
            )
            return model_selection.cross_val_score(model, features_train, target_train, cv=5, scoring="accuracy").mean()  # noqa: E501

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

        mlflow.log_figure(figure=plot_mlp_loss_curve(model, model_name="MLP"), artifact_file="loss_curve.html") # noqa: E501

        log.info("MLP best params: layers=%s, alpha=%.4f, lr=%.4f (cv accuracy: %.4f)\n%s",
                 hidden_layer_sizes, best["alpha"], best["learning_rate_init"], study.best_value,
                 classification_report(target_test, test_predictions))

    return model, study, test_predictions
