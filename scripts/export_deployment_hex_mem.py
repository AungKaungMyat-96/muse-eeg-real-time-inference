#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path


SRC_ROOT = Path("D:/Users/Lenovo/project_1/muse_cnn_sources")
DATA_DIR = SRC_ROOT / "data"
WEIGHTS_DIR = SRC_ROOT / "weights"
DATA_HEX_DIR = DATA_DIR / "hex"
WEIGHTS_HEX_DIR = WEIGHTS_DIR / "hex"


SPECS = [
    (DATA_DIR / "conv1d_input.mem", DATA_HEX_DIR / "conv1d_input_i8.hex", 8),
    (DATA_DIR / "gap_expected_int32.mem", DATA_HEX_DIR / "gap_expected_i32.hex", 32),
    (WEIGHTS_DIR / "conv1d_w.mem", WEIGHTS_HEX_DIR / "conv1d_w_i8.hex", 8),
    (WEIGHTS_DIR / "conv1d_b.mem", WEIGHTS_HEX_DIR / "conv1d_b_i32.hex", 32),
    (WEIGHTS_DIR / "conv2_w.mem", WEIGHTS_HEX_DIR / "conv2_w_i8.hex", 8),
    (WEIGHTS_DIR / "conv2_b.mem", WEIGHTS_HEX_DIR / "conv2_b_i32.hex", 32),
    (WEIGHTS_DIR / "conv3_w.mem", WEIGHTS_HEX_DIR / "conv3_w_i8.hex", 8),
    (WEIGHTS_DIR / "conv3_b.mem", WEIGHTS_HEX_DIR / "conv3_b_i32.hex", 32),
    (WEIGHTS_DIR / "dense1_w.mem", WEIGHTS_HEX_DIR / "dense1_w_i8.hex", 8),
    (WEIGHTS_DIR / "dense1_b.mem", WEIGHTS_HEX_DIR / "dense1_b_i32.hex", 32),
    (WEIGHTS_DIR / "dense2_w.mem", WEIGHTS_HEX_DIR / "dense2_w_i8.hex", 8),
    (WEIGHTS_DIR / "dense2_b.mem", WEIGHTS_HEX_DIR / "dense2_b_i32.hex", 32),
]


def read_decimal_values(path: Path) -> list[int]:
    values: list[int] = []
    with path.open("r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            values.append(int(line, 10))
    return values


def encode_twos_complement(value: int, width: int) -> int:
    min_v = -(1 << (width - 1))
    max_v = (1 << (width - 1)) - 1
    if value < min_v or value > max_v:
        raise ValueError(f"value {value} out of range for int{width}")
    return value & ((1 << width) - 1)


def decode_twos_complement(value: int, width: int) -> int:
    sign_bit = 1 << (width - 1)
    return value - (1 << width) if (value & sign_bit) else value


def write_hex_values(path: Path, values: list[int], width: int) -> None:
    digits = width // 4
    with path.open("w", encoding="ascii", newline="\n") as f:
        for v in values:
            enc = encode_twos_complement(v, width)
            f.write(f"{enc:0{digits}x}\n")


def read_hex_values(path: Path, width: int) -> list[int]:
    decoded: list[int] = []
    with path.open("r", encoding="ascii") as f:
        for raw in f:
            line = raw.strip()
            if not line:
                continue
            u = int(line, 16)
            decoded.append(decode_twos_complement(u, width))
    return decoded


def verify_roundtrip(src: Path, out_hex: Path, width: int) -> tuple[bool, str]:
    src_vals = read_decimal_values(src)
    hex_vals = read_hex_values(out_hex, width)

    if len(src_vals) != len(hex_vals):
        return False, (
            f"FAIL {src.name}: length mismatch src={len(src_vals)} hex={len(hex_vals)}"
        )

    for idx, (a, b) in enumerate(zip(src_vals, hex_vals)):
        if a != b:
            return False, (
                f"FAIL {src.name}: idx={idx} src={a} decoded={b} from={out_hex.name}"
            )

    return True, f"PASS {src.name} -> {out_hex.name} ({len(src_vals)} values, int{width})"


def main() -> int:
    DATA_HEX_DIR.mkdir(parents=True, exist_ok=True)
    WEIGHTS_HEX_DIR.mkdir(parents=True, exist_ok=True)

    for src, out_hex, width in SPECS:
        if not src.exists():
            raise FileNotFoundError(f"Missing source file: {src}")
        vals = read_decimal_values(src)
        write_hex_values(out_hex, vals, width)

    all_ok = True
    for src, out_hex, width in SPECS:
        ok, msg = verify_roundtrip(src, out_hex, width)
        print(msg)
        if not ok:
            all_ok = False
            break

    if not all_ok:
        return 1

    print("PASS deployment HEX export roundtrip verification")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
