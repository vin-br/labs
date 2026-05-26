"""
Survival Prediction - Visualizations

Plotly charts for EDA and model evaluation.
"""

import optuna
import plotly.graph_objects as go
import plotly.subplots as sp
import polars as pl

COLORS = {0: "steelblue", 1: "coral"}
SURVIVED_LABELS = {0: "Did not survive", 1: "Survived"}


def plot_survival_distribution(data: pl.DataFrame) -> go.Figure:
    """Bar chart of survival counts."""
    counts = data["Survived"].value_counts().sort(by="Survived")
    return go.Figure(
        data=go.Bar(
            x=["Did not survive", "Survived"],
            y=counts["count"].to_list(),
            marker_color=[COLORS[0], COLORS[1]],
            text=counts["count"].to_list(),
            textposition="outside",
        ),
        layout=go.Layout(
            title="Survival Distribution",
            yaxis_title="Count",
            width=500, height=400,
        ),
    )


def plot_survival_by_category(
    data: pl.DataFrame,
    category_pairs: list[tuple[str, str, str]],
    title: str,
) -> go.Figure:
    """Subplot grid of bar charts showing mean survival rate per category, split by a second var."""
    cols = 2
    rows = -(-len(category_pairs) // cols)
    figure = sp.make_subplots(rows=rows, cols=cols, subplot_titles=[t for _, _, t in category_pairs]) # noqa: E501

    for index, (x_col, hue_col, _) in enumerate(category_pairs):
        row, col = divmod(index, cols)
        hue_values = data[hue_col].unique().sort().to_list()
        for hue_val in hue_values:
            subset = data.filter(pl.col(hue_col) == hue_val)
            rates = subset.group_by(x_col).agg(pl.col("Survived").mean()).sort(x_col)
            figure.add_trace(
                go.Bar(
                    x=rates[x_col].cast(pl.String).to_list(),
                    y=rates["Survived"].to_list(),
                    name=str(hue_val),
                    showlegend=(index == 0),
                ),
                row=row + 1, col=col + 1,
            )
        figure.update_xaxes(title_text=x_col, row=row + 1, col=col + 1)
        figure.update_yaxes(title_text="Survival Rate", row=row + 1, col=col + 1)

    figure.update_layout(title_text=title, barmode="group", height=400 * rows, width=900)
    return figure


def plot_feature_distributions(data: pl.DataFrame, features: list[str]) -> go.Figure:
    """Overlapping histograms per feature, split by survival."""
    cols = 2
    rows = -(-len(features) // cols)
    figure = sp.make_subplots(rows=rows, cols=cols, subplot_titles=features)

    for index, feature in enumerate(features):
        row, col = divmod(index, cols)
        for survived, label in SURVIVED_LABELS.items():
            subset = data.filter(pl.col("Survived") == survived)
            figure.add_trace(
                go.Histogram(
                    x=subset[feature].to_list(),
                    name=label,
                    marker_color=COLORS[survived],
                    opacity=0.6,
                    showlegend=(index == 0),
                ),
                row=row + 1, col=col + 1,
            )

    figure.update_layout(
        title_text="Feature Distributions by Survival",
        barmode="overlay",
        height=400 * rows,
        width=900,
    )
    return figure


def plot_optuna_trials(study: optuna.Study, model_name: str, param_name: str) -> go.Figure:
    """Scatter plot of Optuna trial accuracy over a hyperparameter."""
    trials = pl.DataFrame({
        "param": [trial.params[param_name] for trial in study.trials],
        "accuracy": [trial.value for trial in study.trials],
    }).sort("param")
    return go.Figure(
        data=go.Scatter(
            x=trials["param"].to_list(),
            y=trials["accuracy"].to_list(),
            mode="markers",
            marker=dict(size=8, color=trials["accuracy"].to_list(), colorscale="Blues", showscale=True),# noqa: E501
            text=[f"{param_name}={p}, acc={a:.4f}" for p, a in zip(trials["param"].to_list(), trials["accuracy"].to_list())],  # noqa: E501
            hoverinfo="text",
        ),
        layout=go.Layout(
            title=f"{model_name} — Optuna Trial Accuracy by {param_name}",
            xaxis_title=param_name, yaxis_title="Cross-Validation Accuracy",
            width=700, height=450,
        ),
    )
