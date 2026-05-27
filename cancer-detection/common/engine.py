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
from sklearn.metrics import classification_report
from sklearn.neural_network import MLPClassifier

from .visualizations import plot_mlp_loss_curve

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger(name=__name__)
optuna.logging.set_verbosity(verbosity=optuna.logging.WARNING)
mlflow.sklearn.autolog(log_models=True, serialization_format="pickle")

ROOT = Path(__file__).parent.parent

N_TRIALS = 20
CV_FOLDS = 5


def train_random_forest(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune Random Forest via Optuna (5-fold CV), retrain on train set, evaluate on test set."""
    with mlflow.start_run(run_name="random_forest"):

        def objective(trial: optuna.Trial) -> float:
            model = ensemble.RandomForestClassifier(
                n_estimators=trial.suggest_int("n_estimators", 50, 500, step=50),
                max_depth=trial.suggest_int("max_depth", 3, 30),
                min_samples_split=trial.suggest_int("min_samples_split", 2, 20),
                min_samples_leaf=trial.suggest_int("min_samples_leaf", 1, 10),
                random_state=42,
            )
            return model_selection.cross_val_score(
                model, features_train, target_train, cv=CV_FOLDS, scoring="accuracy"
            ).mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=N_TRIALS)

        model = ensemble.RandomForestClassifier(**study.best_params, random_state=42)
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        log.info("Random Forest best params=%s (cv accuracy: %.4f)\n%s",
                 study.best_params, study.best_value,
                 classification_report(target_test, test_predictions))

    return model, study, test_predictions


def train_catboost(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune CatBoost via Optuna (5-fold CV), retrain on train set, evaluate on test set."""
    with mlflow.start_run(run_name="catboost"):

        def objective(trial: optuna.Trial) -> float:
            model = CatBoostClassifier(
                depth=trial.suggest_int("depth", 3, 10),
                learning_rate=trial.suggest_float("learning_rate", 1e-3, 0.3, log=True),
                iterations=trial.suggest_int("iterations", 100, 1000, step=100),
                l2_leaf_reg=trial.suggest_float("l2_leaf_reg", 1e-2, 10.0, log=True),
                random_state=42,
                verbose=0,
            )
            return model_selection.cross_val_score(
                model, features_train, target_train, cv=CV_FOLDS, scoring="accuracy"
            ).mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=N_TRIALS)

        model = CatBoostClassifier(**study.best_params, random_state=42, verbose=0)
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        log.info("CatBoost best params=%s (cv accuracy: %.4f)\n%s",
                 study.best_params, study.best_value,
                 classification_report(target_test, test_predictions))

    return model, study, test_predictions


def train_hist_gradient_boosting(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune HistGradientBoosting via Optuna (5-fold CV), retrain, evaluate on test set."""
    with mlflow.start_run(run_name="hist_gradient_boosting"):

        def objective(trial: optuna.Trial) -> float:
            model = ensemble.HistGradientBoostingClassifier(
                learning_rate=trial.suggest_float("learning_rate", 1e-3, 0.3, log=True),
                max_depth=trial.suggest_int("max_depth", 3, 15),
                max_iter=trial.suggest_int("max_iter", 100, 800, step=100),
                min_samples_leaf=trial.suggest_int("min_samples_leaf", 5, 50),
                random_state=42,
            )
            return model_selection.cross_val_score(
                model, features_train, target_train, cv=CV_FOLDS, scoring="accuracy"
            ).mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=N_TRIALS)

        model = ensemble.HistGradientBoostingClassifier(**study.best_params, random_state=42)
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        log.info("HistGradientBoosting best params=%s (cv accuracy: %.4f)\n%s",
                 study.best_params, study.best_value,
                 classification_report(target_test, test_predictions))

    return model, study, test_predictions


def train_svc(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune SVC via Optuna (5-fold CV), retrain on train set, evaluate on test set."""
    with mlflow.start_run(run_name="svc"):

        def objective(trial: optuna.Trial) -> float:
            model = svm.SVC(
                C=trial.suggest_float("C", 1e-3, 1e3, log=True),
                kernel=trial.suggest_categorical("kernel", ["linear", "rbf", "poly"]),
                gamma=trial.suggest_categorical("gamma", ["scale", "auto"]),
                random_state=42,
            )
            return model_selection.cross_val_score(
                model, features_train, target_train, cv=CV_FOLDS, scoring="accuracy"
            ).mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=N_TRIALS)

        model = svm.SVC(**study.best_params, random_state=42)
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        log.info("SVC best params=%s (cv accuracy: %.4f)\n%s",
                 study.best_params, study.best_value,
                 classification_report(target_test, test_predictions))

    return model, study, test_predictions


def train_mlp(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune MLP architecture via Optuna (5-fold CV), retrain, evaluate on test set."""
    with mlflow.start_run(run_name="mlp"):

        def objective(trial: optuna.Trial) -> float:
            hidden_layer_sizes = tuple(
                trial.suggest_int(f"units_layer_{i}", low=8, high=256, step=8)
                for i in range(trial.suggest_int(name="n_layers", low=1, high=4))
            )
            model = MLPClassifier(
                hidden_layer_sizes=hidden_layer_sizes,
                activation=trial.suggest_categorical("activation", ["relu", "tanh"]),
                solver=trial.suggest_categorical("solver", ["adam", "sgd"]),
                alpha=trial.suggest_float(name="alpha", low=1e-5, high=1e-1, log=True),
                learning_rate_init=trial.suggest_float(name="learning_rate_init", low=1e-4, high=1e-1, log=True),  # noqa: E501
                max_iter=1200,
                random_state=42,
            )
            return model_selection.cross_val_score(
                model, features_train, target_train, cv=CV_FOLDS, scoring="accuracy"
            ).mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=N_TRIALS)

        best = study.best_params
        hidden_layer_sizes = tuple(best[f"units_layer_{i}"] for i in range(best["n_layers"]))

        model = MLPClassifier(
            hidden_layer_sizes=hidden_layer_sizes,
            activation=best["activation"],
            solver=best["solver"],
            alpha=best["alpha"],
            learning_rate_init=best["learning_rate_init"],
            max_iter=1200,
            random_state=42,
        )
        model.fit(features_train, target_train)
        test_predictions = model.predict(features_test)

        mlflow.log_figure(figure=plot_mlp_loss_curve(model, model_name="MLP"), artifact_file="loss_curve.html")  # noqa: E501

        log.info("MLP best params: layers=%s, activation=%s, solver=%s, alpha=%.4f, lr=%.4f (cv accuracy: %.4f)\n%s",  # noqa: E501
                 hidden_layer_sizes, best["activation"], best["solver"],
                 best["alpha"], best["learning_rate_init"], study.best_value,
                 classification_report(target_test, test_predictions))

    return model, study, test_predictions
