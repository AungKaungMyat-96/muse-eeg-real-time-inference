# Full Inference Verification

## Purpose

Document final end-to-end behavioral verification of the FPGA CNN inference chain.

## Verified Architecture

Input -> Conv1 -> ReLU1 -> Pool1 -> Conv2 -> Pool2 -> Conv3 -> ReLU3 -> GAP -> Dense1 -> ReLU -> Dense2 logits

## Verification Inputs/Outputs

- Input stimulus: `D:/Users/Lenovo/project_1/muse_cnn_sources/data/conv1d_input.mem`
- Final expected logits: `D:/Users/Lenovo/project_1/muse_cnn_sources/data/dense2_expected_int32.mem`

## Core Artifacts

- Testbench: `D:/Users/Lenovo/project_1/muse_cnn_sources/tb/full_inference_tb.v`
- Runner: `D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone9_sim.tcl`

## PASS Contract

- Input count: `6000`
- Final output logits count: `2`
- Exact PASS line:
  - `PASS: full_inference_compared=2 mismatches=0`

## Runtime

- Final simulation finish time: `95602955 ns`

## Verification Statement

Verilog FPGA inference output matches Python golden reference exactly for full end-to-end inference.
