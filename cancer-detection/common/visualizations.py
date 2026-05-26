"""
Cancer Detection - Visualizations

Plotly charts for EDA and model evaluation.
"""

import optuna
import plotly.graph_objects as go
import plotly.subplots as sp
import polars as pl

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
    rows = -(-len(feature_pairs) // cols)
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


def plot_mlp_loss_curve(model, model_name: str = "MLP") -> go.Figure:
    """Line chart of training loss over iterations from MLPClassifier.loss_curve_."""
    return go.Figure(
        data=go.Scatter(
            x=list(range(1, len(model.loss_curve_) + 1)),
            y=model.loss_curve_,
            mode="lines",
            line=dict(color="steelblue", width=2),
        ),
        layout=go.Layout(
            title=f"{model_name} — Training Loss Curve",
            xaxis_title="Iteration", yaxis_title="Loss",
            width=700, height=450,
        ),
    )
