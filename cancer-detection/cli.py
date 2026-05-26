"""
Cancer Detection - CLI

Entry point for training models from the terminal.
"""

import logging

import mlflow

from common.engine import load_and_prepare_data, train_decision_tree, train_knn, train_mlp

log = logging.getLogger(name=__name__)
logging.getLogger(name="mlflow.sklearn").setLevel(level=logging.ERROR)
logging.getLogger(name="mlflow.utils.uv_utils").setLevel(level=logging.ERROR)
logging.getLogger(name="mlflow.utils.environment").setLevel(level=logging.ERROR)
logging.getLogger(name="mlflow.tracking").setLevel(level=logging.ERROR)


def main() -> None:
    mlflow.set_tracking_uri("sqlite:///mlruns/mlruns.db")
    mlflow.set_experiment(experiment_name="cancer-detection")

    log.info(msg="Loading and preparing data...")
    features_train, features_test, target_train, target_test, _ = load_and_prepare_data()

    log.info(msg="Training Decision Tree...")
    train_decision_tree(features_train, features_test, target_train, target_test)

    log.info(msg="Training K-Nearest Neighbors with Optuna...")
    train_knn(features_train, features_test, target_train, target_test)

    log.info(msg="Training Multi-Layer Perceptron with Optuna...")
    train_mlp(features_train, features_test, target_train, target_test)

    log.info(msg="Training complete!")
    log.info(msg="Run `mlflow ui --backend-store-uri sqlite:///mlruns/mlruns.db` to view results.")


if __name__ == "__main__":
    main()
