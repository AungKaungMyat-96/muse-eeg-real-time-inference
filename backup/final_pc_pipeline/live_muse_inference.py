import os
import csv
import time
import numpy as np
import tensorflow as tf

from muse_adapter import MuseStreamAdapter
from preprocessing import prepare_model_input

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "models", "stroke_eeg_cnn_model.keras")
OUTPUTS_DIR = os.path.join(BASE_DIR, "outputs")
LOG_PATH = os.path.join(OUTPUTS_DIR, "live_muse_predictions.csv")

LABELS = {
    0: "Normal",
    1: "Stroke-like"
}

# Muse channel indices from your output:
# TP9=0, AF7=1, AF8=2, TP10=3, Right AUX=4
AF7_INDEX = 1
AF8_INDEX = 2

# Collect about 30 seconds of Muse data at ~256 Hz
MUSE_WINDOW_SAMPLES = 256 * 30

# Run inference every ~5 seconds of new Muse samples
MUSE_STEP_SAMPLES = 256 * 5


def ensure_output_dir():
    os.makedirs(OUTPUTS_DIR, exist_ok=True)


def init_csv_log():
    ensure_output_dir()
    with open(LOG_PATH, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "timestamp",
            "samples_seen",
            "predicted_class",
            "confidence",
            "normal_prob",
            "stroke_prob"
        ])


def append_csv_log(timestamp_str, samples_seen, predicted_class, confidence, normal_prob, stroke_prob):
    with open(LOG_PATH, "a", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            timestamp_str,
            samples_seen,
            predicted_class,
            f"{confidence:.6f}",
            f"{normal_prob:.6f}",
            f"{stroke_prob:.6f}"
        ])


def main():
    print("Loading model...")
    model = tf.keras.models.load_model(MODEL_PATH)

    init_csv_log()

    adapter = MuseStreamAdapter()
    adapter.connect()

    raw_buffer = []
    samples_seen = 0
    last_inference_at = 0

    print("Starting real Muse live inference...")
    print("Using channels: AF7 and AF8")

    while True:
        sample, ts = adapter.pull_sample()

        if sample is None:
            continue

        # Select only AF7 and AF8
        eeg_2ch = np.array([sample[AF7_INDEX], sample[AF8_INDEX]], dtype=np.float32)
        raw_buffer.append(eeg_2ch)
        samples_seen += 1

        # Keep only the latest 30 seconds
        if len(raw_buffer) > MUSE_WINDOW_SAMPLES:
            raw_buffer = raw_buffer[-MUSE_WINDOW_SAMPLES:]

        if samples_seen % 256 == 0:
            print(f"Collected Muse samples: {samples_seen}")

        if len(raw_buffer) == MUSE_WINDOW_SAMPLES:
            if last_inference_at == 0 or (samples_seen - last_inference_at) >= MUSE_STEP_SAMPLES:
                window = np.array(raw_buffer, dtype=np.float32)  # shape ~ (7680, 2)

                model_input = prepare_model_input(window)
                pred = model.predict(model_input, verbose=0)[0]

                pred_class = int(np.argmax(pred))
                confidence = float(np.max(pred))
                normal_prob = float(pred[0])
                stroke_prob = float(pred[1])

                timestamp_str = time.strftime("%Y-%m-%d %H:%M:%S")

                print("\n=== Muse Live Prediction ===")
                print(f"Time            : {timestamp_str}")
                print(f"Samples seen    : {samples_seen}")
                print(f"Predicted class : {LABELS[pred_class]}")
                print(f"Confidence      : {confidence:.4f}")
                print(f"Normal prob     : {normal_prob:.4f}")
                print(f"Stroke prob     : {stroke_prob:.4f}")

                append_csv_log(
                    timestamp_str=timestamp_str,
                    samples_seen=samples_seen,
                    predicted_class=LABELS[pred_class],
                    confidence=confidence,
                    normal_prob=normal_prob,
                    stroke_prob=stroke_prob,
                )

                last_inference_at = samples_seen


if __name__ == "__main__":
    main()