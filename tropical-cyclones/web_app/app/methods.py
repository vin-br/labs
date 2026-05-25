import joblib
from datetime import datetime
from logger import logging
from preprocessing_steps import StormDirTransformer
import pandas as pd

from app.models import Cyclone


def get_season(date, latitude):
    month = date.month

    if latitude >= 0:  # Northern Hemisphere
        match month:
            case 12 | 1 | 2: 
                return "Winter"
            case 3 | 4 | 5: 
                return "Spring"
            case 6 | 7 | 8:
                return "Summer"
            case 9 | 10 | 11: 
                return "Fall"
    
    else:  # Southern Hemisphere
        match month:
            case 12 | 1 | 2:
                return "Summer"
            case 3 | 4 | 5: 
                return  "Fall"
            case 6 | 7 | 8: 
                return "Winter"
            case 9 | 10 | 11: 
                return "Spring"
            
def classify(data):
    logging.info("starting machine learning classification")


    # load ML model
    # the weights contains the pre-processing step
    logging.info("loading machine learning model's weights")
    with open("app/data/weights/base_augmented_model_histGradientBoost.pkl", "rb") as f:
        loaded_model = joblib.load(f)

    
    # managing the date -> season
    data["season"] = get_season(datetime.strptime(data["season"], "%Y-%m-%d %H:%M:%S"), data["latitude"])

     # Make predictions
    logging.info("Categorizing new data")
    row = pd.json_normalize(data)

    # dropping id
    row.drop(columns=["cyclone_id"], inplace=True)

    # managing the columns' names discrepencies
    row.columns = row.columns.str.upper()
    row = row.rename(columns={"LATITUDE": 'LAT', "LONGITUDE": "LON"})


    predictions = loaded_model.predict(row)

    # returns a <class 'numpy.ndarray'> with a single class element 
    # so we just extract the first value
    predicted_class = predictions[0]

    return predicted_class


def check_form_submit(data):

    logging.debug("checking form submit content")
    logging.debug(data)
    logging.debug(type(data))
    logging.debug(data["season"])
    logging.debug(type(data["season"]))

    # wind
    logging.debug("checking wind")

    if type(data["wind"]) is not int:
        raise ValueError("Wind needs to be a number")

    logging.debug("checking season")

    # season
    try:
        datetime.strptime(data["season"], "%Y-%m-%d %H:%M:%S")
    except ValueError:
        raise ValueError(
            "Invalid date format for season. Expected 'YYYY-MM-DD HH:MM:SS'."
        )

    # basin
    logging.debug("checking basin")

    basin_list = ["NA", "EP", "WP", "NI", "SI", "SP", "SA"]
    if data["basin"].upper() not in basin_list:
        raise ValueError("Basin input invalid")

    # nature
    logging.debug("checking nature")

    nature_list = ["DS", "TS", "ET", "SS", "NR", "MX"]
    if data["nature"].upper() not in nature_list:
        raise ValueError("Nature input invalid")

    # latitude
    logging.debug("checking latitude")

    if type(data["latitude"]) is not int:
        raise ValueError("Latitude needs to be an integer")

    # longitude
    logging.debug("checking longitude")

    if type(data["longitude"]) is not int:
        raise ValueError("longitude needs to be an integer")

    # dist2land
    logging.debug("checking dist2land")

    if type(data["dist2land"]) is not int:
        raise ValueError("The distance to land needs to be an integer")

    # storm_speed
    logging.debug("checking storm_speed")

    if type(data["storm_speed"]) is not int:
        raise ValueError("The storm speed needs to be an integer")

    # storm_dir
    logging.debug("checking storm_dir")

    if type(data["storm_dir"]) is not int:
        raise ValueError("The storm direction needs to be an integer")

    logging.debug("form submit checked")


def populate_database():
    logging.debug("populating the database")

    df = pd.read_parquet("app/data/dataframe/dataframe.parquet", engine="pyarrow")

    # Get the most recent row for each ID
    latest_rows = df.sort_values('ISO_TIME', ascending=False).drop_duplicates(subset='SID')

    # Select the top 10 most recent IDs
    top_10_ids = latest_rows.nlargest(10, 'ISO_TIME')['SID']

    # Filter all rows corresponding to these IDs
    result_df = df[df['SID'].isin(top_10_ids)]

    logging.debug("inserting into database")

    for _, row in result_df.iterrows():    
    
        Cyclone.objects.create(
            cyclone_id=row["SID"],
            season=datetime.strftime(row["ISO_TIME"], "%Y-%m-%d %H:%M:%S"),
            basin=row["BASIN"],
            nature=row["NATURE"],
            latitude=row["LAT"],
            longitude=row["LON"],
            wind=row["WIND"],
            dist2land=row["DIST2LAND"],
            storm_dir=row["STORM_SPEED"],
            storm_speed=row["STORM_DIR"],
            stage=row["TD9636_STAGE"]
        )

    logging.debug("Database populated")
