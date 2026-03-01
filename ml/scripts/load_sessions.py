"""
Utilities for loading motion sessions exported from the BikeLogger iOS app.

Expects files in ../data/ as documented in data/README.md:
- session_<SESSION_ID>.jsonl
- session_<SESSION_ID>_meta.json
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import List, Tuple

import pandas as pd


DATA_DIR = Path(__file__).resolve().parents[2] / "data"


@dataclass
class SessionFiles:
    session_id: str
    samples_path: Path
    meta_path: Path


def list_sessions(data_dir: Path | None = None) -> List[SessionFiles]:
    base = data_dir or DATA_DIR
    meta_files = sorted(base.glob("session_*_meta.json"))
    sessions: List[SessionFiles] = []
    for meta_path in meta_files:
        session_id = meta_path.stem.replace("session_", "").replace("_meta", "")
        samples_path = base / f"session_{session_id}.jsonl"
        if samples_path.exists():
            sessions.append(
                SessionFiles(
                    session_id=session_id,
                    samples_path=samples_path,
                    meta_path=meta_path,
                )
            )
    return sessions


def load_session(
    files: SessionFiles,
) -> Tuple[pd.DataFrame, dict]:
    """Load one session's samples and metadata."""
    # Load metadata
    meta = json.loads(files.meta_path.read_text())

    # Load JSONL samples
    records = []
    with files.samples_path.open() as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError:
                # Skip malformed lines; could log if desired
                continue

    df = pd.DataFrame.from_records(records)

    if not df.empty:
        # Convert timestamps to relative seconds within session if desired
        # (CMDeviceMotion timestamps are seconds since boot).
        df["timestamp"] = df["timestamp"].astype(float)

    return df, meta


def load_all_sessions(
    data_dir: Path | None = None,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Load all sessions into:
    - samples_df: concatenated samples with a 'session_id' column.
    - meta_df: one row per session with metadata.
    """
    sessions = list_sessions(data_dir=data_dir)
    all_samples: List[pd.DataFrame] = []
    meta_rows: List[dict] = []

    for files in sessions:
        df, meta = load_session(files)
        if df.empty:
            continue
        df["session_id"] = files.session_id
        all_samples.append(df)
        meta_rows.append(meta)

    samples_df = pd.concat(all_samples, ignore_index=True) if all_samples else pd.DataFrame()
    meta_df = pd.DataFrame(meta_rows)
    return samples_df, meta_df


def quick_summary() -> None:
    """Print a quick summary of available data."""
    samples_df, meta_df = load_all_sessions()
    if samples_df.empty:
        print("No samples found in data directory:", DATA_DIR)
        return

    print("Data directory:", DATA_DIR)
    print("Number of sessions:", meta_df.shape[0])
    print("Number of samples:", samples_df.shape[0])
    print("Labels distribution:")
    if "label" in samples_df.columns:
        print(samples_df["label"].value_counts())


if __name__ == "__main__":
    quick_summary()

