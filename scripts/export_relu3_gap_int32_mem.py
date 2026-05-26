import os
from datetime import datetime

import numpy as np


SRC_CONV3_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv3_expected_int32.mem"

DST_RELU3_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/relu3_expected_int32.mem"
DST_GAP_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/gap_expected_int32.mem"
DST_META = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/relu3_gap_export_metadata.txt"

L_IN = 750
F_OUT = 64


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


def flatten_t_f(arr):
    out = []
    for t in range(arr.shape[0]):
        for f in range(arr.shape[1]):
            out.append(int(arr[t, f]))
    return out


def stats(arr):
    arr64 = arr.astype(np.int64, copy=False)
    return int(arr64.min()), int(arr64.max()), int(arr64.sum())


def trunc_div_toward_zero(num, den):
    q = abs(num) // den
    return q if num >= 0 else -q


def main():
    if not os.path.exists(SRC_CONV3_MEM):
        raise FileNotFoundError("Missing source file: %s" % SRC_CONV3_MEM)

    conv3_vals = read_int_mem(SRC_CONV3_MEM)
    expected_in_count = L_IN * F_OUT
    if len(conv3_vals) != expected_in_count:
        raise ValueError(
            "Input count mismatch. Expected %d, got %d"
            % (expected_in_count, len(conv3_vals))
        )

    conv3 = np.array(conv3_vals, dtype=np.int32).reshape((L_IN, F_OUT))

    relu3 = np.maximum(conv3, 0).astype(np.int32)
    relu3_vals = flatten_t_f(relu3)

    gap = np.zeros((F_OUT,), dtype=np.int32)
    for f in range(F_OUT):
        s = int(np.int64(relu3[:, f]).sum())
        gap[f] = trunc_div_toward_zero(s, L_IN)
    gap_vals = [int(x) for x in gap]

    if len(relu3_vals) != (L_IN * F_OUT):
        raise ValueError("ReLU3 count mismatch. Expected %d, got %d" % (L_IN * F_OUT, len(relu3_vals)))
    if len(gap_vals) != F_OUT:
        raise ValueError("GAP count mismatch. Expected %d, got %d" % (F_OUT, len(gap_vals)))

    write_mem(DST_RELU3_MEM, relu3_vals)
    write_mem(DST_GAP_MEM, gap_vals)

    relu_min, relu_max, relu_sum = stats(relu3)
    gap_min, gap_max, gap_sum = stats(gap)

    ensure_parent(DST_META)
    with open(DST_META, "w") as f:
        f.write("timestamp_utc: %s\n" % (datetime.utcnow().isoformat() + "Z"))
        f.write("source_conv3_mem: %s\n" % SRC_CONV3_MEM)
        f.write("dest_relu3_mem: %s\n" % DST_RELU3_MEM)
        f.write("dest_gap_mem: %s\n" % DST_GAP_MEM)
        f.write("input_shape: %s\n" % (conv3.shape,))
        f.write("relu3_shape: %s\n" % (relu3.shape,))
        f.write("gap_shape: %s\n" % (gap.shape,))
        f.write("input_count: %d\n" % len(conv3_vals))
        f.write("relu3_count: %d\n" % len(relu3_vals))
        f.write("gap_count: %d\n" % len(gap_vals))
        f.write("relu3_min: %d\n" % relu_min)
        f.write("relu3_max: %d\n" % relu_max)
        f.write("relu3_sum: %d\n" % relu_sum)
        f.write("gap_min: %d\n" % gap_min)
        f.write("gap_max: %d\n" % gap_max)
        f.write("gap_sum: %d\n" % gap_sum)
        f.write("relu_rule: relu3[t,f] = max(0, conv3[t,f])\n")
        f.write("gap_rule: gap[f] = trunc_toward_zero(sum_t(relu3[t,f]) / 750)\n")
        f.write("gap_rounding: signed truncating integer division toward zero\n")
        f.write("flatten_relu3: for t in range(750): for f in range(64): write value\n")
        f.write("flatten_gap: for f in range(64): write value\n")
        f.write("format: decimal signed integer, one value per line, no commas, no brackets\n")

    print("Milestone 7A ReLU3+GAP export completed.")
    print("Generated:")
    print(" - %s" % DST_RELU3_MEM)
    print(" - %s" % DST_GAP_MEM)
    print(" - %s" % DST_META)


if __name__ == "__main__":
    main()
