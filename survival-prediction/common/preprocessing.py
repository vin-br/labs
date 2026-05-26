from pathlib import Path

import polars as pl
from sklearn.compose import make_column_transformer
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder, StandardScaler

ROOT = Path(__file__).parent.parent

DROP_COLS = ["PassengerId", "Name", "Ticket", "Cabin"]
NULL_COLS = ["Age", "Embarked"]
CATEGORICAL_COLS = ["Sex", "Embarked", "Age_Sex"]
TARGET_COL = "Survived"


def _engineer_features(dataframe: pl.DataFrame) -> pl.DataFrame:
    """Create Age_Sex interaction feature (important for Titanic: women & children first)."""
    dataframe = dataframe.with_columns(
        pl.when(pl.col(name="Age") < 18)
        .then(statement=pl.lit(value="Child_"))
        .otherwise(statement=pl.lit(value="Adult_"))
        .alias(name="age_group")
    )
    dataframe = dataframe.with_columns(
        (pl.col(name="age_group") + pl.col(name="Sex")).alias(name="Age_Sex")
    )
    dataframe = dataframe.drop("age_group")
    return dataframe


def load_and_prepare_data(
    data_path: str = "data/train.parquet",
) -> tuple:
    """Load parquet, split 80/20 train/test, scale features."""
    dataframe = pl.read_parquet(ROOT / data_path)

    # Drop high-null / irrelevant columns, then drop rows with nulls in key columns
    dataframe = dataframe.drop([c for c in DROP_COLS if c in dataframe.columns and c != "Age_Sex"])
    dataframe = dataframe.drop_nulls(subset=NULL_COLS)
    dataframe = _engineer_features(dataframe)

    feature_cols = [c for c in dataframe.columns if c != TARGET_COL]
    features = dataframe.select(feature_cols).to_pandas()
    target = dataframe[TARGET_COL].to_numpy()

    features_train, features_val, target_train, target_valid = train_test_split(
        features, target, test_size=0.2, random_state=42
    )

    numerical_cols = [c for c in feature_cols if c not in CATEGORICAL_COLS]
    preprocessor = make_column_transformer(
        (StandardScaler(), numerical_cols),
        (OneHotEncoder(handle_unknown="ignore", sparse_output=False), CATEGORICAL_COLS),
    )

    features_train = preprocessor.fit_transform(features_train)
    features_val = preprocessor.transform(features_val)

    return features_train, features_val, target_train, target_valid, preprocessor
