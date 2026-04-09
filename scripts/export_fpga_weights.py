import os
import numpy as np
import tensorflow as tf

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "models", "stroke_eeg_cnn_model_no_bn.keras")
OUT_DIR = os.path.join(BASE_DIR, "fpga", "weights")


def save_array_txt(path, arr, fmt="%.8f"):
    np.savetxt(path, arr.reshape(-1), fmt=fmt)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    print("Loading model...")
    model = tf.keras.models.load_model(MODEL_PATH)

    print("\nExporting layer weights...")
    for layer in model.layers:
        weights = layer.get_weights()
        if not weights:
            continue

        layer_name = layer.name
        print(f"\nLayer: {layer_name}")

        for i, w in enumerate(weights):
            print(f"  Weight {i}: shape={w.shape}")

            npy_path = os.path.join(OUT_DIR, f"{layer_name}_w{i}.npy")
            txt_path = os.path.join(OUT_DIR, f"{layer_name}_w{i}.txt")

            np.save(npy_path, w)
            save_array_txt(txt_path, w)

    print("\nAll FPGA weight files exported successfully.")
    print("Output folder:", OUT_DIR)


if __name__ == "__main__":
    main()