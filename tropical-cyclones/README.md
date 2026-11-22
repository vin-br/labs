# Tropical Cyclones

Tropical Cyclones Intensity Classification using PyTorch, Optuna, and TensorBoard.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Deep Learning Pipeline](#deep-learning-pipeline)
- [Project Structure](#project-structure)
- [Resources](#resources)

## Overview

Multiclass classification of tropical cyclone intensity stages (TD9636_STAGE, 7 classes) using a feedforward neural network trained with PyTorch. Hyperparameter optimization is handled by Optuna, and training metrics are logged to TensorBoard.

### Features

- Data cleaning pipeline converting raw IBTrACS data to ML-ready features
- Feature engineering: ordinal season encoding, one-hot basin/nature, storm direction decomposition
- SMOTE data augmentation for imbalanced classes
- Automated hyperparameter search with Optuna (architecture, learning rate, dropout, batch size)
- TensorBoard integration for training visualization
- scikit-learn for preprocessing (StandardScaler, LabelEncoder, train_test_split) and evaluation metrics
- CLI for dataset generation and model training

## Installation

### Prerequisites

- Python >= 3.11
- [uv](https://docs.astral.sh/uv/) (recommended) or pip

### Setup

```bash
cd tropical-cyclones
uv sync
```

## Getting Started

### 1. Generate Dataset

Convert raw IBTrACS parquet to a cleaned base dataset:

```bash
python cli.py generate
```

Options:
- `--input PATH` — path to raw parquet (default: `data/ibtracs_single_header.parquet`)
- `--output PATH` — output path (default: `data/base.parquet`)

### 2. Train Model

Run hyperparameter search and train the best model:

```bash
python cli.py train --trials 50 --epochs 50 --device auto
```

Options:
- `--data PATH` — path to `base.parquet` (default: `data/base.parquet`)
- `--trials N` — number of Optuna trials (default: 50)
- `--epochs N` — epochs per trial (default: 50)
- `--device {auto,cpu,cuda,mps}` — compute device (default: auto-detect)
- `--augment` — enable SMOTE data augmentation
- `--log-dir DIR` — TensorBoard log directory (default: `runs`)

### 3. View Training Metrics

```bash
tensorboard --logdir pipeline/runs
```

## Deep Learning Pipeline

### Preprocessing

Raw IBTrACS data goes through two stages before reaching the model:

**1. Dataset generation** (`pipeline/generate_dataset.py`): Cleans the raw IBTrACS CSV/parquet by replacing whitespace with NaN, dropping rows without a target label, deriving meteorological seasons from date + hemisphere, and standardizing wind speed measurements from multiple agencies to a common 1-minute averaging time (10-min sources are multiplied by 1.12).

**2. Feature encoding** (`pipeline/preprocessing.py`): Transforms the cleaned dataset into model-ready tensors:

| Feature | Encoding | Rationale |
|---------|----------|-----------|
| SEASON | OrdinalEncoder (winter=0, spring=1, fall=2, summer=3) | Preserves cyclone frequency ordering |
| BASIN | One-hot (drop_first) | No ordinal relationship between ocean basins |
| NATURE | One-hot (drop_first) | No ordinal relationship between cyclone natures |
| STORM_DIR | Decomposed to cos/sin (X,Y) | Circular variable — raw degrees would create false discontinuity at 0°/360° |
| WIND, DIST2LAND, STORM_SPEED, LAT, LON | StandardScaler (zero mean, unit variance) | Required for gradient-based optimization convergence |

The target `TD9636_STAGE` (7 intensity classes, 0–6) is integer-encoded with sklearn's `LabelEncoder`. Data is split 80/20 with `train_test_split` (stratified) to preserve class distribution. Optional SMOTE augmentation generates synthetic minority-class samples.

### Neural Network Architecture

The model (`pipeline/model.py`) is a feedforward MLP (Multi-Layer Perceptron) — a fully connected artificial neural network. Each hidden layer consists of four operations applied in sequence:

```
Input (16 features)
  → [Linear → BatchNorm → ReLU → Dropout] × N hidden layers
  → Linear → Output (7 logits)
```

**Layer breakdown:**

| Component | What it does |
|-----------|-------------|
| `nn.Linear(in, out)` | Fully connected layer: $y = xW^T + b$. Learns weight matrix $W$ and bias $b$ via backpropagation. |
| `nn.BatchNorm1d(out)` | Normalizes each mini-batch to zero mean and unit variance, then applies learnable scale/shift. Stabilizes training and allows higher learning rates. |
| `nn.ReLU()` | Activation function: $f(x) = \max(0, x)$. Introduces non-linearity — without it, stacking linear layers would collapse into a single linear transformation. |
| `nn.Dropout(p)` | Randomly zeros a fraction $p$ of neurons during training. Prevents co-adaptation of neurons, acting as regularization to reduce overfitting. |
| Final `nn.Linear` | Maps last hidden layer to 7 raw logits (one per class). No activation — `CrossEntropyLoss` applies softmax internally. |

### Loss Function

`nn.CrossEntropyLoss` combines `LogSoftmax` and `NLLLoss`. For a sample with true class $c$:

$$\mathcal{L} = -\log\left(\frac{e^{z_c}}{\sum_{j} e^{z_j}}\right)$$

where $z_j$ are the raw logits. This is the standard loss for multiclass classification.

### Optimizer

**Adam** (Adaptive Moment Estimation) with weight decay. Adam maintains per-parameter learning rates adapted from first and second moment estimates of the gradients, combining the benefits of AdaGrad and RMSProp. Weight decay adds L2 regularization to prevent large weights.

### Hyperparameter Search (Optuna)

Optuna uses a Tree-structured Parzen Estimator (TPE) to efficiently explore the hyperparameter space. The search space includes:

| Parameter | Range | Type |
|-----------|-------|------|
| `n_layers` | 1–4 | Architecture depth |
| `hidden_i` | 64–512 | Neurons per hidden layer |
| `dropout` | 0.05–0.5 | Regularization strength |
| `lr` | 1e-4 – 1e-2 (log) | Learning rate |
| `batch_size` | 64, 128, 256, 512 | Mini-batch size |
| `weight_decay` | 1e-6 – 1e-3 (log) | L2 regularization |

A `MedianPruner` (5 warmup steps) stops unpromising trials early by comparing intermediate accuracy to the running median of completed trials. After the search, the best configuration is retrained from scratch and evaluated on the held-out test set.

### Evaluation

Metrics reported: accuracy, weighted F1, and sklearn's `classification_report` (per-class precision, recall, F1, support). Training curves are logged to TensorBoard (`pipeline/runs/`).

## Project Structure

```
tropical-cyclones/
├── cli.py                         # CLI entrypoint (generate, train)
├── pyproject.toml                 # Project metadata and dependencies
├── README.md
├── eda.ipynb                      # Exploratory data analysis
├── data/                          # Raw and processed datasets
│   ├── ibtracs_single_header.parquet
│   └── base.parquet
├── models/                        # Saved model weights (.pt)
│   └── best_model.pt
├── pipeline/
│   ├── __init__.py
│   ├── generate_dataset.py        # Raw data → cleaned parquet
│   ├── preprocessing.py           # Feature encoding, scaling, splitting
│   ├── model.py                   # CycloneClassifier ANN, train/eval loops
│   ├── engine.py                  # Optuna search orchestration, TensorBoard
│   └── runs/                      # TensorBoard logs
└── assets/
    ├── screenshots/
    └── video/
```

## Resources

### Dataset

To use the data visualization notebooks and the machine learning pipeline, download the dataset and place it in the `/data` folder:

**Download**: https://app.filen.io/#/d/fee1e0e8-c504-49d9-a0b3-98440cd4402a%23Nz1UuOepVd8qKHL81uJimrGDrhVU7Wox

**Official Source**:
- IBTrACS [dataset](https://www.ncei.noaa.gov/products/international-best-track-archive) from the National Centers for Environmental Information [(NOAA)](https://www.ncei.noaa.gov/)
