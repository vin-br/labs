# Price Estimation

## Overview

Summary: Estimate residential home prices in Ames, Iowa using 79 explanatory variables. This Kaggle competition challenges participants to model complex interactions between features and sale price, beyond simple attributes like bedrooms or lot size.

## Table of Contents
- [Objective](#objective)
- [Data](#data)
- [Models](#models)
- [Metric](#metric)
- [Setup & Usage](#setup--usage)

## Data

<details>
<summary><b>Dataset Details</b></summary>

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

## Metric

Root-Mean-Squared-Error (RMSE) on **log-transformed** values. Predictions and actual prices are log-transformed before computing error, ensuring expensive and cheap houses are weighted equally (prevents large errors on expensive houses from dominating the score).

## Setup & Usage

<details>
<summary><b>Commands</b></summary>

### Install dependencies
```bash
pip install -r requirements.txt
```

### Notebooks
- `eda.ipynb` — Exploratory Data Analysis
- `model.ipynb` — Model training and evaluation

</details>
