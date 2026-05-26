import os
from datetime import datetime

import numpy as np


SRC_INPUT_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense1_relu_expected_int32.mem"
SRC_W_FLOAT = r"C:/Users/Lenovo/Documents/muse-eeg-real-time-inference/fpga/weights/dense_5_w0.npy"
SRC_B_FLOAT = r"C:/Users/Lenovo/Documents/muse-eeg-real-time-inference/fpga/weights/dense_5_w1.npy"
SRC_W_INT8_CANDIDATES = [
    r"C:/Users/Lenovo/Documents/muse-eeg-real-time-inference/fpga/test_vectors/dense2_weights_int8.npy",
    r"C:/Users/Lenovo/Documents/muse-eeg-real-time-inference/fpga/weights/dense_5_w0_int8.npy",
]
SRC_B_INT32_CANDIDATES = [
    r"C:/Users/Lenovo/Documents/muse-eeg-real-time-inference/fpga/test_vectors/dense2_bias_int32.npy",
    r"C:/Users/Lenovo/Documents/muse-eeg-real-time-inference/fpga/weights/dense_5_w1_int32.npy",
]

DST_INPUT_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense2_input.mem"
DST_W_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/weights/dense2_w.mem"
DST_B_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/weights/dense2_b.mem"
DST_EXPECTED_MEM = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense2_expected_int32.mem"
DST_META = r"D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense2_export_metadata.txt"

IN_DIM = 32
OUT_DIM = 2


def ensure_parent(path):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def write_lines(path, values):
    ensure_parent(path)
    with open(path, "w") as f:
        for v in values:
            f.write("%d\n" % int(v))


def read_int_mem(path):
    vals = []
    with open(path, "r") as f:
        for line in f:
            s = line.strip()
            if s:
                vals.append(int(s))
    return vals


def stats(arr):
    arr64 = arr.astype(np.int64, copy=False)
    return int(arr64.min()), int(arr64.max()), int(arr64.sum())


def flatten_input(x):
    out = []
    for i in range(IN_DIM):
        out.append(int(x[i]))
    return out


def flatten_weights(w):
    out = []
    for c in range(OUT_DIM):
        for i in range(IN_DIM):
            out.append(int(w[i, c]))
    return out


def flatten_bias(b):
    out = []
    for c in range(OUT_DIM):
        out.append(int(b[c]))
    return out


def flatten_expected(y):
    out = []
    for c in range(OUT_DIM):
        out.append(int(y[c]))
    return out


def dense_raw_int32xint8(x_i32, w_i8, b_i32):
    y = np.zeros((OUT_DIM,), dtype=np.int32)
    for c in range(OUT_DIM):
        acc = int(b_i32[c])
        for i in range(IN_DIM):
            acc += int(x_i32[i]) * int(w_i8[i, c])
        y[c] = acc
    return y


def main():
    if not os.path.exists(SRC_INPUT_MEM):
        raise FileNotFoundError("Missing source file: %s" % SRC_INPUT_MEM)
    if not os.path.exists(SRC_W_FLOAT):
        raise FileNotFoundError("Missing source file: %s" % SRC_W_FLOAT)
    if not os.path.exists(SRC_B_FLOAT):
        raise FileNotFoundError("Missing source file: %s" % SRC_B_FLOAT)

    input_vals = read_int_mem(SRC_INPUT_MEM)
    if len(input_vals) != IN_DIM:
        raise ValueError("Input count mismatch. Expected %d, got %d" % (IN_DIM, len(input_vals)))
    x_i32 = np.array(input_vals, dtype=np.int32)

    w_float = np.load(SRC_W_FLOAT)
    if tuple(w_float.shape) != (IN_DIM, OUT_DIM):
        raise ValueError("Dense2 weight shape mismatch: %s" % (w_float.shape,))

    b_float = np.load(SRC_B_FLOAT)
    if tuple(b_float.shape) != (OUT_DIM,):
        raise ValueError("Dense2 bias shape mismatch: %s" % (b_float.shape,))

    w_i8 = None
    w_source = ""
    w_rule = ""
    for cand in SRC_W_INT8_CANDIDATES:
        if os.path.exists(cand):
            w_cand = np.load(cand)
            if tuple(w_cand.shape) == (IN_DIM, OUT_DIM):
                w_i8 = w_cand.astype(np.int8, copy=False)
                w_source = cand
                w_rule = "used_existing_int8_weight_file"
                break
    if w_i8 is None:
        w_i8 = np.clip(np.round(w_float), -128, 127).astype(np.int8)
        w_source = SRC_W_FLOAT
        w_rule = "int8_from_float_round_then_clip_to_minus128_127"

    b_i32 = None
    b_source = ""
    b_rule = ""
    for cand in SRC_B_INT32_CANDIDATES:
        if os.path.exists(cand):
            b_cand = np.load(cand)
            if tuple(b_cand.shape) == (OUT_DIM,):
                b_i32 = b_cand.astype(np.int32, copy=False)
                b_source = cand
                b_rule = "used_existing_int32_bias_file"
                break
    if b_i32 is None:
        b_i32 = np.zeros((OUT_DIM,), dtype=np.int32)
        b_source = "none"
        b_rule = "zero_bias_placeholder_for_raw_integer_dense2_alignment"

    y_i32 = dense_raw_int32xint8(x_i32, w_i8, b_i32)

    input_flat = flatten_input(x_i32)
    w_flat = flatten_weights(w_i8)
    b_flat = flatten_bias(b_i32)
    y_flat = flatten_expected(y_i32)

    write_lines(DST_INPUT_MEM, input_flat)
    write_lines(DST_W_MEM, w_flat)
    write_lines(DST_B_MEM, b_flat)
    write_lines(DST_EXPECTED_MEM, y_flat)

    x_min, x_max, x_sum = stats(x_i32)
    w_min, w_max, w_sum = stats(w_i8.astype(np.int32))
    b_min, b_max, b_sum = stats(b_i32)
    y_min, y_max, y_sum = stats(y_i32)

    ensure_parent(DST_META)
    with open(DST_META, "w") as f:
        f.write("timestamp_utc: %s\n" % (datetime.utcnow().isoformat() + "Z"))
        f.write("source_input_mem: %s\n" % SRC_INPUT_MEM)
        f.write("source_weight_float: %s\n" % SRC_W_FLOAT)
        f.write("source_bias_float: %s\n" % SRC_B_FLOAT)
        f.write("weight_source_used: %s\n" % w_source)
        f.write("weight_rule: %s\n" % w_rule)
        f.write("bias_source_used: %s\n" % b_source)
        f.write("bias_rule: %s\n" % b_rule)
        f.write("dest_input_mem: %s\n" % DST_INPUT_MEM)
        f.write("dest_weight_mem: %s\n" % DST_W_MEM)
        f.write("dest_bias_mem: %s\n" % DST_B_MEM)
        f.write("dest_expected_mem: %s\n" % DST_EXPECTED_MEM)
        f.write("input_shape: %s\n" % (x_i32.shape,))
        f.write("weights_shape: %s\n" % (w_i8.shape,))
        f.write("bias_shape: %s\n" % (b_i32.shape,))
        f.write("expected_shape: %s\n" % (y_i32.shape,))
        f.write("input_dtype: %s\n" % x_i32.dtype)
        f.write("weights_dtype: %s\n" % w_i8.dtype)
        f.write("bias_dtype: %s\n" % b_i32.dtype)
        f.write("expected_dtype: %s\n" % y_i32.dtype)
        f.write("input_count: %d\n" % len(input_flat))
        f.write("weights_count: %d\n" % len(w_flat))
        f.write("bias_count: %d\n" % len(b_flat))
        f.write("expected_count: %d\n" % len(y_flat))
        f.write("input_min: %d\n" % x_min)
        f.write("input_max: %d\n" % x_max)
        f.write("input_sum: %d\n" % x_sum)
        f.write("weights_min: %d\n" % w_min)
        f.write("weights_max: %d\n" % w_max)
        f.write("weights_sum: %d\n" % w_sum)
        f.write("bias_min: %d\n" % b_min)
        f.write("bias_max: %d\n" % b_max)
        f.write("bias_sum: %d\n" % b_sum)
        f.write("expected_min: %d\n" % y_min)
        f.write("expected_max: %d\n" % y_max)
        f.write("expected_sum: %d\n" % y_sum)
        f.write("activation_in_expected: none_raw_dense2_logits_no_softmax\n")
        f.write("flatten_input: for i in range(32): write input[i]\n")
        f.write("flatten_weights: for c in range(2): for i in range(32): write w[i,c]\n")
        f.write("flatten_bias: for c in range(2): write b[c]\n")
        f.write("flatten_expected: for c in range(2): write y[c]\n")
        f.write("format: decimal signed integer, one value per line, no commas, no brackets\n")

    print("Export completed.")
    print("Created:")
    print(" - %s" % DST_INPUT_MEM)
    print(" - %s" % DST_W_MEM)
    print(" - %s" % DST_B_MEM)
    print(" - %s" % DST_EXPECTED_MEM)
    print(" - %s" % DST_META)


if __name__ == "__main__":
    main()
