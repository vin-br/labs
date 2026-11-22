"""CLI for tropical cyclone intensity classification.

Commands:
    generate  - Convert raw IBTrACS data to cleaned base dataset.
    train     - Train PyTorch model with Optuna hyperparameter optimization.
"""

import argparse
from pathlib import Path

from pipeline.engine import run
from pipeline.generate_dataset import generate


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Tropical Cyclone Intensity Classification",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # -- generate --
    gen = subparsers.add_parser(
        "generate",
        help="Generate cleaned dataset from raw IBTrACS data",
    )
    gen.add_argument("--input", type=Path, default=None, help="Raw parquet path")
    gen.add_argument("--output", type=Path, default=None, help="Output parquet path")

    # -- train --
    tr = subparsers.add_parser(
        "train",
        help="Train PyTorch model with Optuna hyperparameter search",
    )
    tr.add_argument("--data", type=Path, default=None, help="Path to base.parquet")
    tr.add_argument(
        "--trials", type=int, default=50, help="Optuna trials (default: 50)"
    )
    tr.add_argument(
        "--epochs", type=int, default=50, help="Epochs per trial (default: 50)"
    )
    tr.add_argument(
        "--device",
        default="auto",
        choices=["auto", "cpu", "cuda", "mps"],
        help="Compute device (default: auto-detect)",
    )
    tr.add_argument(
        "--augment", action="store_true", help="Use SMOTE data augmentation"
    )
    tr.add_argument("--log-dir", default="runs", help="TensorBoard log directory")

    args = parser.parse_args()

    match args.command:
        case "generate":
            generate(input_path=args.input, output_path=args.output)

        case "train":
            run(
                data_path=args.data,
                n_trials=args.trials,
                epochs=args.epochs,
                device=args.device,
                augment=args.augment,
                log_dir=args.log_dir,
            )


if __name__ == "__main__":
    main()
