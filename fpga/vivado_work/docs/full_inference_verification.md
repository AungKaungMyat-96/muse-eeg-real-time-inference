# Full Inference Verification

## Purpose

This document records full end-to-end FPGA inference verification for the complete CNN chain in behavioral simulation.

## Verified Architecture

- Input
- Conv1
- ReLU1
- Pool1
- Conv2
- Pool2
- Conv3
- ReLU3
- GAP
- Dense1
- ReLU
- Dense2 logits (2 classes)

## Input and Output Files

- Input stimulus: `D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv1d_input.mem`
- Final expected logits: `D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense2_expected_int32.mem`

## Verification Artifacts

- Testbench: `D:/Users/Lenovo/project_1/muse_cnn_sources/tb/full_inference_tb.v`
- Runner: `D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone9_sim.tcl`

## PASS Criteria

- Input count: `6000`
- Output logits compare count: `2`
- Exact PASS line:
  - `PASS: full_inference_compared=2 mismatches=0`

## Runtime

- Full simulation finish timestamp: `95602955 ns`

## Verification Statement

Verilog FPGA inference output matches Python golden reference exactly for the full end-to-end chain.
