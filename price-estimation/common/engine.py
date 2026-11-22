"""
Price Estimation - Model Training Engine (Regression)
"""
import matplotlib

matplotlib.use("Agg")

import logging
from pathlib import Path

import mlflow
import mlflow.sklearn
import numpy as np
import optuna
from catboost import CatBoostRegressor
from sklearn import ensemble, model_selection
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.neural_network import MLPRegressor

from .visualizations import plot_mlp_loss_curve

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger(name=__name__)
optuna.logging.set_verbosity(verbosity=optuna.logging.WARNING)
mlflow.sklearn.autolog(log_models=True, serialization_format="pickle")

ROOT = Path(__file__).parent.parent

N_TRIALS = 60
CV_FOLDS = 5


def _log_regression_metrics(name, target_test, predictions, study=None):
    rmse = np.sqrt(mean_squared_error(target_test, predictions))
    r2 = r2_score(target_test, predictions)
    rmsle = np.sqrt(mean_squared_error(np.log1p(target_test), np.log1p(np.maximum(predictions, 0))))
    if study:
        log.info("%s best params=%s (cv neg-RMSE: %.0f) — test RMSE=%.0f, RMSLE=%.4f, R²=%.4f",
                 name, study.best_params, -study.best_value, rmse, rmsle, r2)
    else:
        log.info("%s — test RMSE=%.0f, RMSLE=%.4f, R²=%.4f", name, rmse, rmsle, r2)


def train_random_forest(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune Random Forest Regressor via Optuna, evaluate on test set."""
    with mlflow.start_run(run_name="random_forest"):

        def objective(trial: optuna.Trial) -> float:
            model = ensemble.RandomForestRegressor(
                n_estimators=trial.suggest_int("n_estimators", 50, 500, step=50),
                max_depth=trial.suggest_int("max_depth", 3, 30),
                min_samples_split=trial.suggest_int("min_samples_split", 2, 20),
                min_samples_leaf=trial.suggest_int("min_samples_leaf", 1, 10),
                random_state=42,
            )
            return model_selection.cross_val_score(
                model, features_train, target_train, cv=CV_FOLDS,
                scoring="neg_root_mean_squared_error",
            ).mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=N_TRIALS)

        model = ensemble.RandomForestRegressor(**study.best_params, random_state=42)
        model.fit(features_train, target_train)
        predictions = model.predict(features_test)

        _log_regression_metrics("Random Forest", target_test, predictions, study)

    return model, study, predictions


def train_catboost(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune CatBoost Regressor via Optuna, evaluate on test set."""
    with mlflow.start_run(run_name="catboost"):

        def objective(trial: optuna.Trial) -> float:
            model = CatBoostRegressor(
                depth=trial.suggest_int("depth", 3, 10),
                learning_rate=trial.suggest_float("learning_rate", 1e-3, 0.3, log=True),
                iterations=trial.suggest_int("iterations", 100, 1000, step=100),
                l2_leaf_reg=trial.suggest_float("l2_leaf_reg", 1e-2, 10.0, log=True),
                random_state=42,
                verbose=0,
            )
            return model_selection.cross_val_score(
                model, features_train, target_train, cv=CV_FOLDS,
                scoring="neg_root_mean_squared_error",
            ).mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=N_TRIALS)

        model = CatBoostRegressor(**study.best_params, random_state=42, verbose=0)
        model.fit(features_train, target_train)
        predictions = model.predict(features_test)

        _log_regression_metrics("CatBoost", target_test, predictions, study)

    return model, study, predictions


def train_hist_gradient_boosting(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune HistGradientBoosting Regressor via Optuna, evaluate on test set."""
    with mlflow.start_run(run_name="hist_gradient_boosting"):

        def objective(trial: optuna.Trial) -> float:
            model = ensemble.HistGradientBoostingRegressor(
                learning_rate=trial.suggest_float("learning_rate", 1e-3, 0.3, log=True),
                max_depth=trial.suggest_int("max_depth", 3, 15),
                max_iter=trial.suggest_int("max_iter", 100, 800, step=100),
                min_samples_leaf=trial.suggest_int("min_samples_leaf", 5, 50),
                random_state=42,
            )
            return model_selection.cross_val_score(
                model, features_train, target_train, cv=CV_FOLDS,
                scoring="neg_root_mean_squared_error",
            ).mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=N_TRIALS)

        model = ensemble.HistGradientBoostingRegressor(**study.best_params, random_state=42)
        model.fit(features_train, target_train)
        predictions = model.predict(features_test)

        _log_regression_metrics("HistGradientBoosting", target_test, predictions, study)

    return model, study, predictions


def train_mlp(
    features_train, features_test, target_train, target_test
) -> tuple:
    """Tune MLP Regressor via Optuna, evaluate on test set."""
    with mlflow.start_run(run_name="mlp"):

        def objective(trial: optuna.Trial) -> float:
            hidden_layer_sizes = tuple(
                trial.suggest_int(f"units_layer_{i}", low=16, high=256, step=16)
                for i in range(trial.suggest_int(name="n_layers", low=1, high=4))
            )
            model = MLPRegressor(
                hidden_layer_sizes=hidden_layer_sizes,
                activation=trial.suggest_categorical("activation", ["relu", "tanh"]),
                alpha=trial.suggest_float(name="alpha", low=1e-5, high=1e-1, log=True),
                learning_rate_init=trial.suggest_float(name="learning_rate_init", low=1e-4, high=1e-1, log=True),  # noqa: E501
                max_iter=1200,
                random_state=42,
            )
            return model_selection.cross_val_score(
                model, features_train, target_train, cv=CV_FOLDS,
                scoring="neg_root_mean_squared_error",
            ).mean()

        study = optuna.create_study(direction="maximize")
        study.optimize(objective, n_trials=N_TRIALS)

        best = study.best_params
        hidden_layer_sizes = tuple(best[f"units_layer_{i}"] for i in range(best["n_layers"]))

        model = MLPRegressor(
            hidden_layer_sizes=hidden_layer_sizes,
            activation=best["activation"],
            alpha=best["alpha"],
            learning_rate_init=best["learning_rate_init"],
            max_iter=1200,
            random_state=42,
        )
        model.fit(features_train, target_train)
        predictions = model.predict(features_test)

        mlflow.log_figure(figure=plot_mlp_loss_curve(model, model_name="MLP"), artifact_file="loss_curve.html")  # noqa: E501

        _log_regression_metrics("MLP", target_test, predictions, study)

    return model, study, predictions
