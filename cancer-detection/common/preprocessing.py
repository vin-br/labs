from pathlib import Path

import polars as pl
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).parent.parent


def load_and_prepare_data(
    data_path: str = "data/breast_cancer.parquet",
) -> tuple:
    """Load parquet, split 80/20 train/test, scale features."""
    dataframe = pl.read_parquet(ROOT / data_path)

    feature_columns = dataframe.columns[
        dataframe.columns.index("radius_mean"):dataframe.columns.index("fractal_dimension_worst") + 1  # noqa: E501
    ]
    features = dataframe.select(feature_columns).to_numpy()
    target = dataframe["diagnosis"].to_numpy()

    features_train, features_test, target_train, target_test = train_test_split(
        features, target, test_size=0.2, random_state=42
    )

    scaler = StandardScaler()
    features_train = scaler.fit_transform(features_train)
    features_test = scaler.transform(features_test)

    return features_train, features_test, target_train, target_test, scaler
