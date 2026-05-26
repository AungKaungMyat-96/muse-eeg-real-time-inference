# FPGA CNN Milestone Status

Target FPGA: `xc7k325tffg900-2` (AV7K325)  
Vivado: `2022.2`

## Verified PASS Milestones

1. Conv1 standalone PASS
2. Conv1 -> ReLU1 -> Pool1 PASS
3. Conv2 standalone PASS
4. Integrated Conv1 -> ReLU1 -> Pool1 -> Conv2 PASS
5. Pool2 standalone PASS
6. Conv3 standalone PASS
7. ReLU3 + GAP PASS
8. Dense1 RAW PASS
9. Dense1 ReLU PASS
10. Dense2 logits PASS
11. Integrated classifier PASS
12. Full end-to-end inference PASS

## Final PASS Line

`PASS: full_inference_compared=2 mismatches=0`

## Verified End-to-End Chain

Input -> Conv1 -> ReLU1 -> Pool1 -> Conv2 -> Pool2 -> Conv3 -> ReLU3 -> GAP -> Dense1 -> ReLU -> Dense2 logits

## Output Policy

- FPGA currently outputs 2 logits.
- Softmax/argmax is host-side by design.

## Completion Estimate

- Full FPGA inference simulation: `100%`
- Board deployment: `60-65%`
- Real-time EEG demo: `55-60%`
- Thesis-ready implementation: `90%`
