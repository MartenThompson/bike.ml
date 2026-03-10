import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

import argparse


def plot_timeseries(df: pd.DataFrame):
    plt.plot(df['unix_time'], df['accel_x'], label='accX')
    plt.plot(df['unix_time'], df['accel_y'], label='accY')
    plt.plot(df['unix_time'], df['accel_z'], label='accZ')
    plt.legend()
    plt.show()

def fourier_transform(series: pd.Series):
    fft = np.fft.fft(series)
    fft_magnitude = np.abs(fft)
    fft_magnitude = fft_magnitude[:len(fft_magnitude)//2]
    plt.plot(fft_magnitude)
    plt.show()

def main():
    df = pd.read_csv('data/training_data_2026_03_01_155020.csv')
    print(df.head())
    print(df.describe())
    

    window_size = 50
    step_size = 25
    for i in range(0, len(df), step_size):
        window = df.iloc[i:i+window_size]
        fourier_transform(window['accel_x'])
    

    


if __name__ == "__main__":
    main()