import numpy as np
from sklearn.base import BaseEstimator, ClassifierMixin
from sklearn.utils.validation import check_X_y, check_array, check_is_fitted
from sklearn.utils.multiclass import unique_labels
from sklearn.metrics import accuracy_score


def log_loss(A, y):
    return (1 / len(y)) * np.sum(-y * np.log(A) - (1 - y) * np.log(1 - A))


class CustomMLPClassifier(ClassifierMixin, BaseEstimator):
    """An example classifier which implements a 1-NN algorithm.
    For more information regarding how to build your own classifier, read more
    in the :ref:`User Guide <user_guide>`.
    Parameters
    ----------
    demo_param : str, default='demo'
    A parameter used for demonstation of how to pass and store paramters.
    Attributes
    ----------
    X_ : ndarray, shape (n_samples, n_features)
    The input passed during :meth:`fit`.
    y_ : ndarray, shape (n_samples,)
    The labels passed during :meth:`fit`.
    classes_ : ndarray, shape (n_classes,)
    The classes seen at :meth:`fit`.
    """

    def __init__(
        self, hidden_layers=[16, 16, 16], learning_rate=0.1, n_iter=1000
    ):
        self.hidden_layers = hidden_layers
        self.learning_rate = learning_rate
        self.n_iter = n_iter

    def _initialisation(self, layers):
        params = []
        for i in range(1, len(layers)):
            params.append(
                {
                    "W": np.random.randn(layers[i], layers[i - 1]),
                    "b": np.random.randn(layers[i], 1),
                }
            )
        return params

    def _forward_propagation(self, X):
        Z = self.params[0]["W"].dot(X) + self.params[0]["b"]
        activations = [1 / (1 + np.exp(-Z))]
        for p in self.params[1:]:
            Z = p["W"].dot(activations[-1]) + p["b"]
            activations.append(1 / (1 + np.exp(-Z)))
        return activations

    def _back_propagation(self, activations):
        Ws = [p["W"] for p in self.params]

        m = self.y_.shape[1]

        dZ = activations[-1] - self.y_
        gradients = [
            {
                "dW": 1 / m * dZ.dot(activations[-2].T),
                "db": 1 / m * np.sum(dZ, axis=1, keepdims=True),
            }
        ]

        for i in range(len(activations) - 2, 0, -1):
            dZ = (
                np.dot(Ws[i + 1].T, dZ) * activations[i] * (1 - activations[i])
            )
            gradients.append(
                {
                    "dW": 1 / m * dZ.dot(activations[i].T),
                    "db": 1 / m * np.sum(dZ, axis=1, keepdims=True),
                }
            )

        dZ = np.dot(Ws[1].T, dZ) * activations[0] * (1 - activations[0])
        gradients.append(
            {
                "dW": 1 / m * dZ.dot(self.X_.T),
                "db": 1 / m * np.sum(dZ, axis=1, keepdims=True),
            }
        )

        gradients.reverse()
        return gradients

    def _update(self, gradients):
        # W = W - learning_rate * dW
        # b = b - learning_rate * db
        # return (W, b)

        new_params = []

        for g, p in zip(gradients, self.params):
            new_params.append(
                {
                    "W": p["W"] - self.learning_rate * g["dW"],
                    "b": p["b"] - self.learning_rate * g["db"],
                }
            )

        return new_params

    def fit(self, X, y, return_fit_report=False):
        """A reference implementation of a fitting function for a classifier.
        Parameters
        ----------
        X : array-like, shape (n_samples, n_features)
            The training input samples.
        y : array-like, shape (n_samples,)
            The target values. An array of int.
        Returns
        -------
        self : object
            Returns self.
        """
        # Check that X and y have correct shape
        X, y = check_X_y(X, y)
        # Store the classes seen during fit
        self.classes_ = unique_labels(y)

        self.X_ = X.T
        self.y_ = y.reshape((1, y.shape[0]))

        self.params = self._initialisation(
            [self.X_.shape[0], *self.hidden_layers, self.y_.shape[0]]
        )

        train_loss = []
        train_acc = []

        for i in range(self.n_iter):
            activations = self._forward_propagation(self.X_)
            gradients = self._back_propagation(activations)
            self.params = self._update(gradients)

            if return_fit_report:
                train_loss.append(log_loss(
                    activations[-1].flatten(), self.y_.flatten()))
                y_pred = self.predict(X)
                train_acc.append(accuracy_score(self.y_.flatten(), y_pred))

        # Return the classifier
        return train_loss, train_acc

    def predict(self, X):
        """A reference implementation of a prediction for a classifier.
        Parameters
        ----------
        X : array-like, shape (n_samples, n_features)
            The input samples.
        Returns
        -------
        y : ndarray, shape (n_samples,)
            The label for each sample is the label of the closest sample
            seen during fit.
        """
        # Check is fit had been called
        check_is_fitted(self, ["X_", "y_"])

        # Input validation
        X = check_array(X)

        X = X.T

        # activations = self._forward_propagation(X)[-1]
        # return activations[-1] >= 0.5

        activations = self._forward_propagation(X)
        y_pred = activations[-1] >= 0.5
        return y_pred.flatten()

    def predict_proba(self, X):
        return self._forward_propagation(X)[-1]
