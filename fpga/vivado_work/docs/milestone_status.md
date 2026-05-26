# Milestone Status

Current FPGA target: `xc7k325tffg900-2`  
Vivado version: `2022.2`

## Milestone 2 - Conv1 Standalone

- Status: PASS
- Exact PASS line: `PASS: compared=48000 mismatches=0`
- Expected count: Conv1 = `48000`

## Milestone 3 - Conv1 + ReLU1 + Pool1

- Status: PASS
- Exact PASS line: `PASS: relu_compared=48000 relu_mismatches=0 maxpool_compared=24000 maxpool_mismatches=0`
- Expected counts:
  - ReLU1 = `48000`
  - Pool1 = `24000`

## Milestone 4A - Conv2 Standalone

- Status: PASS
- Exact PASS line: `PASS: compared=48000 mismatches=0`
- Expected count: Conv2 = `48000`

## Milestone 4B - Integrated Conv1 -> ReLU1 -> Pool1 -> Conv2

- Status: PASS
- Exact PASS line: `PASS: integrated_conv2_compared=48000 mismatches=0`
- Expected count: integrated Conv2 = `48000`

## Milestone 5A - Pool2 Standalone

- Status: PASS
- Exact PASS line: `PASS: pool2_compared=24000 mismatches=0`
- Expected count: Pool2 = `24000`

## Milestone 5B - Conv3 Standalone

- Status: PASS
- Exact PASS line: `PASS: conv3_compared=48000 mismatches=0`
- Expected count: Conv3 = `48000`

## Milestone 6 - Integrated Conv1 -> ReLU1 -> Pool1 -> Conv2 -> Pool2 -> Conv3

- Status: PASS
- Exact PASS line: `PASS: integrated_conv3_compared=48000 mismatches=0`
- Expected count: integrated Conv3 = `48000`

## Milestone 7A - ReLU3 + GAP Standalone

- Status: PASS
- Exact PASS line: `PASS: relu3_compared=48000 relu3_mismatches=0 gap_compared=64 gap_mismatches=0`
- Expected counts:
  - ReLU3 = `48000`
  - GAP = `64`

## Milestone 7B - Dense1 RAW Standalone (pre-ReLU)

- Status: PASS
- Exact PASS line: `PASS: dense1_compared=32 mismatches=0`
- Expected count: Dense1 raw = `32`

## Milestone 7C - Dense1 ReLU Standalone

- Status: PASS
- Exact PASS line: `PASS: dense1_relu_compared=32 mismatches=0`
- Expected count: Dense1 ReLU = `32`

## Milestone 7D - Dense2 Logits Standalone

- Status: PASS
- Exact PASS line: `PASS: dense2_compared=2 mismatches=0`
- Expected count: Dense2 logits = `2`

## Milestone 8A - Integrated Classifier (GAP -> Dense1 -> ReLU -> Dense2)

- Status: PASS
- Exact PASS line: `PASS: classifier_compared=2 mismatches=0`
- Expected count: classifier logits = `2`

## Milestone 9 - Full End-to-End FPGA Inference

- Status: PASS
- Exact PASS line: `PASS: full_inference_compared=2 mismatches=0`
- Final simulation finish time: `95602955 ns`
- Verified chain:
  - Input -> Conv1 -> ReLU1 -> Pool1 -> Conv2 -> Pool2 -> Conv3 -> ReLU3 -> GAP -> Dense1 -> ReLU -> Dense2 logits

## Deployment and Thesis Progress Estimate

- Full FPGA inference simulation: `100%`
- Board deployment: `60-65%`
- Real-time EEG demo: `55-60%`
- Thesis-ready implementation: `90%`

## Inference Output Note

- FPGA currently outputs 2 raw logits.
- Softmax/argmax decision remains host-side.
