"""
Convert a trained scikit-learn model to Core ML format.

Usage:
    python -m ml.scripts.export_coreml --model baseline_random_forest.pkl --output BikeActivityClassifier.mlmodel
"""

from __future__ import annotations

import argparse
from pathlib import Path

import coremltools as ct  # type: ignore[import-untyped]
import joblib  # type: ignore[import-untyped]
import numpy as np

from .train_baseline_models import make_windows
from .load_sessions import load_all_sessions


ROOT = Path(__file__).resolve().parents[2]
MODELS_DIR = ROOT / "models"


def build_example_input() -> np.ndarray:
    """
    Build an example input feature vector to infer shape.

    Uses the same feature pipeline as train_baseline_models.make_windows.
    """
    samples_df, _ = load_all_sessions()
    if samples_df.empty:
        # Fallback to a dummy vector with the expected number of features (28).
        return np.zeros((1, 28), dtype=float)

    X, _ = make_windows(samples_df)
    if X.size == 0:
        return np.zeros((1, X.shape[1] if X.ndim == 2 else 28), dtype=float)
    return X[:1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--model",
        type=str,
        default="baseline_random_forest.pkl",
        help="Pickled model file in models/ to convert.",
    )
    parser.add_argument(
        "--output",
        type=str,
        default="BikeActivityClassifier.mlmodel",
        help="Output .mlmodel filename (stored in models/).",
    )
    args = parser.parse_args()

    model_path = MODELS_DIR / args.model
    if not model_path.exists():
        raise SystemExit(f"Model file not found: {model_path}")

    bundle = joblib.load(model_path)
    sk_model = bundle["model"]
    label_mapping = bundle["label_mapping"]

    example_input = build_example_input()

    # Convert to Core ML
    coreml_model = ct.converters.sklearn.convert(
        sk_model,
        input_features=[("features", ct.models.datatypes.Array(example_input.shape[1]))],
        output_feature_names=["classLabel"],
    )

    # Attach metadata
    coreml_model.author = "bike.ml"
    coreml_model.license = "See project LICENSE"
    coreml_model.short_description = "Baseline biking vs. not-biking classifier."
    coreml_model.user_defined_metadata = {
        "label_mapping": str(label_mapping),
        "feature_description": bundle.get("feature_description", ""),
    }

    output_path = MODELS_DIR / args.output
    coreml_model.save(output_path)
    print("Saved Core ML model to", output_path)


if __name__ == "__main__":
    main()

