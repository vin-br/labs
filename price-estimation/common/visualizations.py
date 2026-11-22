"""
Price Estimation - Visualizations

Plotly charts for model evaluation.
"""

import plotly.graph_objects as go


def plot_mlp_loss_curve(model, model_name: str = "MLP") -> go.Figure:
    """Line chart of training loss over iterations from MLPRegressor.loss_curve_."""
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
