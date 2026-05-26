import os
from datetime import datetime

import numpy as np


SRC_INPUT_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\maxpool1_expected_int32.mem"
SRC_W_FLOAT = r"C:\Users\Lenovo\Documents\muse-eeg-real-time-inference\fpga\weights\conv1d_6_w0.npy"
SRC_B_FLOAT = r"C:\Users\Lenovo\Documents\muse-eeg-real-time-inference\fpga\weights\conv1d_6_w1.npy"
SRC_W_INT8_CANDIDATES = [
    r"C:\Users\Lenovo\Documents\muse-eeg-real-time-inference\fpga\test_vectors\conv2_weights_int8.npy",
    r"C:\Users\Lenovo\Documents\muse-eeg-real-time-inference\fpga\weights\conv1d_6_w0_int8.npy",
]

DST_INPUT_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\conv2_input.mem"
DST_W_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\weights\conv2_w.mem"
DST_B_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\weights\conv2_b.mem"
DST_EXPECTED_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\conv2_expected_int32.mem"
DST_META = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\conv2_export_metadata.txt"

L_IN = 1500
C_IN = 16
K = 5
F_OUT = 32
PAD_LEFT = 2


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


def flatten_input(inp):
    out = []
    for t in range(L_IN):
        for c in range(C_IN):
            out.append(int(inp[t, c]))
    return out


def flatten_weights(w):
    out = []
    for f in range(F_OUT):
        for k in range(K):
            for c in range(C_IN):
                out.append(int(w[k, c, f]))
    return out


def flatten_bias(b):
    out = []
    for f in range(F_OUT):
        out.append(int(b[f]))
    return out


def flatten_expected(exp):
    out = []
    for t in range(L_IN):
        for f in range(F_OUT):
            out.append(int(exp[t, f]))
    return out


def conv1d_same_int32xint8(inp_i32, w_i8, b_i32):
    y = np.zeros((L_IN, F_OUT), dtype=np.int32)
    for t in range(L_IN):
        for f in range(F_OUT):
            acc = int(b_i32[f])
            for k in range(K):
                in_t = t + k - PAD_LEFT
                if (in_t < 0) or (in_t >= L_IN):
                    continue
                for c in range(C_IN):
                    acc += int(inp_i32[in_t, c]) * int(w_i8[k, c, f])
            y[t, f] = acc
    return y


def main():
    if not os.path.exists(SRC_INPUT_MEM):
        raise FileNotFoundError("Missing source file: %s" % SRC_INPUT_MEM)
    if not os.path.exists(SRC_W_FLOAT):
        raise FileNotFoundError("Missing source file: %s" % SRC_W_FLOAT)
    if not os.path.exists(SRC_B_FLOAT):
        raise FileNotFoundError("Missing source file: %s" % SRC_B_FLOAT)

    input_vals = read_int_mem(SRC_INPUT_MEM)
    if len(input_vals) != (L_IN * C_IN):
        raise ValueError(
            "Input count mismatch. Expected %d, got %d"
            % (L_IN * C_IN, len(input_vals))
        )

    inp_i32 = np.array(input_vals, dtype=np.int32).reshape((L_IN, C_IN))

    w_float = np.load(SRC_W_FLOAT)
    if tuple(w_float.shape) != (K, C_IN, F_OUT):
        raise ValueError("Conv2 weight shape mismatch: %s" % (w_float.shape,))

    b_float = np.load(SRC_B_FLOAT)
    if tuple(b_float.shape) != (F_OUT,):
        raise ValueError("Conv2 bias shape mismatch: %s" % (b_float.shape,))

    w_i8 = None
    w_source = ""
    w_rule = ""
    for cand in SRC_W_INT8_CANDIDATES:
        if os.path.exists(cand):
            w_cand = np.load(cand)
            if tuple(w_cand.shape) == (K, C_IN, F_OUT):
                w_i8 = w_cand.astype(np.int8, copy=False)
                w_source = cand
                w_rule = "used_existing_int8_weight_file"
                break

    if w_i8 is None:
        w_i8 = np.clip(np.round(w_float), -128, 127).astype(np.int8)
        w_source = SRC_W_FLOAT
        w_rule = "int8_from_float_round_then_clip_to_minus128_127"

    b_i32 = np.zeros((F_OUT,), dtype=np.int32)
    bias_mode = "zero_bias_placeholder_for_raw_integer_conv2_alignment"

    exp_i32 = conv1d_same_int32xint8(inp_i32, w_i8, b_i32)

    input_flat = flatten_input(inp_i32)
    w_flat = flatten_weights(w_i8)
    b_flat = flatten_bias(b_i32)
    exp_flat = flatten_expected(exp_i32)

    write_lines(DST_INPUT_MEM, input_flat)
    write_lines(DST_W_MEM, w_flat)
    write_lines(DST_B_MEM, b_flat)
    write_lines(DST_EXPECTED_MEM, exp_flat)

    i_min, i_max, i_sum = stats(inp_i32)
    w_min, w_max, w_sum = stats(w_i8.astype(np.int32))
    b_min, b_max, b_sum = stats(b_i32)
    e_min, e_max, e_sum = stats(exp_i32)

    ensure_parent(DST_META)
    with open(DST_META, "w") as f:
        f.write("timestamp_utc: %s\n" % (datetime.utcnow().isoformat() + "Z"))
        f.write("source_input_mem: %s\n" % SRC_INPUT_MEM)
        f.write("source_weight_float: %s\n" % SRC_W_FLOAT)
        f.write("source_bias_float: %s\n" % SRC_B_FLOAT)
        f.write("weight_source_used: %s\n" % w_source)
        f.write("weight_rule: %s\n" % w_rule)
        f.write("bias_mode: %s\n" % bias_mode)
        f.write("dest_input_mem: %s\n" % DST_INPUT_MEM)
        f.write("dest_weight_mem: %s\n" % DST_W_MEM)
        f.write("dest_bias_mem: %s\n" % DST_B_MEM)
        f.write("dest_expected_mem: %s\n" % DST_EXPECTED_MEM)
        f.write("input_shape: %s\n" % (inp_i32.shape,))
        f.write("weights_shape: %s\n" % (w_i8.shape,))
        f.write("bias_shape: %s\n" % (b_i32.shape,))
        f.write("expected_shape: %s\n" % (exp_i32.shape,))
        f.write("input_dtype: %s\n" % inp_i32.dtype)
        f.write("weights_dtype: %s\n" % w_i8.dtype)
        f.write("bias_dtype: %s\n" % b_i32.dtype)
        f.write("expected_dtype: %s\n" % exp_i32.dtype)
        f.write("input_count: %d\n" % len(input_flat))
        f.write("weights_count: %d\n" % len(w_flat))
        f.write("bias_count: %d\n" % len(b_flat))
        f.write("expected_count: %d\n" % len(exp_flat))
        f.write("input_min: %d\n" % i_min)
        f.write("input_max: %d\n" % i_max)
        f.write("input_sum: %d\n" % i_sum)
        f.write("weights_min: %d\n" % w_min)
        f.write("weights_max: %d\n" % w_max)
        f.write("weights_sum: %d\n" % w_sum)
        f.write("bias_min: %d\n" % b_min)
        f.write("bias_max: %d\n" % b_max)
        f.write("bias_sum: %d\n" % b_sum)
        f.write("expected_min: %d\n" % e_min)
        f.write("expected_max: %d\n" % e_max)
        f.write("expected_sum: %d\n" % e_sum)
        f.write("padding: SAME\n")
        f.write("pad_left: 2\n")
        f.write("stride: 1\n")
        f.write("flatten_input: for t in range(1500): for c in range(16): write input[t,c]\n")
        f.write("flatten_weights: for f in range(32): for k in range(5): for c in range(16): write weight[k,c,f]\n")
        f.write("flatten_bias: for f in range(32): write bias[f]\n")
        f.write("flatten_expected: for t in range(1500): for f in range(32): write output[t,f]\n")
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
