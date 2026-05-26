# Conv1D Milestone 2 Simulation Notes

## Why `run 1000ns` is too short

The Milestone 2 testbench streams 6000 input samples and verifies 48000 outputs.
A default short run like `run 1000ns` stops before completion, so PASS/FAIL summary
is never reached.

Use a long run (e.g., `run 20 ms`) or run until testbench `$finish`.

## About large memory wave warnings

Warnings or heavy waveform loading related to large arrays like `expected_mem`
are generally harmless for correctness. These arrays are testbench data buffers.

For faster GUI performance, avoid adding:
- `expected_mem`
- `input_mem`
- `weight_mem`
- `bias_mem`

## PASS/FAIL criteria

PASS requires both:
- `compared=48000`
- `mismatches=0`

Expected PASS line:
- `PASS: compared=48000 mismatches=0`

Any `FAIL` line or `FIRST_MISMATCH` indicates mismatch/incomplete run.

## About old path warnings

If Vivado shows warnings from old paths but current absolute paths compile and files
open successfully in simulation, those old warnings can be ignored.

Current testbench paths used:
- `D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv1d_input.mem`
- `D:/Users/Lenovo/project_1/muse_cnn_sources/weights/conv1d_w.mem`
- `D:/Users/Lenovo/project_1/muse_cnn_sources/weights/conv1d_b.mem`
- `D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv1d_expected_int32.mem`
