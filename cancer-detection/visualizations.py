"""
Cancer Detection - Visualizations

Plotly charts for EDA and model evaluation.
"""

import optuna
import plotly.graph_objects as go
import plotly.subplots as sp
import polars as pl
from sklearn.metrics import confusion_matrix

COLORS = {"B": "steelblue", "M": "coral"}


def plot_class_distribution(data: pl.DataFrame) -> go.Figure:
    """Bar chart of Benign vs Malignant counts."""
    counts = data["diagnosis"].value_counts().sort("diagnosis")
    return go.Figure(
        data=go.Bar(
            x=["Benign", "Malignant"],
            y=counts["count"].to_list(),
            marker_color=[COLORS["B"], COLORS["M"]],
            text=counts["count"].to_list(),
            textposition="outside",
        ),
        layout=go.Layout(
            title="Class Distribution",
            yaxis_title="Count",
            width=500, height=400,
        ),
    )


def plot_scatter_pairs(
    data: pl.DataFrame,
    feature_pairs: list[tuple[str, str, str]],
    title: str,
) -> go.Figure:
    """Subplot grid of scatter plots coloured by diagnosis."""
    cols = 2
    rows = -(-len(feature_pairs) // cols)  # ceiling division
    figure = sp.make_subplots(rows=rows, cols=cols, subplot_titles=[t for _, _, t in feature_pairs])

    for index, (x_col, y_col, _) in enumerate(feature_pairs):
        row, col = divmod(index, cols)
        for label, name in [("B", "Benign"), ("M", "Malignant")]:
            subset = data.filter(pl.col("diagnosis") == label)
            figure.add_trace(
                go.Scatter(
                    x=subset[x_col].to_list(),
                    y=subset[y_col].to_list(),
                    mode="markers",
                    name=name,
                    marker=dict(color=COLORS[label], opacity=0.5, size=5),
                    showlegend=(index == 0),
                ),
                row=row + 1, col=col + 1,
            )
        figure.update_xaxes(title_text=x_col, row=row + 1, col=col + 1)
        figure.update_yaxes(title_text=y_col, row=row + 1, col=col + 1)

    figure.update_layout(title_text=title, height=400 * rows, width=900)
    return figure


def plot_feature_distributions(data: pl.DataFrame, features: list[str]) -> go.Figure:
    """Overlapping histograms per feature, Benign vs Malignant."""
    cols = 2
    rows = -(-len(features) // cols)
    figure = sp.make_subplots(rows=rows, cols=cols, subplot_titles=features)

    for index, feature in enumerate(features):
        row, col = divmod(index, cols)
        for label, name in [("B", "Benign"), ("M", "Malignant")]:
            subset = data.filter(pl.col("diagnosis") == label)
            figure.add_trace(
                go.Histogram(
                    x=subset[feature].to_list(),
                    name=name,
                    marker_color=COLORS[label],
                    opacity=0.6,
                    showlegend=(index == 0),
                ),
                row=row + 1, col=col + 1,
            )

    figure.update_layout(
        title_text="Feature Distributions by Diagnosis",
        barmode="overlay",
        height=400 * rows,
        width=900,
    )
    return figure


def plot_confusion_matrix(y_true, y_pred, model_name: str) -> go.Figure:
    """Heatmap confusion matrix for binary classification."""
    matrix = confusion_matrix(y_true, y_pred)
    labels = ["Benign", "Malignant"]
    return go.Figure(
        data=go.Heatmap(
            z=matrix, x=labels, y=labels,
            text=matrix, texttemplate="%{text}", textfont={"size": 18},
            colorscale="Blues", colorbar=dict(title="Count"),
        ),
        layout=go.Layout(
            title=f"{model_name} — Confusion Matrix (Test Set)",
            xaxis_title="Predicted", yaxis_title="Actual",
            width=500, height=450,
        ),
    )


def plot_cross_validation_scores(cross_validation_scores: dict, model_name: str) -> go.Figure:
    """Bar chart of per-fold train vs test accuracy from cross_validate()."""
    n_folds = len(cross_validation_scores["test_accuracy"])
    folds = [f"Fold {i + 1}" for i in range(n_folds)]
    figure = go.Figure()
    figure.add_trace(go.Bar(name="Train", x=folds, y=cross_validation_scores["train_accuracy"], marker_color="steelblue"))
    figure.add_trace(go.Bar(name="Test", x=folds, y=cross_validation_scores["test_accuracy"], marker_color="coral"))
    figure.update_layout(
        title=f"{model_name} — Cross-Validation Accuracy per Fold",
        xaxis_title="Fold", yaxis_title="Accuracy",
        yaxis_range=[0.8, 1.0], barmode="group",
        width=700, height=450, hovermode="x unified",
    )
    return figure


def plot_optuna_trials(study: optuna.Study, model_name: str) -> go.Figure:
    """Scatter plot of Optuna trial accuracy over k values."""
    trials = pl.DataFrame({
        "k": [trial.params["n_neighbors"] for trial in study.trials],
        "accuracy": [trial.value for trial in study.trials],
    }).sort("k")
    return go.Figure(
        data=go.Scatter(
            x=trials["k"].to_list(),
            y=trials["accuracy"].to_list(),
            mode="markers",
            marker=dict(size=8, color=trials["accuracy"].to_list(), colorscale="Blues", showscale=True),
            text=[f"k={k}, acc={a:.4f}" for k, a in zip(trials["k"].to_list(), trials["accuracy"].to_list())],
            hoverinfo="text",
        ),
        layout=go.Layout(
            title=f"{model_name} — Optuna Trial Accuracy by k",
            xaxis_title="k (n_neighbors)", yaxis_title="Cross-Validation Accuracy",
            width=700, height=450,
        ),
    )


def plot_metrics_comparison(
    model_names: list[str],
    test_accuracies: list[float],
    test_precisions: list[float],
    test_recalls: list[float],
) -> go.Figure:
    """Grouped bar chart comparing accuracy, precision, recall across models."""
    figure = go.Figure()
    for metric, values, color in [
        ("Accuracy", test_accuracies, "steelblue"),
        ("Precision", test_precisions, "coral"),
        ("Recall", test_recalls, "mediumseagreen"),
    ]:
        figure.add_trace(go.Bar(
            name=metric, x=model_names, y=values,
            marker_color=color,
            text=[f"{v:.4f}" for v in values], textposition="outside",
        ))
    figure.update_layout(
        title="Model Comparison — Test Set Metrics",
        yaxis_range=[0.85, 1.02], barmode="group",
        width=700, height=450, hovermode="x unified",
    )
    return figure
