"""
Price Estimation - CLI

Entry point for training regression models from the terminal.
"""

import logging

import mlflow

from common import (
    load_and_prepare_data,
    train_catboost,
    train_hist_gradient_boosting,
    train_mlp,
    train_random_forest,
)

log = logging.getLogger(name=__name__)
logging.getLogger(name="mlflow.sklearn").setLevel(level=logging.ERROR)
logging.getLogger(name="mlflow.utils.uv_utils").setLevel(level=logging.ERROR)
logging.getLogger(name="mlflow.utils.environment").setLevel(level=logging.ERROR)
logging.getLogger(name="mlflow.tracking").setLevel(level=logging.ERROR)


def main() -> None:
    mlflow.set_tracking_uri("sqlite:///mlruns/mlruns.db")
    mlflow.set_experiment(experiment_name="price-estimation")

    log.info(msg="Loading and preparing data...")
    features_train, features_test, target_train, target_test, _ = load_and_prepare_data()

    log.info(msg="Training Random Forest Regressor with Optuna...")
    train_random_forest(features_train, features_test, target_train, target_test)

    log.info(msg="Training CatBoost Regressor with Optuna...")
    train_catboost(features_train, features_test, target_train, target_test)

    log.info(msg="Training HistGradientBoosting Regressor with Optuna...")
    train_hist_gradient_boosting(features_train, features_test, target_train, target_test)

    log.info(msg="Training MLP Regressor with Optuna...")
    train_mlp(features_train, features_test, target_train, target_test)

    log.info(msg="Training complete!")
    log.info(msg="Run `mlflow ui --backend-store-uri sqlite:///mlruns/mlruns.db` to view results.")


if __name__ == "__main__":
    main()
