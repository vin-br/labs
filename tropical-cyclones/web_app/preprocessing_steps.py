import numpy as np 
from sklearn.base import BaseEstimator, TransformerMixin

class StormDirTransformer(BaseEstimator, TransformerMixin):
    def __init__(self, col="STORM_DIR"):
        self.col = col

    def fit(self, X, y=None):
        return self  # Nothing to fit

    def transform(self, X):
        x = np.cos(np.radians(X[self.col]))
        y = np.sin(np.radians(X[self.col]))
        return np.c_[x, y]  # Returns a 2D array
    
    def get_feature_names_out(self, input_features=None):
        return [f"x", f"y"]