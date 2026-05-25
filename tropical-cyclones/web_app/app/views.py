import json
import requests
from datetime import datetime

import pandas as pd
import plotly.express as px
import plotly.io as pio

from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Max
from django.db import connection

from logger import logging
from app.models import Cyclone
from app.methods import classify, check_form_submit, populate_database


if "app_cyclone" in connection.introspection.table_names():
    if not Cyclone.objects.exists():
        logging.info("The database is empty")
        populate_database()


def index(request):

    return render(request, "index.html")


def get_cyclone_chart(request):

    # Fetch most recent cyclone data
    url = "http://127.0.0.1:8000/most-recent?nb_predictions=1"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        df_ = pd.DataFrame(data)

        # Check if required columns exist
        if {"LAT", "LON", "TD9636_STAGE", "WIND", "PRESSURE"}.issubset(
            df_.columns
        ):
            fig = px.scatter_geo(
                df_,
                lat="LAT",
                lon="LON",
                color="TD9636_STAGE",
                size="WIND",
                hover_name="PRESSURE",
                projection="natural earth",
            )

            fig.update_layout(
                title="Most Recent Cyclone",
                geo=dict(
                    showland=True,
                    landcolor="lightgray",
                    showcountries=True,
                    countrycolor="black",
                ),
            )

            # Convert Plotly figure to HTML
            plot_html = pio.to_html(fig, full_html=False)

        else:
            plot_html = "<p>Error: Unexpected data format.</p>"
    else:
        plot_html = f"<p>Error fetching data: {response.status_code}</p>"

    return JsonResponse({"plot_html": plot_html})


@csrf_exempt
def make_prediction(request):
    try:
        if request.method == "POST":
            data = json.loads(request.body)

            check_form_submit(data)

            # create new entry
            logging.debug("inserting new cyclone into the database")

            new_cyclone = Cyclone.objects.create(
                cyclone_id=data["cyclone_id"],
                season=datetime.strptime(data["season"], "%Y-%m-%d %H:%M:%S"),
                basin=data["basin"],
                nature=data["nature"],
                latitude=data["latitude"],
                longitude=data["longitude"],
                wind=data["wind"],
                dist2land=data["dist2land"],
                storm_dir=data["storm_dir"],
                storm_speed=data["storm_speed"],
            )
            logging.debug("object created")

            # get the id to be able to update the cyclone entry later
            cyclone_id = new_cyclone.id
            logging.debug(f"cyclone {cyclone_id} inserted")

            # send data to the model to make a prediction
            result = classify(data)

            # update stage of the cyclone entry
            logging.debug(f"updating stage of cyclone {cyclone_id}")

            Cyclone.objects.filter(id=cyclone_id).update(stage=result)

            logging.debug(f"cyclone {cyclone_id} updated")

            return JsonResponse(
                {
                    "message": "Form submitted!",
                    "cyclone_id": new_cyclone.cyclone_id,
                    "stage": result,
                    "status": 200,
                }
            )
        return JsonResponse({"error": "Invalid request"}, status=400)

    except ValueError as error:
        return JsonResponse({"error": error}, status=400)


def display_most_recent_predictions(request):
    try:
        nb_predictions = int(request.GET.get("nb_predictions", 1))
        # Get the n most recent unique cyclone IDs
        if nb_predictions > 1:
            logging.debug(
                f"fetching the last {str(nb_predictions)} cyclones in the DB"
            )
        else:
            logging.debug("fetching the last cyclone in the database")

        # recent_cyclone_ids = (
        #     Cyclone.objects.order_by("-season")
        #     .values_list("cyclone_id", flat=True)
        #     .distinct()[:nb_predictions]
        # )

        # Fetch the most recent season for each unique cyclone_id
        recent_cyclone_ids = (
            Cyclone.objects.values("cyclone_id")
            .annotate(
                latest_season=Max("season")
            )  # Get the latest season per cyclone
            .order_by("-latest_season")[
                :nb_predictions
            ]  # Order by latest season
        )

        # Extract only the cyclone_id values
        recent_cyclone_ids = [
            entry["cyclone_id"] for entry in recent_cyclone_ids
        ]

        logging.debug(f"Recent cyclone IDs: {recent_cyclone_ids}")

        latest_cyclones = Cyclone.objects.filter(
            cyclone_id__in=recent_cyclone_ids
        ).order_by("-season")

        if latest_cyclones.exists():
            data = list(latest_cyclones.values())
            logging.debug("nb_prediction " + str(nb_predictions))
            # logging.debug(data)

            return JsonResponse(
                {"message": "Form submitted!", "data": data, "status": 200}
            )
        return JsonResponse({"error": "No data found"}, status=404)

    except ValueError as error:
        return JsonResponse({"error": error}, status=404)


def get_cyclone_by_id(request, value: str):

    logging.debug(f"fetching the cyclone with ID {value}")

    cyclones = Cyclone.objects.filter(cyclone_id=value)

    if cyclones.exists():
        data = list(cyclones.values())
        # logging.debug(data)

        return JsonResponse(
            {"message": "Form submitted!", "data": data, "status": 200}
        )
    return JsonResponse({"error": "No data found"}, status=404)
