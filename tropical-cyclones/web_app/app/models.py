from django.db import models


class Cyclone(models.Model):
    cyclone_id = models.CharField(max_length=200)
    season = models.CharField(max_length=200)
    basin = models.CharField(max_length=200)
    nature = models.CharField(max_length=200)
    latitude = models.IntegerField()
    longitude = models.IntegerField()
    wind = models.IntegerField()
    dist2land = models.IntegerField()
    storm_dir = models.IntegerField()
    storm_speed = models.IntegerField()
    stage = models.CharField(max_length=200, default=None, null=True)
