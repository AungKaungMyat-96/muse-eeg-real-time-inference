import numpy as np
from scipy.signal import resample


def normalize_epoch(epoch: np.ndarray) -> np.ndarray:
    epoch = epoch.astype(np.float32)
    mean = np.mean(epoch, axis=0, keepdims=True)
    std = np.std(epoch, axis=0, keepdims=True) + 1e-8
    return (epoch - mean) / std


def resample_epoch(epoch: np.ndarray, target_samples: int = 3000) -> np.ndarray:
    """
    Resample an EEG epoch from arbitrary length to target_samples.
    Input shape: (N, 2)
    Output shape: (target_samples, 2)
    """
    if epoch.ndim != 2 or epoch.shape[1] != 2:
        raise ValueError(f"Expected input shape (N, 2), got {epoch.shape}")

    resampled = resample(epoch, target_samples, axis=0)
    return resampled.astype(np.float32)


def prepare_model_input(epoch: np.ndarray) -> np.ndarray:
    """
    Prepare one epoch for model inference.
    Expected final input shape: (1, 3000, 2)
    """
    if epoch.ndim != 2 or epoch.shape[1] != 2:
        raise ValueError(f"Expected input shape (N, 2), got {epoch.shape}")

    if epoch.shape[0] != 3000:
        epoch = resample_epoch(epoch, target_samples=3000)

    epoch_norm = normalize_epoch(epoch)
    return np.expand_dims(epoch_norm, axis=0).astype(np.float32)