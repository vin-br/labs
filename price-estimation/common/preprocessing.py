from pathlib import Path

import polars as pl
from sklearn.compose import make_column_transformer
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder, StandardScaler

ROOT = Path(__file__).parent.parent

TARGET_COL = "SalePrice"

# Columns with NA meaning "no feature" per data description
NA_MEANS_NONE = [
    "Alley", "BsmtQual", "BsmtCond", "BsmtExposure", "BsmtFinType1",
    "BsmtFinType2", "FireplaceQu", "GarageType", "GarageFinish",
    "GarageQual", "GarageCond", "PoolQC", "Fence", "MiscFeature",
]

# Columns with very low correlation to SalePrice (|r| < 0.15)
LOW_IMPACT_COLS = [
    "Alley", "Street", "Condition1", "Condition2", "MoSold", "YrSold", "SaleType",
    "LandContour", "LotConfig", "Utilities", "MiscFeature", "MiscVal", "MSSubClass",
    "3SsnPorch", "EnclosedPorch", "Fence", "LandSlope", "PoolArea", "PoolQC", "ScreenPorch",
    "Functional", "LowQualFinSF", "FireplaceQu", "Heating",
    "RoofMatl", "ExterCond", "Exterior2nd", "Exterior1st", "MasVnrType", "OverallCond", "BldgType",
    "BsmtCond", "BsmtFinType2", "BsmtFinSF2", "BsmtHalfBath", "BsmtFinType1", "KitchenAbvGr",
]

# Ordinal features with natural ordering (quality scales)
ORDINAL_FEATURES = {
    "ExterQual": ["Po", "Fa", "TA", "Gd", "Ex"],
    "BsmtQual": ["NA", "Po", "Fa", "TA", "Gd", "Ex"],
    "KitchenQual": ["Po", "Fa", "TA", "Gd", "Ex"],
    "HeatingQC": ["Po", "Fa", "TA", "Gd", "Ex"],
    "GarageFinish": ["NA", "Unf", "RFn", "Fin"],
    "GarageCond": ["NA", "Po", "Fa", "TA", "Gd", "Ex"],
    "GarageQual": ["NA", "Po", "Fa", "TA", "Gd", "Ex"],
}


def load_and_prepare_data(
    data_path: str = "data/train.parquet",
    drop_low_impact: bool = True,
) -> tuple:
    """Load parquet, clean, engineer features, split 80/20 train/test, scale."""
    df = pl.read_parquet(ROOT / data_path)

    # Drop Id
    if "Id" in df.columns:
        df = df.drop("Id")

    # Fill NA-means-none columns
    df = df.with_columns(
        pl.col(c).fill_null("NA") for c in NA_MEANS_NONE if c in df.columns
    )

    # Numeric imputation
    if "LotFrontage" in df.columns:
        df = df.with_columns(pl.col("LotFrontage").fill_null(pl.col("LotFrontage").median()))
    if "MasVnrArea" in df.columns:
        df = df.with_columns(pl.col("MasVnrArea").fill_null(0.0))
    if "GarageYrBlt" in df.columns:
        df = df.with_columns(pl.col("GarageYrBlt").fill_null(pl.col("YearBuilt")))

    # String imputation with mode
    for col_name in ["MasVnrType", "Electrical", "MSZoning"]:
        if col_name in df.columns and df[col_name].null_count() > 0:
            mode_val = df[col_name].drop_nulls().mode().item()
            df = df.with_columns(pl.col(col_name).fill_null(mode_val))

    # Drop remaining rows with nulls (should be very few)
    df = df.drop_nulls()

    # Drop low-impact columns if requested
    if drop_low_impact:
        df = df.drop([c for c in LOW_IMPACT_COLS if c in df.columns])

    # Separate target
    target = df[TARGET_COL].to_numpy().astype("float64")
    df = df.drop(TARGET_COL)

    # Identify column types
    cat_cols = [c for c in df.columns if df[c].dtype == pl.String]
    num_cols = [c for c in df.columns if c not in cat_cols]

    # Split ordinal vs nominal categoricals
    ordinal_cols = [c for c in cat_cols if c in ORDINAL_FEATURES]
    nominal_cols = [c for c in cat_cols if c not in ORDINAL_FEATURES]

    features = df.to_pandas()

    features_train, features_test, target_train, target_test = train_test_split(
        features, target, test_size=0.2, random_state=42
    )

    transformers = [(StandardScaler(), num_cols)]
    if ordinal_cols:
        ordinal_categories = [ORDINAL_FEATURES[c] for c in ordinal_cols]
        transformers.append((OrdinalEncoder(categories=ordinal_categories, handle_unknown="use_encoded_value", unknown_value=-1), ordinal_cols))
    if nominal_cols:
        transformers.append((OneHotEncoder(handle_unknown="ignore", sparse_output=False), nominal_cols))

    preprocessor = make_column_transformer(*transformers)

    features_train = preprocessor.fit_transform(features_train)
    features_test = preprocessor.transform(features_test)

    return features_train, features_test, target_train, target_test, preprocessor
