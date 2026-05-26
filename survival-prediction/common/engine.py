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
from sklearn import ensemble, model_selection, neighbors, svm
from sklearn.metrics import accuracy_score, classification_report

from common.visualizations import plot_optuna_trials

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger(name=__name__)
optuna.logging.set_verbosity(verbosity=optuna.logging.WARNING)
mlflow.sklearn.autolog(log_models=True, serialization_format="pickle")

ROOT = Path(__file__).parent.parent


def train_knn(
    features_train, features_val, target_train, target_valid
) -> tuple:
    """Tune KNN k via Optuna (5-fold cross-validation), retrain on train set, evaluate on validation set."""  # noqa: E501
    with mlflow.start_run(run_name="knn"):

        def objective(trial: optuna.Trial) -> float:
            k = trial.suggest_int(name="n_neighbors", low=2, high=41)
            model = neighbors.KNeighborsClassifier(n_neighbors=k)
            return model_selection.cross_val_score(model, features_train, target_train, cv=5, scoring="accuracy").mean()  # noqa: E501

        study = optuna.create_study(direction="maximize")
        study.optimize(func=objective, n_trials=40)

        model = neighbors.KNeighborsClassifier(n_neighbors=study.best_params["n_neighbors"])
        model.fit(features_train, target_train)
        valid_predictions = model.predict(features_val)

        mlflow.log_figure(plot_optuna_trials(study, model_name="KNN", param_name="n_neighbors"), artifact_file="optuna_trials.html") # noqa: E501

        log.info("KNN best k=%d (cross-validation accuracy: %.4f)\n%s",
                 study.best_params["n_neighbors"], study.best_value,
                 classification_report(target_valid, valid_predictions))

    return model, study, valid_predictions

def train_svc(
    features_train, features_val, target_train, target_valid
) -> tuple:
    """Tune SVC via Optuna (5-fold cross-validation), retrain on train set, evaluate on validation set."""
    with mlflow.start_run(run_name="svc"):

        def objective(trial: optuna.Trial) -> float:

            C = trial.suggest_float("C", low=1e-3, high=1e3, log=True)
            kernel = trial.suggest_categorical("kernel", choices=["linear", "rbf", "poly"])
            model = svm.SVC(C=C, kernel=kernel, random_state=42)
            return model_selection.cross_val_score(model, features_train, target_train, cv=5, scoring="accuracy").mean()  # noqa: E501

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=40)

        model = svm.SVC(**study.best_params, random_state=42)
        model.fit(features_train, target_train)
        valid_predictions = model.predict(features_val)

        mlflow.log_figure(figure=plot_optuna_trials(study, model_name="SVC", param_name="C"), artifact_file="optuna_trials.html") # noqa: E501

        log.info("SVC best params=%s (cross-validation accuracy: %.4f)\n%s",
                 study.best_params, study.best_value,
                 classification_report(target_valid, valid_predictions))

    return model, study, valid_predictions

def train_random_forest(
    features_train, features_val, target_train, target_valid
) -> tuple:
    """Train Random Forest with default parameters, evaluate on validation set."""
    with mlflow.start_run(run_name="random_forest"):
        model = ensemble.RandomForestClassifier(random_state=42)
        model.fit(features_train, target_train)
        valid_predictions = model.predict(features_val)

        log.info("Random Forest accuracy: %.4f\n%s",
                 accuracy_score(target_valid, valid_predictions),
                 classification_report(target_valid, valid_predictions))

    return model, None, valid_predictions



def train_catboost(
    features_train, features_val, target_train, target_valid
) -> tuple:
    """Train CatBoost with default parameters, evaluate on validation set."""
    with mlflow.start_run(run_name="catboost"):
        model = CatBoostClassifier(random_state=42, verbose=0)
        model.fit(features_train, target_train)
        valid_predictions = model.predict(features_val)

        log.info("CatBoost accuracy: %.4f\n%s",
                 accuracy_score(target_valid, valid_predictions),
                 classification_report(target_valid, valid_predictions))

    return model, None, valid_predictions


def train_hist_gradient_boosting(
    features_train, features_val, target_train, target_valid
) -> tuple:
    """Train HistGradientBoosting with default parameters, evaluate on validation set."""
    with mlflow.start_run(run_name="hist_gradient_boosting"):
        model = ensemble.HistGradientBoostingClassifier(random_state=42)
        model.fit(features_train, target_train)
        valid_predictions = model.predict(features_val)

        log.info("HistGradientBoosting accuracy: %.4f\n%s",
                 accuracy_score(target_valid, valid_predictions),
                 classification_report(target_valid, valid_predictions))

    return model, None, valid_predictions


# To test DL:
# from tabpfn import TabPFNClassifier

