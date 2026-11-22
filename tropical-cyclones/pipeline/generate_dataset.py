"""Convert raw IBTrACS parquet to a cleaned base dataset for ML training.

Reads the single-header IBTrACS parquet, cleans whitespace/NaN values, derives
meteorological seasons from date and hemisphere, standardizes wind speed measurements
to a 1-min averaging time, and selects the final feature columns.
"""

from pathlib import Path

import numpy as np
import pandas as pd

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

_TEN_MIN_WIND_COLS = [
    "BOM_WIND",
    "WELLINGTON_WIND",
    "REUNION_WIND",
    "HKO_WIND",
    "TOKYO_WIND",
]
_WIND_FALLBACK = [
    "TD9636_WIND",
    "NEUMANN_WIND",
    "HKO_WIND",
    "TOKYO_WIND",
    "BOM_WIND",
    "WELLINGTON_WIND",
    "REUNION_WIND",
    "DS824_WIND",
]
_SELECTED_COLS = [
    "SEASON",
    "BASIN",
    "NATURE",
    "LAT",
    "LON",
    "WIND",
    "DIST2LAND",
    "STORM_SPEED",
    "STORM_DIR",
    "TD9636_STAGE",
]


def _get_season(date: pd.Timestamp, latitude: float) -> str:
    """Derive meteorological season from date and hemisphere (NOAA CPC)."""
    month = date.month
    if latitude >= 0:  # Northern Hemisphere
        match month:
            case 12 | 1 | 2:
                return "winter"
            case 3 | 4 | 5:
                return "spring"
            case 6 | 7 | 8:
                return "summer"
            case 9 | 10 | 11:
                return "fall"
    else:  # Southern Hemisphere
        match month:
            case 12 | 1 | 2:
                return "summer"
            case 3 | 4 | 5:
                return "fall"
            case 6 | 7 | 8:
                return "winter"
            case 9 | 10 | 11:
                return "spring"


def generate(
    input_path: Path | None = None,
    output_path: Path | None = None,
) -> pd.DataFrame:
    """Clean raw IBTrACS data and save as parquet.

    Steps:
    1. Replace whitespace-only strings with NaN, coerce numeric columns.
    2. Drop rows missing the target (TD9636_STAGE).
    3. Derive season from ISO_TIME + latitude.
    4. Standardize wind speed to 1-min averaging (10-min sources x 1.12).
    5. Fill missing WIND from fallback agency columns.
    6. Select final columns and drop remaining NaN rows.
    """
    input_path = input_path or DATA_DIR / "ibtracs_single_header.parquet"
    output_path = output_path or DATA_DIR / "base.parquet"

    df = pd.read_parquet(input_path, engine="pyarrow")

    pd.set_option("future.no_silent_downcasting", True)
    for col in df.columns:
        df[col] = df[col].replace(" ", np.nan)
        try:
            df[col] = pd.to_numeric(df[col])
        except ValueError:
            pass

    df = df.dropna(subset=["TD9636_STAGE"])
    df["ISO_TIME"] = pd.to_datetime(df["ISO_TIME"])

    df["SEASON"] = df.apply(lambda r: _get_season(r["ISO_TIME"], r["LAT"]), axis=1)

    # Standardize wind: rename USA_WIND, convert 10-min to 1-min, fill gaps
    df.rename(columns={"USA_WIND": "WIND"}, inplace=True)
    df[_TEN_MIN_WIND_COLS] = df[_TEN_MIN_WIND_COLS] * 1.12
    for col in _WIND_FALLBACK:
        df["WIND"] = df["WIND"].fillna(df[col])
    df = df.dropna(subset=["WIND"])

    result = df[_SELECTED_COLS].dropna()
    result.to_parquet(output_path, engine="pyarrow")
    print(f"Dataset saved to {output_path} ({len(result):,} rows)")
    return result
