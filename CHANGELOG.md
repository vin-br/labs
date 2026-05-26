# Changelog

All notable changes to this repository are documented here.

## [26.05]

### Added
- Merged cycling-operator XML data pipeline project
- Merged enron analysis and Shiny app with R
- Merged tropical-cyclones project
- Added to cancer-detection an Optuna ML pipeline with the models Random Forest, SVC, CatBoost, HistGradientBoosting and MLP Classifier
- Added to cancer-detection MLflow tracking
- Added to survival-prediction an Optuna ML pipeline with the models KNN, SVC, Random Forest, CatBoost, HistGradientBoosting
- Added to survival-prediction MLflow tracking

### Changed
- Updated README with repo structure and projects details
- Updated .gitignore for all projects
- Rebuilt cancer-detection with modern stack (latest Python, Optuna, Polars, Plotly) and refactored codebase to be more modular and reusable across projects
- Code cleanup

### Removed

- Remove custom-mlp exercise since it was reused in part in cancer-detection
- Remove most of the manual plots in cancer-detection in favor of MLflow + remove evaluation notebook
- Remmove Decision Tree and KNN models from cancer-detection since they performed poorly

## [25.10]

### Added
- Merged custom-mlp exercise
- Merged price-estimation EDA project
- Merged survival-prediction EDA and ML project
- Merged cancer-detection EDA

## [22.12]

### Added
- Initial Labs setup with notebooks

## [22.11]

### Added
- Initial commit
