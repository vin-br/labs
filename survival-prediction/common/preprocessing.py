from pathlib import Path

import polars as pl
from sklearn.compose import make_column_transformer
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder, StandardScaler

ROOT = Path(__file__).parent.parent

TARGET_COL = "Survived"
CATEGORICAL_COLS = ["Sex", "Embarked", "Title", "Deck", "Age_Sex"]

# Title mapping: group rare titles into broader categories
TITLE_MAP = {
    "Mr": "Mr", "Miss": "Miss", "Mrs": "Mrs", "Master": "Master",
    "Dr": "Rare", "Rev": "Rare", "Col": "Rare", "Major": "Rare",
    "Mlle": "Miss", "Ms": "Miss", "Mme": "Mrs", "Sir": "Rare",
    "Lady": "Rare", "Capt": "Rare", "Don": "Rare", "Dona": "Rare",
    "Countess": "Rare", "Jonkheer": "Rare",
}


def _extract_title(name: str) -> str:
    """Extract title from passenger name (e.g. 'Braund, Mr. Owen' → 'Mr')."""
    title = name.split(",")[1].split(".")[0].strip()
    return TITLE_MAP.get(title, "Rare")


def _engineer_features(df: pl.DataFrame) -> pl.DataFrame:
    """Feature engineering based on Titanic best practices.

    - Title: extracted from Name — captures social status / age proxy.
    - FamilySize: SibSp + Parch + 1 — families of 2-4 survived more.
    - IsAlone: binary flag — solo travellers had lower survival.
    - Deck: first letter of Cabin — proxy for deck location (lifeboat access).
    - Age_Sex: Child/Adult x Sex interaction — "women and children first".
    """
    df = df.with_columns(
        # Title from Name
        pl.col("Name")
        .map_elements(lambda n: _extract_title(n), return_dtype=pl.String)
        .alias("Title"),
        # Family size
        (pl.col("SibSp") + pl.col("Parch") + 1).alias("FamilySize"),
        # Deck from Cabin (first letter, or "U" for unknown)
        pl.col("Cabin").fill_null("U").str.slice(0, 1).alias("Deck"),
    )

    # Impute Age by median per Title (preserves ~20% more data than dropping nulls)
    title_medians = df.group_by("Title").agg(pl.col("Age").median().alias("Age_median"))
    df = df.join(title_medians, on="Title", how="left")
    df = df.with_columns(pl.col("Age").fill_null(pl.col("Age_median"))).drop("Age_median")

    # Impute remaining Embarked nulls with mode ("S")
    df = df.with_columns(pl.col("Embarked").fill_null("S"))

    # Derived features
    df = df.with_columns(
        pl.when(pl.col("FamilySize") == 1).then(1).otherwise(0).cast(pl.Int32).alias("IsAlone"),
        pl.when(pl.col("Age") < 18)
        .then(pl.lit("Child_"))
        .otherwise(pl.lit("Adult_"))
        .add(pl.col("Sex"))
        .alias("Age_Sex"),
    )

    # Drop columns no longer needed
    df = df.drop(["PassengerId", "Name", "Ticket", "Cabin", "Fare"])
    return df


def load_and_prepare_data(
    data_path: str = "data/train.parquet",
) -> tuple:
    """Load parquet, engineer features, split 80/20 train/test, scale features."""
    dataframe = pl.read_parquet(ROOT / data_path)

    dataframe = _engineer_features(dataframe)

    feature_cols = [c for c in dataframe.columns if c != TARGET_COL]
    features = dataframe.select(feature_cols).to_pandas()
    target = dataframe[TARGET_COL].to_numpy()

    features_train, features_val, target_train, target_valid = train_test_split(
        features, target, test_size=0.2, random_state=42
    )

    numerical_cols = [c for c in feature_cols if c not in CATEGORICAL_COLS]
    cat_cols = [c for c in CATEGORICAL_COLS if c in feature_cols]
    preprocessor = make_column_transformer(
        (StandardScaler(), numerical_cols),
        (OneHotEncoder(handle_unknown="ignore", sparse_output=False), cat_cols),
    )

    features_train = preprocessor.fit_transform(features_train)
    features_val = preprocessor.transform(features_val)

    return features_train, features_val, target_train, target_valid, preprocessor
