## ML playground

The `ml/` directory contains the Python tooling for working with motion logs exported from the iOS `BikeLogger` app:

- Ingest and clean session data from `data/`.
- Engineer windowed features for biking vs. non-biking classification.
- Train and evaluate baseline and advanced models.
- Export selected models to Core ML format (`.mlmodel`) for use on-device.

### Environment setup

1. Create and activate a virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate  # on macOS / Linux
# .venv\\Scripts\\activate  # on Windows
```

2. Install dependencies:

```bash
pip install -r ml/requirements.txt
```

3. (Optional) Install Jupyter:

```bash
pip install jupyter
```

### Layout

- `requirements.txt`: Python dependencies.
- `scripts/`: CLI utilities for data ingestion, feature extraction, training, and Core ML export.
- `notebooks/`: Jupyter notebooks for ad-hoc exploration and visualization.

### Typical workflow

1. Copy exported motion log files from the iOS app into the top-level `data/` directory.
2. Use `scripts/load_sessions.py` to load and sanity-check the data.
3. Use `scripts/train_baseline_models.py` to train and evaluate models.
4. Use `scripts/export_coreml.py` to convert a chosen model into a `.mlmodel` file in `models/`.
5. Add the exported `.mlmodel` to the iOS project for on-device inference.

