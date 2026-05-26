import os
from datetime import datetime

import numpy as np


SRC_CONV1_INT32 = r"C:\Users\Lenovo\Documents\muse-eeg-real-time-inference\fpga\test_vectors\conv1_output_int32.npy"

DST_RELU_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\relu1_expected_int32.mem"
DST_POOL_MEM = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\maxpool1_expected_int32.mem"
DST_META = r"D:\Users\Lenovo\project_1\muse_cnn_sources\data\milestone3_export_metadata.txt"

L_IN = 3000
F_OUT = 16
POOL_SIZE = 2
STRIDE = 2
L_POOL = 1500


def ensure_parent(path):
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def validate_input(arr):
    if tuple(arr.shape) != (L_IN, F_OUT):
        raise ValueError(
            "Input shape mismatch. Expected (3000, 16), got %s" % (arr.shape,)
        )
    if arr.dtype.kind not in ("i", "u"):
        raise TypeError(
            "Input dtype must be integer-compatible. Got %s" % arr.dtype
        )


def flatten_t_f(arr):
    out = []
    for t in range(arr.shape[0]):
        for f in range(arr.shape[1]):
            out.append(int(arr[t, f]))
    return out


def write_mem(path, values):
    ensure_parent(path)
    with open(path, "w") as f:
        for v in values:
            f.write("%d\n" % int(v))


def stats(arr):
    arr64 = arr.astype(np.int64, copy=False)
    return int(arr64.min()), int(arr64.max()), int(arr64.sum())


def write_metadata(meta_path, meta):
    ensure_parent(meta_path)
    with open(meta_path, "w") as f:
        for k, v in meta.items():
            f.write("%s: %s\n" % (k, v))


def main():
    if not os.path.exists(SRC_CONV1_INT32):
        raise FileNotFoundError("Missing source file: %s" % SRC_CONV1_INT32)

    conv1 = np.load(SRC_CONV1_INT32)
    validate_input(conv1)

    conv1_i32 = conv1.astype(np.int32, copy=False)

    # ReLU rule: y = max(0, x), INT32 domain
    relu = np.maximum(conv1_i32, 0).astype(np.int32)

    # MaxPool1 rule: pool_size=2, stride=2 over time axis
    pool = np.zeros((L_POOL, F_OUT), dtype=np.int32)
    for t in range(L_POOL):
        t0 = 2 * t
        t1 = t0 + 1
        for f in range(F_OUT):
            a = int(relu[t0, f])
            b = int(relu[t1, f])
            pool[t, f] = a if a >= b else b

    relu_vals = flatten_t_f(relu)
    pool_vals = flatten_t_f(pool)

    write_mem(DST_RELU_MEM, relu_vals)
    write_mem(DST_POOL_MEM, pool_vals)

    relu_min, relu_max, relu_sum = stats(relu)
    pool_min, pool_max, pool_sum = stats(pool)

    meta = {
        "timestamp_utc": datetime.utcnow().isoformat() + "Z",
        "source_conv1_output_int32": SRC_CONV1_INT32,
        "dest_relu_mem": DST_RELU_MEM,
        "dest_maxpool_mem": DST_POOL_MEM,
        "input_shape": tuple(conv1_i32.shape),
        "input_dtype": str(conv1_i32.dtype),
        "relu_shape": tuple(relu.shape),
        "relu_dtype": str(relu.dtype),
        "maxpool_shape": tuple(pool.shape),
        "maxpool_dtype": str(pool.dtype),
        "relu_count": len(relu_vals),
        "maxpool_count": len(pool_vals),
        "relu_min": relu_min,
        "relu_max": relu_max,
        "relu_sum": relu_sum,
        "maxpool_min": pool_min,
        "maxpool_max": pool_max,
        "maxpool_sum": pool_sum,
        "relu_rule": "relu[t,f] = max(0, conv1_output_int32[t,f])",
        "maxpool_rule": "maxpool[t,f] = max(relu[2*t,f], relu[2*t+1,f])",
        "flatten_order": "for t: for f: write value",
        "format": "decimal signed integer, one value per line, no commas, no brackets",
    }
    write_metadata(DST_META, meta)

    print("Milestone 3 export completed.")
    print("Generated:")
    print(" - %s" % DST_RELU_MEM)
    print(" - %s" % DST_POOL_MEM)
    print(" - %s" % DST_META)


if __name__ == "__main__":
    main()
