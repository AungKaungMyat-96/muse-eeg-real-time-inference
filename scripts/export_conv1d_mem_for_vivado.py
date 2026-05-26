import os
from datetime import datetime

import numpy as np


SRC_INPUT = r"C:\Users\Lenovo\Documents\muse-eeg-real-time-inference\fpga\test_vectors\sample_input_int8.npy"
SRC_WEIGHTS = r"C:\Users\Lenovo\Documents\muse-eeg-real-time-inference\fpga\test_vectors\conv1_weights_int8.npy"
SRC_EXPECTED = r"C:\Users\Lenovo\Documents\muse-eeg-real-time-inference\fpga\test_vectors\conv1_output_int32.npy"
SRC_BIAS_INT32 = r"C:\Users\Lenovo\Documents\muse-eeg-real-time-inference\fpga\test_vectors\conv1_bias_int32.npy"

DST_INPUT_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\conv1d_input.mem"
DST_WEIGHTS_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\weights\conv1d_w.mem"
DST_BIAS_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\weights\conv1d_b.mem"
DST_EXPECTED_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\conv1d_expected_int32.mem"
DST_METADATA = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\conv1d_export_metadata.txt"

L_IN = 3000
C_IN = 2
K = 7
F_OUT = 16


def ensure_parent(path):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def validate_shape(name, arr, expected_shape):
    if tuple(arr.shape) != tuple(expected_shape):
        raise ValueError(
            "%s shape mismatch. Expected %s, got %s"
            % (name, expected_shape, arr.shape)
        )


def tensor_stats(arr):
    arr64 = arr.astype(np.int64, copy=False)
    return {
        "min": int(arr64.min()),
        "max": int(arr64.max()),
        "sum": int(arr64.sum()),
    }


def write_lines(path, values):
    ensure_parent(path)
    with open(path, "w") as f:
        for v in values:
            f.write("%d\n" % int(v))


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


def write_metadata(metadata):
    ensure_parent(DST_METADATA)
    with open(DST_METADATA, "w") as f:
        for key, value in metadata.items():
            f.write("%s: %s\n" % (key, value))


def main():
    if not os.path.exists(SRC_INPUT):
        raise FileNotFoundError("Missing source file: %s" % SRC_INPUT)
    if not os.path.exists(SRC_WEIGHTS):
        raise FileNotFoundError("Missing source file: %s" % SRC_WEIGHTS)
    if not os.path.exists(SRC_EXPECTED):
        raise FileNotFoundError("Missing source file: %s" % SRC_EXPECTED)

    inp = np.load(SRC_INPUT)
    w = np.load(SRC_WEIGHTS)
    exp = np.load(SRC_EXPECTED)

    validate_shape("input", inp, (L_IN, C_IN))
    validate_shape("weights", w, (K, C_IN, F_OUT))
    validate_shape("expected", exp, (L_IN, F_OUT))

    inp_i = inp.astype(np.int64)
    w_i = w.astype(np.int64)
    exp_i = exp.astype(np.int64)

    bias_source = SRC_BIAS_INT32
    if os.path.exists(SRC_BIAS_INT32):
        b = np.load(SRC_BIAS_INT32)
        validate_shape("bias", b, (F_OUT,))
        b_i = b.astype(np.int64)
        bias_mode = "int32_bias_from_file"
    else:
        b_i = np.zeros((F_OUT,), dtype=np.int64)
        bias_source = "none"
        bias_mode = "zero_bias_placeholder_for_raw_mac_alignment"

    input_vals = flatten_input(inp_i)
    weight_vals = flatten_weights(w_i)
    bias_vals = flatten_bias(b_i)
    expected_vals = flatten_expected(exp_i)

    write_lines(DST_INPUT_MEM, input_vals)
    write_lines(DST_WEIGHTS_MEM, weight_vals)
    write_lines(DST_BIAS_MEM, bias_vals)
    write_lines(DST_EXPECTED_MEM, expected_vals)

    metadata = {
        "timestamp_utc": datetime.utcnow().isoformat() + "Z",
        "source_input": SRC_INPUT,
        "source_weights": SRC_WEIGHTS,
        "source_expected": SRC_EXPECTED,
        "source_bias": bias_source,
        "dest_input_mem": DST_INPUT_MEM,
        "dest_weights_mem": DST_WEIGHTS_MEM,
        "dest_bias_mem": DST_BIAS_MEM,
        "dest_expected_mem": DST_EXPECTED_MEM,
        "input_shape": tuple(inp.shape),
        "weights_shape": tuple(w.shape),
        "bias_shape": tuple(b_i.shape),
        "expected_shape": tuple(exp.shape),
        "input_dtype": str(inp.dtype),
        "weights_dtype": str(w.dtype),
        "bias_dtype": str(b_i.dtype),
        "expected_dtype": str(exp.dtype),
        "input_count": len(input_vals),
        "weights_count": len(weight_vals),
        "bias_count": len(bias_vals),
        "expected_count": len(expected_vals),
        "input_min": tensor_stats(inp_i)["min"],
        "input_max": tensor_stats(inp_i)["max"],
        "input_sum": tensor_stats(inp_i)["sum"],
        "weights_min": tensor_stats(w_i)["min"],
        "weights_max": tensor_stats(w_i)["max"],
        "weights_sum": tensor_stats(w_i)["sum"],
        "bias_min": tensor_stats(b_i)["min"],
        "bias_max": tensor_stats(b_i)["max"],
        "bias_sum": tensor_stats(b_i)["sum"],
        "expected_min": tensor_stats(exp_i)["min"],
        "expected_max": tensor_stats(exp_i)["max"],
        "expected_sum": tensor_stats(exp_i)["sum"],
        "bias_mode": bias_mode,
        "flatten_input": "for t in range(3000): for c in range(2): write input[t,c]",
        "flatten_weights": "for f in range(16): for k in range(7): for c in range(2): write weights[k,c,f]",
        "flatten_bias": "for f in range(16): write bias[f]",
        "flatten_expected": "for t in range(3000): for f in range(16): write expected[t,f]",
        "format": "decimal signed integer, one value per line, no commas, no brackets",
    }

    write_metadata(metadata)
    print("Export completed.")
    print("Created:")
    print(" - %s" % DST_INPUT_MEM)
    print(" - %s" % DST_WEIGHTS_MEM)
    print(" - %s" % DST_BIAS_MEM)
    print(" - %s" % DST_EXPECTED_MEM)
    print(" - %s" % DST_METADATA)


if __name__ == "__main__":
    main()
