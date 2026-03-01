"""
Basic exploratory plots for motion data.

Usage:
    python -m ml.scripts.plot_basic
"""

from __future__ import annotations

import matplotlib.pyplot as plt

from .load_sessions import load_all_sessions


def main() -> None:
    samples_df, meta_df = load_all_sessions()
    if samples_df.empty:
        print("No samples available; export data from the iOS app first.")
        return

    print("Loaded", len(samples_df), "samples from", len(meta_df), "sessions.")

    # Simple accelerometer magnitude over time for a single session
    session_id = samples_df["session_id"].iloc[0]
    df_session = samples_df[samples_df["session_id"] == session_id].copy()

    df_session["acc_mag"] = (df_session["accX"] ** 2 + df_session["accY"] ** 2 + df_session["accZ"] ** 2) ** 0.5

    plt.figure(figsize=(10, 4))
    plt.plot(df_session["timestamp"], df_session["acc_mag"], linewidth=0.5)
    plt.title(f"Accelerometer magnitude over time (session {session_id})")
    plt.xlabel("Timestamp (s)")
    plt.ylabel("Acceleration magnitude (g)")
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()

