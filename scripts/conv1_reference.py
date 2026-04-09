import os
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEST_VECTOR_DIR = os.path.join(BASE_DIR, "fpga", "test_vectors")
WEIGHTS_DIR = os.path.join(BASE_DIR, "fpga", "weights")
OUT_DIR = os.path.join(BASE_DIR, "fpga", "test_vectors")

# Layer names from your exported no-BN model
CONV1_W_PATH = os.path.join(WEIGHTS_DIR, "conv1d_5_w0.npy")
CONV1_B_PATH = os.path.join(WEIGHTS_DIR, "conv1d_5_w1.npy")
INPUT_PATH = os.path.join(TEST_VECTOR_DIR, "sample_input_float.npy")


def conv1d_same(x: np.ndarray, w: np.ndarray, b: np.ndarray) -> np.ndarray:
    """
    x: (time_steps, in_channels)
    w: (kernel_size, in_channels, out_channels)
    b: (out_channels,)
    returns: (time_steps, out_channels)
    Implements Conv1D with padding='same', stride=1
    """
    time_steps, in_channels = x.shape
    kernel_size, w_in_channels, out_channels = w.shape

    if in_channels != w_in_channels:
        raise ValueError(
            f"Input channels mismatch: x has {in_channels}, weights expect {w_in_channels}"
        )

    pad_total = kernel_size - 1
    pad_left = pad_total // 2
    pad_right = pad_total - pad_left

    x_padded = np.pad(
        x,
        pad_width=((pad_left, pad_right), (0, 0)),
        mode="constant",
        constant_values=0.0,
    )

    y = np.zeros((time_steps, out_channels), dtype=np.float32)

    for t in range(time_steps):
        window = x_padded[t:t + kernel_size, :]  # (kernel_size, in_channels)

        for oc in range(out_channels):
            acc = 0.0
            for k in range(kernel_size):
                for ic in range(in_channels):
                    acc += window[k, ic] * w[k, ic, oc]
            y[t, oc] = acc + b[oc]

    return y


def relu(x: np.ndarray) -> np.ndarray:
    return np.maximum(x, 0.0).astype(np.float32)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    print("Loading input and Conv1D layer 1 weights...")
    x = np.load(INPUT_PATH).astype(np.float32)      # shape: (3000, 2)
    w = np.load(CONV1_W_PATH).astype(np.float32)    # shape: (7, 2, 16)
    b = np.load(CONV1_B_PATH).astype(np.float32)    # shape: (16,)

    print(f"Input shape       : {x.shape}")
    print(f"Conv1 weight shape: {w.shape}")
    print(f"Conv1 bias shape  : {b.shape}")

    print("Running Conv1D layer 1 reference...")
    conv_out = conv1d_same(x, w, b)                 # shape: (3000, 16)
    relu_out = relu(conv_out)                       # shape: (3000, 16)

    conv_out_npy = os.path.join(OUT_DIR, "conv1_output_float.npy")
    conv_out_txt = os.path.join(OUT_DIR, "conv1_output_float.txt")
    relu_out_npy = os.path.join(OUT_DIR, "conv1_relu_output_float.npy")
    relu_out_txt = os.path.join(OUT_DIR, "conv1_relu_output_float.txt")

    np.save(conv_out_npy, conv_out)
    np.savetxt(conv_out_txt, conv_out.reshape(-1), fmt="%.8f")

    np.save(relu_out_npy, relu_out)
    np.savetxt(relu_out_txt, relu_out.reshape(-1), fmt="%.8f")

    print("Saved reference outputs:")
    print(" -", conv_out_npy)
    print(" -", conv_out_txt)
    print(" -", relu_out_npy)
    print(" -", relu_out_txt)
    print("Output shape:", conv_out.shape)
    print("ReLU output shape:", relu_out.shape)
    print("Done.")


if __name__ == "__main__":
    main()