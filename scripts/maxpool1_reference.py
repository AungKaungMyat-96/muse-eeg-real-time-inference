import os
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEST_VECTOR_DIR = os.path.join(BASE_DIR, "fpga", "test_vectors")

INPUT_PATH = os.path.join(TEST_VECTOR_DIR, "conv1_relu_output_float.npy")


def maxpool1d(x: np.ndarray, pool_size: int = 2, stride: int = 2) -> np.ndarray:
    """
    x: (time_steps, channels)
    returns: (pooled_time_steps, channels)
    """
    time_steps, channels = x.shape
    out_time = (time_steps - pool_size) // stride + 1

    y = np.zeros((out_time, channels), dtype=np.float32)

    for t in range(out_time):
        start = t * stride
        end = start + pool_size
        window = x[start:end, :]   # shape: (pool_size, channels)
        y[t, :] = np.max(window, axis=0)

    return y


def main():
    print("Loading Conv1 ReLU output...")
    x = np.load(INPUT_PATH).astype(np.float32)   # shape: (3000, 16)

    print(f"Input shape: {x.shape}")
    print("Running MaxPooling1D reference...")

    y = maxpool1d(x, pool_size=2, stride=2)      # shape: (1500, 16)

    out_npy = os.path.join(TEST_VECTOR_DIR, "maxpool1_output_float.npy")
    out_txt = os.path.join(TEST_VECTOR_DIR, "maxpool1_output_float.txt")

    np.save(out_npy, y)
    np.savetxt(out_txt, y.reshape(-1), fmt="%.8f")

    print("Saved maxpool reference outputs:")
    print(" -", out_npy)
    print(" -", out_txt)
    print("Output shape:", y.shape)
    print("Done.")


if __name__ == "__main__":
    main()