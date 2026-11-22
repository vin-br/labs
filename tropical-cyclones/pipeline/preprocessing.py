"""Preprocessing pipeline for tropical cyclone intensity classification.

Encodes categorical features (season, basin, nature), decomposes storm direction
into X/Y components, scales numerical features, and optionally augments with SMOTE.
"""

from pathlib import Path

import numpy as np
import pandas as pd
from imblearn.over_sampling import SMOTE
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
TARGET = "TD9636_STAGE"

# Seasons ordered by cyclone frequency: winter < spring < fall < summer
SEASON_ORDER = {"winter": 0, "spring": 1, "fall": 2, "summer": 3}


def encode_features(df: pd.DataFrame) -> pd.DataFrame:
    """Apply all feature engineering to the cleaned dataset.

    - SEASON: ordinal encoding (0=winter, 1=spring, 2=fall, 3=summer).
    - BASIN, NATURE: one-hot encoding (drop_first=True).
    - STORM_DIR: decomposed into cos/sin components (STORM_DIR_X, STORM_DIR_Y).
    """
    df = df.copy()

    df["SEASON"] = df["SEASON"].str.lower().map(SEASON_ORDER).astype(float)

    df = pd.get_dummies(df, columns=["BASIN", "NATURE"], drop_first=True)

    df["STORM_DIR_X"] = np.cos(np.radians(df["STORM_DIR"]))
    df["STORM_DIR_Y"] = np.sin(np.radians(df["STORM_DIR"]))
    df = df.drop(columns=["STORM_DIR"])

    bool_cols = df.select_dtypes(include="bool").columns
    df[bool_cols] = df[bool_cols].astype(float)

    return df


def prepare_data(
    path: Path | None = None,
    test_size: float = 0.2,
    augment: bool = False,
) -> dict:
    """Load, encode, split, scale, and optionally augment the dataset.

    Returns dict with: X_train, X_test, y_train, y_test,
    feature_names, n_classes, label_encoder, scaler.
    """
    path = path or DATA_DIR / "base.parquet"
    df = pd.read_parquet(path, engine="pyarrow")
    df = encode_features(df)

    label_encoder = LabelEncoder()
    y = label_encoder.fit_transform(df[TARGET].astype(int))

    X = df.drop(columns=[TARGET])
    feature_names = list(X.columns)

    X_train, X_test, y_train, y_test = train_test_split(
        X.values.astype(np.float32),
        y,
        test_size=test_size,
        stratify=y,
        random_state=42,
    )

    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_test = scaler.transform(X_test)

    if augment:
        smote = SMOTE(sampling_strategy="auto", random_state=42)
        X_train, y_train = smote.fit_resample(X_train, y_train)

    return {
        "X_train": X_train.astype(np.float32),
        "X_test": X_test.astype(np.float32),
        "y_train": y_train,
        "y_test": y_test,
        "feature_names": feature_names,
        "n_classes": len(label_encoder.classes_),
        "label_encoder": label_encoder,
        "scaler": scaler,
    }
