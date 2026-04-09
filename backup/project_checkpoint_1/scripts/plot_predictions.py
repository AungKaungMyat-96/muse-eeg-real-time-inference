import os
import pandas as pd
import matplotlib.pyplot as plt

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV_PATH = os.path.join(BASE_DIR, "outputs", "live_muse_predictions.csv")
PLOTS_DIR = os.path.join(BASE_DIR, "outputs", "plots")


def main():
    os.makedirs(PLOTS_DIR, exist_ok=True)

    df = pd.read_csv(CSV_PATH)
    print(df.head())

    df["samples_seen"] = pd.to_numeric(df["samples_seen"])
    df["predicted_num"] = df["predicted_class"].map({
        "Normal": 0,
        "Stroke-like": 1
    })

    # 1. Confidence plot
    plt.figure()
    plt.plot(df["samples_seen"], df["confidence"])
    plt.xlabel("Samples Seen")
    plt.ylabel("Confidence")
    plt.title("Prediction Confidence Over Time")
    plt.grid()
    plt.savefig(os.path.join(PLOTS_DIR, "confidence_over_time.png"), dpi=300, bbox_inches="tight")

    # 2. Stroke probability plot
    plt.figure()
    plt.plot(df["samples_seen"], df["stroke_prob"])
    plt.xlabel("Samples Seen")
    plt.ylabel("Stroke Probability")
    plt.title("Stroke Probability Over Time")
    plt.grid()
    plt.savefig(os.path.join(PLOTS_DIR, "stroke_probability_over_time.png"), dpi=300, bbox_inches="tight")

    # 3. Normal probability plot
    plt.figure()
    plt.plot(df["samples_seen"], df["normal_prob"])
    plt.xlabel("Samples Seen")
    plt.ylabel("Normal Probability")
    plt.title("Normal Probability Over Time")
    plt.grid()
    plt.savefig(os.path.join(PLOTS_DIR, "normal_probability_over_time.png"), dpi=300, bbox_inches="tight")

    # 4. Predicted class plot
    plt.figure()
    plt.plot(df["samples_seen"], df["predicted_num"])
    plt.xlabel("Samples Seen")
    plt.ylabel("Predicted Class (0=Normal, 1=Stroke)")
    plt.title("Predicted Class Over Time")
    plt.grid()
    plt.savefig(os.path.join(PLOTS_DIR, "predicted_class_over_time.png"), dpi=300, bbox_inches="tight")

    plt.show()


if __name__ == "__main__":
    main()