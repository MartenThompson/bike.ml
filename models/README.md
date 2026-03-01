## Models

This directory stores trained models and their exported Core ML counterparts.

Typical contents:

- `baseline_logreg.pkl`: Pickled logistic regression model trained by `ml/scripts/train_baseline_models.py`.
- `baseline_random_forest.pkl`: Pickled random forest model trained by `ml/scripts/train_baseline_models.py`.
- `BikeActivityClassifier.mlmodel`: Core ML model exported by `ml/scripts/export_coreml.py`.
- `metadata.json` (optional): Tracking model version, training config, and feature definitions.

Models in this directory are **artifacts**, not source; they can be regenerated from data in `data/` using the scripts in `ml/scripts/`.

