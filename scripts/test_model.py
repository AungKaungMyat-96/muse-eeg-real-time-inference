import os
import numpy as np
import tensorflow as tf
from preprocessing import prepare_model_input

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "models", "stroke_eeg_cnn_model.keras")
X_TEST_PATH = os.path.join(BASE_DIR, "data", "X_test_eeg.npy")
Y_TEST_PATH = os.path.join(BASE_DIR, "data", "y_test_eeg.npy")

LABELS = {
    0: "Normal",
    1: "Stroke-like"
}


def main():
    print("Loading model...")
    model = tf.keras.models.load_model(MODEL_PATH)

    print("Loading test data...")
    x_test = np.load(X_TEST_PATH)
    y_test = np.load(Y_TEST_PATH)

    print(f"x_test shape: {x_test.shape}")
    print(f"y_test shape: {y_test.shape}")

    sample = x_test[0]
    sample_input = prepare_model_input(sample)

    pred = model.predict(sample_input, verbose=0)
    pred_class = int(np.argmax(pred, axis=1)[0])
    confidence = float(np.max(pred))

    print("\n=== Prediction Result ===")
    print(f"Predicted class : {LABELS[pred_class]}")
    print(f"Confidence      : {confidence:.4f}")
    print(f"True label      : {LABELS[int(y_test[0])]}")


if __name__ == "__main__":
    main()