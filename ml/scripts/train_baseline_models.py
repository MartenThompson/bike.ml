"""
Train baseline classifiers for biking vs. not biking using windowed features.

Usage:
    python -m ml.scripts.train_baseline_models
"""

from __future__ import annotations

from pathlib import Path

import joblib  # type: ignore[import-untyped]
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split

from .load_sessions import load_all_sessions


ROOT = Path(__file__).resolve().parents[2]
MODELS_DIR = ROOT / "models"
MODELS_DIR.mkdir(exist_ok=True)


def make_windows(
    df: pd.DataFrame,
    window_seconds: float = 5.0,
    step_seconds: float = 2.5,
) -> tuple[np.ndarray, np.ndarray]:
    """
    Create simple statistical features over sliding windows, per session.

    Returns:
        X: feature matrix (n_windows, n_features)
        y: labels (n_windows,)
    """
    all_features = []
    all_labels = []

    for session_id, df_sess in df.groupby("session_id"):
        if "timestamp" not in df_sess or "label" not in df_sess:
            continue

        df_sess = df_sess.sort_values("timestamp").reset_index(drop=True)
        t = df_sess["timestamp"].to_numpy()
        labels = df_sess["label"].to_numpy()

        start_t = t[0]
        end_t = t[-1]

        w = window_seconds
        step = step_seconds

        cur_start = start_t
        while cur_start + w <= end_t:
            cur_end = cur_start + w
            mask = (t >= cur_start) & (t < cur_end)
            if not mask.any():
                cur_start += step
                continue

            window_df = df_sess.loc[mask]
            # Majority label in the window
            majority_label = window_df["label"].mode().iloc[0]
            # Skip windows with ambiguous labels if desired

            feats = []
            for col in ["accX", "accY", "accZ", "gyroX", "gyroY", "gyroZ"]:
                if col in window_df:
                    vals = window_df[col].to_numpy(dtype=float)
                    feats.extend(
                        [
                            float(np.mean(vals)),
                            float(np.std(vals)),
                            float(np.min(vals)),
                            float(np.max(vals)),
                        ]
                    )

            # acceleration magnitude stats
            if all(c in window_df for c in ["accX", "accY", "accZ"]):
                acc_mag = np.sqrt(
                    window_df["accX"].to_numpy(dtype=float) ** 2
                    + window_df["accY"].to_numpy(dtype=float) ** 2
                    + window_df["accZ"].to_numpy(dtype=float) ** 2
                )
                feats.extend(
                    [
                        float(np.mean(acc_mag)),
                        float(np.std(acc_mag)),
                        float(np.min(acc_mag)),
                        float(np.max(acc_mag)),
                    ]
                )

            all_features.append(feats)
            all_labels.append(majority_label)

            cur_start += step

    X = np.array(all_features, dtype=float)
    y = np.array(all_labels)
    return X, y


def encode_labels(y: np.ndarray) -> tuple[np.ndarray, dict]:
    classes = sorted(set(y.tolist()))
    mapping = {label: i for i, label in enumerate(classes)}
    y_encoded = np.array([mapping[label] for label in y], dtype=int)
    return y_encoded, mapping


def main() -> None:
    samples_df, meta_df = load_all_sessions()
    if samples_df.empty:
        print("No samples available; export data from the iOS app first.")
        return

    print("Loaded", len(samples_df), "samples from", len(meta_df), "sessions.")

    X, y = make_windows(samples_df)
    if X.size == 0:
        print("No windows generated; check data and parameters.")
        return

    y_encoded, label_mapping = encode_labels(y)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded
    )

    # Logistic regression baseline
    logreg = LogisticRegression(max_iter=1000)
    logreg.fit(X_train, y_train)
    y_pred_lr = logreg.predict(X_test)
    print("Logistic regression report:")
    print(classification_report(y_test, y_pred_lr, target_names=sorted(label_mapping)))

    joblib.dump(
        {
            "model": logreg,
            "label_mapping": label_mapping,
            "feature_description": "statistical windows over acc/gyro (mean, std, min, max + acc magnitude)",
        },
        MODELS_DIR / "baseline_logreg.pkl",
    )

    # Random forest baseline
    rf = RandomForestClassifier(
        n_estimators=100,
        max_depth=None,
        random_state=42,
        n_jobs=-1,
    )
    rf.fit(X_train, y_train)
    y_pred_rf = rf.predict(X_test)
    print("Random forest report:")
    print(classification_report(y_test, y_pred_rf, target_names=sorted(label_mapping)))

    joblib.dump(
        {
            "model": rf,
            "label_mapping": label_mapping,
            "feature_description": "statistical windows over acc/gyro (mean, std, min, max + acc magnitude)",
        },
        MODELS_DIR / "baseline_random_forest.pkl",
    )

    print("Saved models to", MODELS_DIR)


if __name__ == "__main__":
    main()

