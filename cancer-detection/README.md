# Cancer Detection

## Table of Contents
- [Objective](#objective)
- [Data](#data)
- [Project Files](#project-files)
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
- **Format**: Parquet (optimized for analytics, ~50% smaller than CSV)

### Data Split Strategy

The dataset is split into three sets:

| Set | Samples | Purpose |
|-----|---------|---------|
| Training | 341 (60%) | Model learning |
| Validation | 114 (20%) | Hyperparameter tuning & model selection |
| Test | 114 (20%) | Final performance evaluation |

**Key Note**: Scaler is fitted on training data only and applied to validation/test sets to prevent data leakage.

</details>


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

This trains both Decision Tree and KNN models on the dataset with 60/20/20 train/val/test split.

### Option 2: Interactive Evaluation (Recommended)
Open and run `evaluation.ipynb` to:
- Train both models
- View cross-validation training curves (with validation included)
- Display interactive confusion matrices for validation and test sets
- Compare model performance metrics side-by-side

**Key Visualizations in the Notebook:**
- **Training Curves**: Cross-validation accuracy by fold (Decision Tree) or by hyperparameter (KNN)
- **Confusion Matrices**: Interactive heatmaps for validation and test sets with cell counts
- **Performance Metrics**: Accuracy, precision, recall, F1-score comparison table

</details>
