# Next Board Deployment Plan

## Objective

Transition from full behavioral simulation PASS to AV7K325 board deployment with deterministic logits output.

## Next Steps

1. Build synthesizable top-level inference wrapper for full chain.
2. Replace simulation-oriented file loading with BRAM/ROM initialization strategy.
3. Define board input strategy for frame data ingestion.
4. Define board output strategy for 2 logits.
5. Implement UART/host communication path.
6. Keep softmax/argmax on host side for initial deployment.
7. Generate bitstream and run board bring-up tests.
8. Collect utilization/timing/power reports from synthesis and implementation.

## Implementation Focus Areas

- Weight/bias storage migration:
  - from simulation `$fopen` style to synthesis-safe memory init.
- Frame control:
  - start, active stream window, done signaling.
- Host protocol:
  - command framing, payload integrity, logits response format.

## Risks

- INT32 resource usage may increase LUT/DSP/BRAM pressure.
- Current simulation-oriented memory loading is not hardware-ready.
- No-backpressure pipeline may require strict input timing discipline.
- Timing closure risk rises after full-chain top-level synthesis.
- Board IO constraints and interface timing need careful validation.

## Deployment Output Policy

- FPGA outputs 2 logits.
- Host computes softmax/argmax and class label display.
