import os
from datetime import datetime

import numpy as np


SRC_DENSE1_RAW = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense1_expected_int32.mem"
DST_DENSE1_RELU = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense1_relu_expected_int32.mem"
DST_META = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense1_relu_export_metadata.txt"

COUNT = 32


def ensure_parent(path):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def read_int_mem(path):
    vals = []
    with open(path, "r") as f:
        for line in f:
            s = line.strip()
            if s:
                vals.append(int(s))
    return vals


def write_mem(path, values):
    ensure_parent(path)
    with open(path, "w") as f:
        for v in values:
            f.write("%d\n" % int(v))


def stats(arr):
    arr64 = arr.astype(np.int64, copy=False)
    return int(arr64.min()), int(arr64.max()), int(arr64.sum())


def main():
    if not os.path.exists(SRC_DENSE1_RAW):
        raise FileNotFoundError("Missing source file: %s" % SRC_DENSE1_RAW)

    raw_vals = read_int_mem(SRC_DENSE1_RAW)
    if len(raw_vals) != COUNT:
        raise ValueError("Input count mismatch. Expected %d, got %d" % (COUNT, len(raw_vals)))

    raw = np.array(raw_vals, dtype=np.int32)
    relu = np.maximum(raw, 0).astype(np.int32)
    relu_vals = [int(x) for x in relu]

    if len(relu_vals) != COUNT:
        raise ValueError("Output count mismatch. Expected %d, got %d" % (COUNT, len(relu_vals)))

    write_mem(DST_DENSE1_RELU, relu_vals)

    rmin, rmax, rsum = stats(relu)

    ensure_parent(DST_META)
    with open(DST_META, "w") as f:
        f.write("timestamp_utc: %s\n" % (datetime.utcnow().isoformat() + "Z"))
        f.write("source_dense1_raw_mem: %s\n" % SRC_DENSE1_RAW)
        f.write("dest_dense1_relu_mem: %s\n" % DST_DENSE1_RELU)
        f.write("input_count: %d\n" % len(raw_vals))
        f.write("output_count: %d\n" % len(relu_vals))
        f.write("relu_min: %d\n" % rmin)
        f.write("relu_max: %d\n" % rmax)
        f.write("relu_sum: %d\n" % rsum)
        f.write("rule: dense1_relu[o] = max(0, dense1_raw[o])\n")
        f.write("format: decimal signed integer, one value per line, no commas, no brackets\n")

    print("Milestone 7C Dense1 ReLU export completed.")
    print("Generated:")
    print(" - %s" % DST_DENSE1_RELU)
    print(" - %s" % DST_META)


if __name__ == "__main__":
    main()
