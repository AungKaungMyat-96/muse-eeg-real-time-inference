import os
from typing import Optional, Tuple

import numpy as np
import tensorflow as tf

from preprocessing import prepare_model_input


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "models", "stroke_eeg_cnn_model.keras")
X_TEST_PATH = os.path.join(BASE_DIR, "data", "X_test_eeg.npy")
Y_TEST_PATH = os.path.join(BASE_DIR, "data", "y_test_eeg.npy")

OUT_DIR = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data"
METADATA_PATH = os.path.join(OUT_DIR, "demo_samples_metadata.txt")
INDEX_CACHE_PATH = os.path.join(OUT_DIR, "demo_samples_selected_indices.npz")


def _class_name(class_id: int) -> str:
    return "Normal" if class_id == 0 else "Stroke-like"


def _pick_correct_index(y_true: np.ndarray, y_pred: np.ndarray, target_class: int) -> int:
    candidates = np.where((y_true == target_class) & (y_pred == target_class))[0]
    if candidates.size == 0:
        raise RuntimeError(f"No correctly classified sample found for class {target_class}")
    return int(candidates[0])


def _get_logits_if_available(model: tf.keras.Model, sample_input: np.ndarray) -> Optional[np.ndarray]:
    logits_model: Optional[tf.keras.Model] = None
    for layer in model.layers[::-1]:
        if "dense" in layer.name.lower() and hasattr(layer, "activation"):
            if getattr(layer.activation, "__name__", "") == "softmax":
                logits_model = tf.keras.Model(inputs=model.input, outputs=layer.input)
                break
    if logits_model is None:
        return None
    logits = logits_model.predict(sample_input, verbose=0)[0]
    return np.asarray(logits, dtype=np.float32)


def _infer_one(model: tf.keras.Model, sample: np.ndarray, true_label: int) -> Tuple[int, np.ndarray, float, Optional[np.ndarray]]:
    sample_input = prepare_model_input(sample)
    probs = np.asarray(model.predict(sample_input, verbose=0)[0], dtype=np.float32)
    pred_label = int(np.argmax(probs))
    confidence = float(np.max(probs))
    logits = _get_logits_if_available(model, sample_input)
    print(f"true={true_label} pred={pred_label} probs={probs.tolist()} conf={confidence:.6f}")
    if logits is not None:
        print(f"logits={logits.tolist()}")
    return pred_label, probs, confidence, logits


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)

    print(f"Loading model: {MODEL_PATH}")
    model = tf.keras.models.load_model(MODEL_PATH)

    print(f"Loading test data: {X_TEST_PATH}")
    x_test = np.load(X_TEST_PATH)
    y_test = np.load(Y_TEST_PATH).astype(np.int32)

    print("Running model over test set...")
    probs_all = np.asarray(model.predict(x_test, verbose=0), dtype=np.float32)
    pred_all = np.argmax(probs_all, axis=1).astype(np.int32)

    idx_normal = _pick_correct_index(y_test, pred_all, target_class=0)
    idx_abnormal = _pick_correct_index(y_test, pred_all, target_class=1)

    print(f"Selected normal index   : {idx_normal}")
    print(f"Selected abnormal index : {idx_abnormal}")

    normal_pred, normal_probs, normal_conf, normal_logits = _infer_one(model, x_test[idx_normal], int(y_test[idx_normal]))
    abnormal_pred, abnormal_probs, abnormal_conf, abnormal_logits = _infer_one(model, x_test[idx_abnormal], int(y_test[idx_abnormal]))

    with open(METADATA_PATH, "w", encoding="ascii") as f:
        f.write("milestone: 10G real-sample LED demo\n")
        f.write(f"model_path: {MODEL_PATH}\n")
        f.write(f"x_test_path: {X_TEST_PATH}\n")
        f.write(f"y_test_path: {Y_TEST_PATH}\n")
        f.write("\n")
        f.write(f"normal_index: {idx_normal}\n")
        f.write(f"normal_true_label: {int(y_test[idx_normal])} ({_class_name(int(y_test[idx_normal]))})\n")
        f.write(f"normal_pred_label: {normal_pred} ({_class_name(normal_pred)})\n")
        f.write(f"normal_prob_0: {float(normal_probs[0]):.9f}\n")
        f.write(f"normal_prob_1: {float(normal_probs[1]):.9f}\n")
        f.write(f"normal_confidence: {normal_conf:.9f}\n")
        if normal_logits is not None:
            f.write(f"normal_logit_0: {float(normal_logits[0]):.9f}\n")
            f.write(f"normal_logit_1: {float(normal_logits[1]):.9f}\n")
        f.write("\n")
        f.write(f"abnormal_index: {idx_abnormal}\n")
        f.write(f"abnormal_true_label: {int(y_test[idx_abnormal])} ({_class_name(int(y_test[idx_abnormal]))})\n")
        f.write(f"abnormal_pred_label: {abnormal_pred} ({_class_name(abnormal_pred)})\n")
        f.write(f"abnormal_prob_0: {float(abnormal_probs[0]):.9f}\n")
        f.write(f"abnormal_prob_1: {float(abnormal_probs[1]):.9f}\n")
        f.write(f"abnormal_confidence: {abnormal_conf:.9f}\n")
        if abnormal_logits is not None:
            f.write(f"abnormal_logit_0: {float(abnormal_logits[0]):.9f}\n")
            f.write(f"abnormal_logit_1: {float(abnormal_logits[1]):.9f}\n")

    np.savez(INDEX_CACHE_PATH, normal_index=idx_normal, abnormal_index=idx_abnormal)
    print(f"Saved metadata: {METADATA_PATH}")
    print(f"Saved index cache: {INDEX_CACHE_PATH}")


if __name__ == "__main__":
    main()
