import os
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEST_VECTOR_DIR = os.path.join(BASE_DIR, "fpga", "test_vectors")
WEIGHTS_DIR = os.path.join(BASE_DIR, "fpga", "weights")

INPUT_Q_PATH = os.path.join(TEST_VECTOR_DIR, "sample_input_int8.npy")
INPUT_SCALE_PATH = os.path.join(TEST_VECTOR_DIR, "sample_input_scale.txt")

CONV1_W_PATH = os.path.join(WEIGHTS_DIR, "conv1d_5_w0.npy")
CONV1_B_PATH = os.path.join(WEIGHTS_DIR, "conv1d_5_w1.npy")


def quantize_weights_int8(w: np.ndarray):
    max_abs = np.max(np.abs(w))
    scale = 127.0 / max_abs if max_abs != 0 else 1.0
    w_q = np.round(w * scale).astype(np.int8)
    return w_q, scale


def conv1d_same_int8(x_q: np.ndarray, w_q: np.ndarray) -> np.ndarray:
    """
    x_q: (time_steps, in_channels) int8
    w_q: (kernel_size, in_channels, out_channels) int8
    returns: (time_steps, out_channels) int32
    """
    time_steps, in_channels = x_q.shape
    kernel_size, w_in_channels, out_channels = w_q.shape

    if in_channels != w_in_channels:
        raise ValueError(
            f"Input channels mismatch: x has {in_channels}, weights expect {w_in_channels}"
        )

    pad_total = kernel_size - 1
    pad_left = pad_total // 2
    pad_right = pad_total - pad_left

    x_padded = np.pad(
        x_q,
        pad_width=((pad_left, pad_right), (0, 0)),
        mode="constant",
        constant_values=0,
    )

    y = np.zeros((time_steps, out_channels), dtype=np.int32)

    for t in range(time_steps):
        window = x_padded[t:t + kernel_size, :]  # (kernel_size, in_channels)

        for oc in range(out_channels):
            acc = 0
            for k in range(kernel_size):
                for ic in range(in_channels):
                    acc += int(window[k, ic]) * int(w_q[k, ic, oc])
            y[t, oc] = acc

    return y


def main():
    print("Loading quantized input...")
    x_q = np.load(INPUT_Q_PATH).astype(np.int8)
    input_scale = float(open(INPUT_SCALE_PATH).read().strip())

    print("Loading float weights...")
    w = np.load(CONV1_W_PATH).astype(np.float32)
    b = np.load(CONV1_B_PATH).astype(np.float32)

    print("Quantizing Conv1 weights...")
    w_q, w_scale = quantize_weights_int8(w)

    print(f"Input int8 shape  : {x_q.shape}")
    print(f"Weight int8 shape : {w_q.shape}")
    print(f"Bias float shape  : {b.shape}")
    print(f"Input scale       : {input_scale}")
    print(f"Weight scale      : {w_scale}")

    print("Running quantized Conv1 reference...")
    y_int32 = conv1d_same_int8(x_q, w_q)

    # Save raw int32 accumulator output
    out_int32_npy = os.path.join(TEST_VECTOR_DIR, "conv1_output_int32.npy")
    out_int32_txt = os.path.join(TEST_VECTOR_DIR, "conv1_output_int32.txt")
    np.save(out_int32_npy, y_int32)
    np.savetxt(out_int32_txt, y_int32.reshape(-1), fmt="%d")

    # Save quantized weights too
    w_q_npy = os.path.join(TEST_VECTOR_DIR, "conv1_weights_int8.npy")
    w_q_txt = os.path.join(TEST_VECTOR_DIR, "conv1_weights_int8.txt")
    np.save(w_q_npy, w_q)
    np.savetxt(w_q_txt, w_q.reshape(-1), fmt="%d")

    # Save scales
    scale_txt = os.path.join(TEST_VECTOR_DIR, "conv1_quant_scales.txt")
    with open(scale_txt, "w") as f:
        f.write(f"input_scale={input_scale}\n")
        f.write(f"weight_scale={w_scale}\n")

    print("Saved quantized Conv1 reference outputs:")
    print(" -", out_int32_npy)
    print(" -", out_int32_txt)
    print(" -", w_q_npy)
    print(" -", w_q_txt)
    print(" -", scale_txt)
    print("Output shape:", y_int32.shape)
    print("Done.")


if __name__ == "__main__":
    main()