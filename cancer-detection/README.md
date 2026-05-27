# Cancer Detection

---

[![Python](https://img.shields.io/badge/Python-3.14+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org) [![uv](https://img.shields.io/badge/uv-latest-261230?style=for-the-badge&logo=uv&logoColor=DE5FE9)](https://docs.astral.sh/uv/) [![Polars](https://img.shields.io/badge/Polars-1.41+-0075FF?style=for-the-badge&logo=polars&logoColor=white)](https://pola.rs/) [![scikit-learn](https://img.shields.io/badge/scikit--learn-1.8+-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white)](https://scikit-learn.org/) [![Optuna](https://img.shields.io/badge/Optuna-4.8+-2EA9DF?style=for-the-badge&logo=optuna&logoColor=white)](https://optuna.org/) [![MLflow](https://img.shields.io/badge/MLflow-3.12+-0194E2?style=for-the-badge&logo=mlflow&logoColor=white)](https://mlflow.org/)

---

## Overview

Classify breast cancer cells as malignant or benign using fine-needle biopsy measurements from the Breast Cancer Wisconsin dataset (Kaggle). Models include Random Forest, SVC, CatBoost, HistGradientBoosting, and MLP classifiers with Optuna hyperparameter tuning.

## Table of Contents
- [Python Setup](#python-setup)
- [Run Pipeline](#run-pipeline)
- [Data](#data)
- [Models](#models)

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
<summary><b>Commands</b></summary>

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
<summary><b>Dataset Details</b></summary>

[Breast Cancer Wisconsin dataset](https://www.kaggle.com/datasets/uciml/breast-cancer-wisconsin-data)

- **File**: `breast_cancer.parquet`
- **Samples**: 569
- **Features**: 31 (mean, std, worst) from 10 measurements
- **Format**: Parquet

### Data Split

- **Train**: 80% (~455 samples) — used for model training & 5-fold cross-validation
- **Test**: 20% (~114 samples) — held out for final evaluation

**Note**: Scaler is fitted on training data only and applied to test set to prevent data leakage.

</details>

## Models

<details>
<summary><b>Model Details</b></summary>

Five classifiers trained with hyperparameter optimization:

| Model | Optimization |
|-------|--------------|
| Random Forest | Optuna (20 trials, 5-fold CV) |
| CatBoost | Optuna (20 trials, 5-fold CV) |
| HistGradientBoosting | Optuna (20 trials, 5-fold CV) |
| Support Vector Classifier (SVC) | Optuna (20 trials, 5-fold CV) |
| Multi-Layer Perceptron (MLP) | Optuna (20 trials, architecture search) |

</details>
