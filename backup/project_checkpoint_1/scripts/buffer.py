import numpy as np
from collections import deque


class EEGBuffer:
    def __init__(self, max_samples: int = 3000, n_channels: int = 2):
        self.max_samples = max_samples
        self.n_channels = n_channels
        self.buffer = deque(maxlen=max_samples)
        self.total_samples_seen = 0

    def add_sample(self, sample: np.ndarray) -> None:
        sample = np.asarray(sample, dtype=np.float32)

        if sample.shape != (self.n_channels,):
            raise ValueError(
                f"Expected sample shape ({self.n_channels},), got {sample.shape}"
            )

        self.buffer.append(sample)
        self.total_samples_seen += 1

    def is_full(self) -> bool:
        return len(self.buffer) == self.max_samples

    def get_window(self) -> np.ndarray:
        if not self.is_full():
            raise ValueError("Buffer is not full yet.")
        return np.array(self.buffer, dtype=np.float32)

    def current_size(self) -> int:
        return len(self.buffer)