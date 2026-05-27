# Price Estimation

---

[![Python](https://img.shields.io/badge/Python-3.14+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org) [![uv](https://img.shields.io/badge/uv-latest-261230?style=for-the-badge&logo=uv&logoColor=DE5FE9)](https://docs.astral.sh/uv/) [![Polars](https://img.shields.io/badge/Polars-1.41+-0075FF?style=for-the-badge&logo=polars&logoColor=white)](https://pola.rs/) [![scikit-learn](https://img.shields.io/badge/scikit--learn-1.8+-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white)](https://scikit-learn.org/) [![Optuna](https://img.shields.io/badge/Optuna-4.8+-2EA9DF?style=for-the-badge&logo=optuna&logoColor=white)](https://optuna.org/) [![MLflow](https://img.shields.io/badge/MLflow-3.12+-0194E2?style=for-the-badge&logo=mlflow&logoColor=white)](https://mlflow.org/)

---

## Overview

Summary: Estimate residential home prices in Ames, Iowa using 79 explanatory variables. This Kaggle competition challenges participants to model complex interactions between features and sale price, beyond simple attributes like bedrooms or lot size.


## Table of Contents
- [Python Setup](#python-setup)
- [Run Pipeline](#run-pipeline)
- [Data](#data)
- [Models](#models)
- [Metrics](#metrics)

## Python Setup

<details>
<summary>Install uv & Python</summary>

Install [uv](https://docs.astral.sh/uv/):

```shell
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Install Python and sync dependencies:

```shell
uv python install 3.14
uv sync
```

Activate the virtual environment:

```shell
# macOS / Linux
source .venv/bin/activate

# Windows
.venv\Scripts\activate
```

**Python version used:** 3.14.5

</details>

## Run Pipeline

<details>
<summary>Commands</summary>

### Install dependencies
```bash
uv sync
```

### Train Models from CLI
```bash
uv run python cli.py
```

### View Results
```bash
mlflow ui --backend-store-uri sqlite:///mlruns/mlruns.db
```

</details>

## Data

<details>
<summary>Dataset Details</summary>

[House Prices - Advanced Regression Techniques](https://www.kaggle.com/c/house-prices-advanced-regression-techniques)

- **File**: `train.csv`, `test.csv`
- **Samples**: 1,460 (train) + 1,459 (test)
- **Features**: 79 explanatory variables + target
- **Target**: SalePrice (continuous)
- **Format**: CSV

### Data Preprocessing

- Categorical features: One-hot encoding
- Numerical features: Robust scaling
- Missing values: KNN imputation, mode, or domain-specific strategies
- Index: Set to `Id`

</details>

## Models

Regression models with hyperparameter tuning via GridSearchCV:

| Model | Algorithm |
|-------|-----------|
| Gradient Boosting | Ensemble gradient boosting |
| Random Forest | Ensemble bagging |
| Decision Tree | Single decision tree |

## Metrics

<details>
<summary>Metrics</summary>

Root-Mean-Squared-Error (RMSE) on **log-transformed** values. Predictions and actual prices are log-transformed before computing error, ensuring expensive and cheap houses are weighted equally (prevents large errors on expensive houses from dominating the score).
</details>
