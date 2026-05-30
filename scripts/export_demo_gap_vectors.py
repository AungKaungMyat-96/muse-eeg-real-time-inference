import os
from typing import Iterable, Tuple

import numpy as np
import tensorflow as tf

from preprocessing import prepare_model_input


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "models", "stroke_eeg_cnn_model.keras")
X_TEST_PATH = os.path.join(BASE_DIR, "data", "X_test_eeg.npy")
Y_TEST_PATH = os.path.join(BASE_DIR, "data", "y_test_eeg.npy")

VIVADO_DATA_DIR = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data"
VIVADO_HEX_DIR = os.path.join(VIVADO_DATA_DIR, "hex")
INDEX_CACHE_PATH = os.path.join(VIVADO_DATA_DIR, "demo_samples_selected_indices.npz")
META_PATH = os.path.join(VIVADO_DATA_DIR, "demo_gap_export_metadata.txt")


def _to_hex_i32(values: np.ndarray) -> np.ndarray:
    v = values.astype(np.int64)
    return np.array([f"{(int(x) & 0xFFFFFFFF):08X}" for x in v], dtype=object)


def _to_hex_i8(values: np.ndarray) -> np.ndarray:
    v = values.astype(np.int64)
    return np.array([f"{(int(x) & 0xFF):02X}" for x in v], dtype=object)


def _hex_i32_to_dec(lines: Iterable[str]) -> np.ndarray:
    out = []
    for s in lines:
        u = int(s, 16)
        if u >= 0x80000000:
            u -= 0x100000000
        out.append(u)
    return np.asarray(out, dtype=np.int32)


def _hex_i8_to_dec(lines: Iterable[str]) -> np.ndarray:
    out = []
    for s in lines:
        u = int(s, 16)
        if u >= 0x80:
            u -= 0x100
        out.append(u)
    return np.asarray(out, dtype=np.int8)


def _write_lines(path: str, lines: Iterable[str]) -> None:
    with open(path, "w", encoding="ascii") as f:
        for line in lines:
            f.write(f"{line}\n")


def _make_feature_models(model: tf.keras.Model) -> Tuple[tf.keras.Model, tf.keras.Model]:
    gap_layer = None
    dense2_softmax_layer = None
    for layer in model.layers:
        if isinstance(layer, tf.keras.layers.GlobalAveragePooling1D):
            gap_layer = layer
        if isinstance(layer, tf.keras.layers.Dense) and getattr(layer.activation, "__name__", "") == "softmax":
            dense2_softmax_layer = layer
    if gap_layer is None:
        raise RuntimeError("Could not find GlobalAveragePooling1D layer in model")
    if dense2_softmax_layer is None:
        raise RuntimeError("Could not find final Dense softmax layer in model")
    gap_model = tf.keras.Model(inputs=model.input, outputs=gap_layer.output)
    logits_model = tf.keras.Model(inputs=model.input, outputs=dense2_softmax_layer.input)
    return gap_model, logits_model


def main() -> None:
    os.makedirs(VIVADO_DATA_DIR, exist_ok=True)
    os.makedirs(VIVADO_HEX_DIR, exist_ok=True)

    if not os.path.exists(INDEX_CACHE_PATH):
        raise FileNotFoundError(
            f"Missing selected index cache: {INDEX_CACHE_PATH}. Run select_demo_samples_for_fpga.py first."
        )

    idx_data = np.load(INDEX_CACHE_PATH)
    idx_normal = int(idx_data["normal_index"])
    idx_abnormal = int(idx_data["abnormal_index"])

    model = tf.keras.models.load_model(MODEL_PATH)
    x_test = np.load(X_TEST_PATH)
    y_test = np.load(Y_TEST_PATH).astype(np.int32)

    gap_model, logits_model = _make_feature_models(model)

    def export_one(idx: int, tag: str) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        raw_sample = np.asarray(x_test[idx], dtype=np.float32)
        model_input = prepare_model_input(raw_sample)

        gap_f = np.asarray(gap_model.predict(model_input, verbose=0)[0], dtype=np.float32)
        if gap_f.shape[0] != 64:
            raise RuntimeError(f"Expected GAP length 64, got {gap_f.shape[0]} for {tag}")

        gap_i32 = np.trunc(gap_f).astype(np.int32)
        logits = np.asarray(logits_model.predict(model_input, verbose=0)[0], dtype=np.float32)
        probs = np.asarray(model.predict(model_input, verbose=0)[0], dtype=np.float32)
        pred = int(np.argmax(probs))

        mem_path = os.path.join(VIVADO_DATA_DIR, f"{tag}_gap_expected_int32.mem")
        hex_path = os.path.join(VIVADO_HEX_DIR, f"{tag}_gap_i32.hex")
        raw_hex_path = os.path.join(VIVADO_HEX_DIR, f"{tag}_conv1d_input_i8.hex")

        _write_lines(mem_path, [str(int(x)) for x in gap_i32])
        gap_hex = _to_hex_i32(gap_i32)
        _write_lines(hex_path, gap_hex)

        raw_i8 = np.rint(raw_sample).astype(np.int8).reshape(-1)
        raw_hex = _to_hex_i8(raw_i8)
        _write_lines(raw_hex_path, raw_hex)

        # Roundtrip checks
        gap_back = _hex_i32_to_dec(gap_hex)
        if not np.array_equal(gap_i32, gap_back):
            raise RuntimeError(f"Roundtrip failed for {tag} GAP i32 hex")

        raw_back = _hex_i8_to_dec(raw_hex)
        if not np.array_equal(raw_i8, raw_back):
            raise RuntimeError(f"Roundtrip failed for {tag} raw i8 hex")

        return gap_i32, logits, probs, np.array([pred, int(y_test[idx])], dtype=np.int32)

    normal_gap_i32, normal_logits, normal_probs, normal_labels = export_one(idx_normal, "normal")
    abnormal_gap_i32, abnormal_logits, abnormal_probs, abnormal_labels = export_one(idx_abnormal, "abnormal")

    with open(META_PATH, "w", encoding="ascii") as f:
        f.write("milestone: 10G real-sample GAP export\n")
        f.write(f"model_path: {MODEL_PATH}\n")
        f.write(f"x_test_path: {X_TEST_PATH}\n")
        f.write(f"y_test_path: {Y_TEST_PATH}\n")
        f.write(f"normal_index: {idx_normal}\n")
        f.write(f"normal_true_label: {int(normal_labels[1])}\n")
        f.write(f"normal_pred_label: {int(normal_labels[0])}\n")
        f.write(f"normal_logits: {normal_logits.tolist()}\n")
        f.write(f"normal_probs: {normal_probs.tolist()}\n")
        f.write(f"normal_gap_count: {normal_gap_i32.shape[0]}\n")
        f.write(f"abnormal_index: {idx_abnormal}\n")
        f.write(f"abnormal_true_label: {int(abnormal_labels[1])}\n")
        f.write(f"abnormal_pred_label: {int(abnormal_labels[0])}\n")
        f.write(f"abnormal_logits: {abnormal_logits.tolist()}\n")
        f.write(f"abnormal_probs: {abnormal_probs.tolist()}\n")
        f.write(f"abnormal_gap_count: {abnormal_gap_i32.shape[0]}\n")
        f.write("roundtrip_check_gap_i32: PASS\n")
        f.write("roundtrip_check_raw_i8: PASS\n")

    print("Export complete")
    print(f"Metadata: {META_PATH}")


if __name__ == "__main__":
    main()
