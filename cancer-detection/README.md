# Cancer Detection

## Table of Contents
- [Objective](#objective)
- [Data](#data)
- [Models](#models)
- [Setup & Usage](#setup--usage)

## Overview

Classify breast cancer cells as malignant or benign using fine-needle biopsy measurements.

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

Three classifiers trained with hyperparameter optimization:

| Model | Optimization |
|-------|--------------|
| Decision Tree | 5-fold cross-validation |
| K-Nearest Neighbors (KNN) | Optuna (40 trials, k=2–41) |
| Multi-Layer Perceptron (MLP) | Optuna (40 trials, architecture search) |


## Setup & Usage

<details>
<summary><b>Commands</b></summary>

### Install dependencies
```bash
uv sync
```

### Option 1: Train Models from CLI
```bash
uv run python cli.py
```

</details>
