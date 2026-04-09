import os
import csv
import time
import numpy as np
import tensorflow as tf

from buffer import EEGBuffer
from preprocessing import prepare_model_input
from simulated_stream import stream_multiple_windows

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "models", "stroke_eeg_cnn_model.keras")
OUTPUTS_DIR = os.path.join(BASE_DIR, "outputs")
LOG_PATH = os.path.join(OUTPUTS_DIR, "live_predictions.csv")

LABELS = {
    0: "Normal",
    1: "Stroke-like"
}


def ensure_output_dir():
    os.makedirs(OUTPUTS_DIR, exist_ok=True)


def init_csv_log():
    ensure_output_dir()
    if not os.path.exists(LOG_PATH):
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


def run_inference(model, window: np.ndarray, samples_seen: int):
    model_input = prepare_model_input(window)
    pred = model.predict(model_input, verbose=0)[0]

    pred_class = int(np.argmax(pred))
    confidence = float(np.max(pred))
    normal_prob = float(pred[0])
    stroke_prob = float(pred[1])

    timestamp_str = time.strftime("%Y-%m-%d %H:%M:%S")

    print("\n=== Live Prediction ===")
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


def main():
    print("Loading model...")
    model = tf.keras.models.load_model(MODEL_PATH)

    init_csv_log()

    eeg_buffer = EEGBuffer(max_samples=3000, n_channels=2)

    # Run inference every 500 new samples = every 5 seconds at 100 Hz
    inference_interval = 500
    last_inference_sample_count = 0

    print("Starting continuous simulated EEG stream...")

    for sample in stream_multiple_windows(start_index=0, num_windows=3, delay_sec=0.0005):
        eeg_buffer.add_sample(sample)

        if eeg_buffer.current_size() % 500 == 0 and eeg_buffer.current_size() <= 3000:
            print(f"Buffered samples: {eeg_buffer.current_size()}/3000")

        if eeg_buffer.is_full():
            samples_since_last_inference = eeg_buffer.total_samples_seen - last_inference_sample_count

            if last_inference_sample_count == 0 or samples_since_last_inference >= inference_interval:
                window = eeg_buffer.get_window()
                run_inference(
                    model=model,
                    window=window,
                    samples_seen=eeg_buffer.total_samples_seen
                )
                last_inference_sample_count = eeg_buffer.total_samples_seen

    print("\nStreaming finished.")
    print(f"Prediction log saved to: {LOG_PATH}")


if __name__ == "__main__":
    main()