"""
Cancer Detection - Command Line Interface

Entry point for training models from the terminal.
"""

import logging

from engine import load_and_prepare_data, save_model, train_decision_tree, train_knn

log = logging.getLogger(__name__)


def main() -> None:
    log.info("Loading and preparing data...")
    features_train, features_test, target_train, target_test, scaler = load_and_prepare_data()
    save_model(scaler, "scaler")

    log.info("Training Decision Tree...")
    decision_tree, _, _ = train_decision_tree(features_train, features_test, target_train, target_test)
    save_model(decision_tree, "decision_tree")

    log.info("Training KNN with Optuna...")
    knn, _, _ = train_knn(features_train, features_test, target_train, target_test)
    save_model(knn, "knn")

    log.info("✓ Training complete!")


if __name__ == "__main__":
    main()
