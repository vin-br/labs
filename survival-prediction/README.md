# Survival Prediction

---

[![Python](https://img.shields.io/badge/Python-3.14+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org) [![uv](https://img.shields.io/badge/uv-latest-261230?style=for-the-badge&logo=uv&logoColor=DE5FE9)](https://docs.astral.sh/uv/) [![Polars](https://img.shields.io/badge/Polars-1.41+-0075FF?style=for-the-badge&logo=polars&logoColor=white)](https://pola.rs/) [![scikit-learn](https://img.shields.io/badge/scikit--learn-1.8+-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white)](https://scikit-learn.org/) [![Optuna](https://img.shields.io/badge/Optuna-4.8+-2EA9DF?style=for-the-badge&logo=optuna&logoColor=white)](https://optuna.org/) [![MLflow](https://img.shields.io/badge/MLflow-3.12+-0194E2?style=for-the-badge&logo=mlflow&logoColor=white)](https://mlflow.org/)

---

## Overview

The Titanic dataset is a widely used benchmark for binary classification tasks in machine learning. It contains information about the passengers aboard the RMS Titanic, including their demographics, ticket details, and whether they survived the disaster. The goal is to predict survival based on the appropriate features.

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
<summary>Files description</summary>

### Description

The dataset is split into two groups:
- **Training set** (`train..parquet`): Build models using features (passenger gender, class, age, etc.) with known survival outcomes
- **Test set** (`test..parquet`): Evaluate models on unseen data; ground truth is not provided

A sample submission file (`gender_submission.parquet`) assumes all and only female passengers survived and shows the expected output format.

</details>

<details>
<summary>Data Dictionary</summary>

### Data Dictionary

| **Variable** | **Definition**                             | **Key**                                        |
| ------------ | ------------------------------------------ | ---------------------------------------------- |
| survival     | Survival                                   | 0 = No, 1 = Yes                                |
| pclass       | Ticket class                               | 1 = 1st, 2 = 2nd, 3 = 3rd                      |
| sex          | Sex                                        |                                                |
| age          | Age in years                               |                                                |
| sibsp        | # of siblings / spouses aboard the Titanic |                                                |
| parch        | # of parents / children aboard the Titanic |                                                |
| ticket       | Ticket number                              |                                                |
| fare         | Passenger fare                             |                                                |
| cabin        | Cabin number                               |                                                |
| embarked     | Port of embarkation                        | C = Cherbourg, Q = Queenston, S = Southampton  |


> Details 
> - **pclass** — Proxy for socio-economic status: 1 = Upper, 2 = Middle, 3 = Lower
> - **age** — Fractional if less than 1; estimated ages given as xx.5
> - **sibsp** — Siblings/spouses aboard (brother, sister, stepbrother, stepsister, husband, wife)
> - **parch** — Parents/children aboard (mother, father, daughter, son, stepchild). Children travelling only with a nanny have parch = 0
> - **embarked** — Port of embarkation (C = Cherbourg, Q = Queenstown, S = Southampton)

</details>

## Models

<details>
<summary>Model Details</summary>

Five classifiers trained with hyperparameter optimization:

| Model | Optimization |
|-------|--------------|
| Random Forest | Default parameters |
| CatBoost | Default parameters |
| HistGradientBoosting | Default parameters |
| Support Vector Classifier (SVC) | Default parameters |
| KNN | Default parameters |
