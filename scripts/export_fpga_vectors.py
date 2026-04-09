import os
import numpy as np

from preprocessing import prepare_model_input

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
X_TEST_PATH = os.path.join(BASE_DIR, "data", "X_test_eeg.npy")
OUT_DIR = os.path.join(BASE_DIR, "fpga", "test_vectors")


def quantize_to_int8(x: np.ndarray):
    """
    Quantize float32 array to int8 using symmetric scaling.
    Returns quantized array and scale factor.
    """
    max_abs = np.max(np.abs(x))
    scale = 127.0 / max_abs if max_abs != 0 else 1.0
    x_q = np.round(x * scale).astype(np.int8)
    return x_q, scale


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    x_test = np.load(X_TEST_PATH)

    # Use first EEG sample
    raw_epoch = x_test[0]                 # shape (3000, 2)
    model_input = prepare_model_input(raw_epoch)[0]   # back to (3000, 2)

    # Save float version
    np.save(os.path.join(OUT_DIR, "sample_input_float.npy"), model_input)
    np.savetxt(
        os.path.join(OUT_DIR, "sample_input_float.txt"),
        model_input.reshape(-1),
        fmt="%.6f"
    )

    # Save quantized int8 version
    model_input_q, scale = quantize_to_int8(model_input)

    np.save(os.path.join(OUT_DIR, "sample_input_int8.npy"), model_input_q)
    np.savetxt(
        os.path.join(OUT_DIR, "sample_input_int8.txt"),
        model_input_q.reshape(-1),
        fmt="%d"
    )

    # Save scale factor
    with open(os.path.join(OUT_DIR, "sample_input_scale.txt"), "w") as f:
        f.write(f"{scale:.10f}\n")

    print("FPGA test vectors exported successfully.")
    print("Output folder:", OUT_DIR)
    print("Original shape:", raw_epoch.shape)
    print("Prepared shape:", model_input.shape)
    print("Quantized shape:", model_input_q.shape)
    print("Scale factor:", scale)


if __name__ == "__main__":
    main()