from django.urls import path
from . import views

app_name = "app"

urlpatterns = [
    path("", views.index, name="index"),
    path("submit-form/", views.make_prediction, name="submit_form"),
    path(
        "most-recent/",
        views.display_most_recent_predictions,
        name="most_recent_storm",
    ),
    path("get-id/<str:value>/", views.get_cyclone_by_id, name="by_sid"),
]
