import os
import time
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
X_TEST_PATH = os.path.join(BASE_DIR, "data", "X_test_eeg.npy")


def stream_test_sample(window_index: int = 0, delay_sec: float = 0.001):
    """
    Simulate live EEG streaming by yielding one sample row at a time
    from one stored EEG test window.
    Each row has shape (2,)
    """
    x_test = np.load(X_TEST_PATH)

    if window_index < 0 or window_index >= len(x_test):
        raise IndexError(f"window_index {window_index} out of range. Total windows: {len(x_test)}")

    sample_window = x_test[window_index]  # shape: (3000, 2)

    for row in sample_window:
        yield row
        time.sleep(delay_sec)


def stream_multiple_windows(start_index: int = 0, num_windows: int = 3, delay_sec: float = 0.001):
    """
    Stream multiple stored windows one after another.
    Useful for testing continuous inference.
    """
    x_test = np.load(X_TEST_PATH)

    end_index = min(start_index + num_windows, len(x_test))

    for idx in range(start_index, end_index):
        sample_window = x_test[idx]
        for row in sample_window:
            yield row
            time.sleep(delay_sec)