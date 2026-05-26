# Quantization Contract for INT8 Conv1D FPGA Implementation

## 1) Objective and Scope

This document defines the bit-accurate quantization and arithmetic rules for the FPGA implementation of the CNN inference pipeline.

Milestone 2 scope is limited to **Conv1D INT8 MAC verification only**. ReLU, MaxPool, and Dense quantization contracts are out of scope for this milestone.

The goal is to guarantee exact numeric agreement between:

- Python golden reference export
- Verilog RTL (`conv1d_int8.v`)
- Vivado simulation testbench

## 2) Locked Model Parameters

All parameters below must be finalized before RTL implementation is considered complete.

- Input length (`L_in`): **TODO**
- Kernel size (`K`): **TODO**
- Stride (`S`): **TODO**
- Padding mode (`valid` or `same`): **TODO**
- Number of output filters (`F_out`): **TODO**
- Number of input channels (`C_in`): **TODO**
- Output length formula: **TODO**
  - For `valid`: `L_out = floor((L_in - K) / S) + 1`
  - For `same`: exact padding and index formula must be defined

## 3) Tensor Layout and Export Mapping

The exact memory flattening order must be fixed and shared by Python and RTL.

- Framework Conv1D weight tensor layout: **TODO**
- Export weight layout order (example: `[f][k][c]`): **TODO**
- Bias layout order: **TODO**
- Input stream order in `conv1d_input.mem`: **TODO**
- Expected output order in `conv1d_expected.mem`: **TODO**

## 4) Numeric Formats and Ranges

- Input activation: signed INT8, range `[-128, 127]`
- Conv1D weight: signed INT8, range `[-128, 127]`
- Multiply intermediate: signed INT16
- Accumulator: signed INT32
- Bias: signed INT32 (preferred), format finalization **TODO**
- Output activation: signed INT8, range `[-128, 127]`

All values use two's complement representation.

## 5) Conv1D INT8 Arithmetic Equation

For each output position `t` and output filter `f`:

1. Initialize accumulator:
   - `acc = 0` (signed INT32)
2. Multiply and accumulate:
   - `acc += x[t*S + k, c] * w[f, k, c]`
   - where `k = 0..K-1`, `c = 0..C_in-1`
3. Add bias:
   - `acc_b = acc + b[f]`
4. Requantize:
   - `q = REQUANTIZE(acc_b)`
5. Saturate:
   - `y = clamp(q, -128, 127)`

RTL and Python must implement identical signed arithmetic, sign extension, and operation order.

## 6) Requantization and Saturation Rules

Requantization details must be fully locked:

- Requantization method: **TODO**
  - fixed right shift only, or
  - scale multiplier + shift
- Shift amount (`RQ_SHIFT`): **TODO**
- Rounding mode before shift: **TODO**
  - truncation toward zero, or
  - round-to-nearest

Saturation rule is fixed:

- If value > 127, output 127
- If value < -128, output -128
- Else output lower 8-bit signed value

## 7) File Format Specifications

Required exported files for Milestone 2:

- `conv1d_input.mem`
- `conv1d_w.mem`
- `conv1d_b.mem`
- `conv1d_expected.mem`

For each file, define and keep consistent:

- Numeric radix (`hex` or `decimal`): **TODO**
- One value per line or packed format: **TODO**
- Signed encoding rule: **TODO**
- Flattening order: **TODO**

Recommended baseline: one signed value per line in deterministic order.

## 8) RTL/Testbench Compliance Rules

For Milestone 2, RTL and testbench must satisfy:

- `conv1d_int8.v` performs real Conv1D MAC + bias + requantization + saturation
- Testbench reads all `.mem` files and drives valid input stream
- Testbench compares RTL output to Python expected output only when `out_valid == 1`
- Any mismatch must be logged with index and values

Do not apply approximation or tolerance; this is integer-exact verification.

## 9) PASS/FAIL Criteria

Simulation PASS condition:

- Total compared samples match expected sample count
- `mismatch_count == 0`

Simulation FAIL condition:

- Any mismatch (`mismatch_count > 0`), or
- Output sample count mismatch

**Exact match with Python golden output is required.**

## 10) Missing Information Checklist

- [ ] `L_in` (input length)
- [ ] `K` (kernel size)
- [ ] `S` (stride)
- [ ] Padding mode and exact output indexing
- [ ] `F_out` (number of output filters)
- [ ] `C_in` (input channels)
- [ ] Framework weight tensor layout
- [ ] Export weight flattening order
- [ ] Bias datatype and scaling relation
- [ ] Requantization method
- [ ] `RQ_SHIFT` value
- [ ] Rounding mode
- [ ] `.mem` radix and signed encoding
- [ ] Expected output ordering
- [ ] Vector count for first regression set

## 11) Revision History

- Rev 0.1 - Initial contract skeleton for Milestone 2 Conv1D INT8 MAC verification; created with TODO placeholders pending final model export details.
