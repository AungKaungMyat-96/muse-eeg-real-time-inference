import os
from datetime import datetime

import numpy as np


SRC_CONV2_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv2_expected_int32.mem"
DST_POOL2_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/pool2_expected_int32.mem"
DST_META = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/pool2_export_metadata.txt"

L_IN = 1500
F_IN = 32
POOL_SIZE = 2
STRIDE = 2
L_OUT = 750


def ensure_parent(path):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def read_int_mem(path):
    values = []
    with open(path, "r") as f:
        for line in f:
            s = line.strip()
            if s:
                values.append(int(s))
    return values


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


def main():
    if not os.path.exists(SRC_CONV2_MEM):
        raise FileNotFoundError("Missing source file: %s" % SRC_CONV2_MEM)

    conv2_vals = read_int_mem(SRC_CONV2_MEM)
    expected_input_count = L_IN * F_IN
    if len(conv2_vals) != expected_input_count:
        raise ValueError(
            "Input count mismatch. Expected %d, got %d"
            % (expected_input_count, len(conv2_vals))
        )

    conv2 = np.array(conv2_vals, dtype=np.int32).reshape((L_IN, F_IN))

    pool2 = np.zeros((L_OUT, F_IN), dtype=np.int32)
    for t in range(L_OUT):
        t0 = STRIDE * t
        t1 = t0 + 1
        for f in range(F_IN):
            a = int(conv2[t0, f])
            b = int(conv2[t1, f])
            pool2[t, f] = a if a >= b else b

    pool2_vals = flatten_t_f(pool2)
    expected_output_count = L_OUT * F_IN
    if len(pool2_vals) != expected_output_count:
        raise ValueError(
            "Output count mismatch. Expected %d, got %d"
            % (expected_output_count, len(pool2_vals))
        )

    write_mem(DST_POOL2_MEM, pool2_vals)

    out_min, out_max, out_sum = stats(pool2)
    ensure_parent(DST_META)
    with open(DST_META, "w") as f:
        f.write("timestamp_utc: %s\n" % (datetime.utcnow().isoformat() + "Z"))
        f.write("source_conv2_mem: %s\n" % SRC_CONV2_MEM)
        f.write("dest_pool2_mem: %s\n" % DST_POOL2_MEM)
        f.write("input_shape: %s\n" % (conv2.shape,))
        f.write("output_shape: %s\n" % (pool2.shape,))
        f.write("input_count: %d\n" % len(conv2_vals))
        f.write("output_count: %d\n" % len(pool2_vals))
        f.write("output_min: %d\n" % out_min)
        f.write("output_max: %d\n" % out_max)
        f.write("output_sum: %d\n" % out_sum)
        f.write("rule: pool2[t,f] = max(conv2[2*t,f], conv2[2*t+1,f])\n")
        f.write("pool_size: %d\n" % POOL_SIZE)
        f.write("stride: %d\n" % STRIDE)
        f.write("flatten_order: for t in range(750): for f in range(32): write value\n")
        f.write("format: decimal signed integer, one value per line, no commas, no brackets\n")

    print("Milestone 5A Pool2 export completed.")
    print("Generated:")
    print(" - %s" % DST_POOL2_MEM)
    print(" - %s" % DST_META)


if __name__ == "__main__":
    main()
