# Milestone 10E Classifier-Only Board Demo

## Purpose

Provide a smaller first board-deployment evidence step using classifier-only hardware.
This milestone does not replace full inference verification.

## Accuracy Contract

- Golden full inference remains Milestone 9 (`PASS: full_inference_compared=2 mismatches=0`).
- Decimal golden `.mem` files remain unchanged.
- Weights and quantization are unchanged.
- Deployment HEX files are generated from decimal sources with roundtrip verification.

## Design Scope

Top module: `src/classifier_top_av7k325.v`

Pipeline:

- Fixed GAP vector preload (`data/hex/gap_expected_i32.hex`)
- Dense1 (`dense1_int32.v`)
- ReLU (`relu_int32.v`)
- Dense2 logits (`dense2_int32.v`)

Outputs:

- `led_done` active-low done indicator
- `led_class` active-low class indicator (`logit1 > logit0`)

## Build Commands

Synthesis-only:

```tcl
source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone10e_classifier_synth_impl.tcl
```

Full implementation + bitstream:

```tcl
set M10E_MODE full
source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone10e_classifier_synth_impl.tcl
```

## Reports

- `reports/m10e_classifier_synth_util.rpt`
- `reports/m10e_classifier_timing_precheck.rpt`
- `reports/m10e_classifier_impl_util.rpt` (full mode)
- `reports/m10e_classifier_timing_impl.rpt` (full mode)
- `reports/m10e_classifier_power.rpt` (full mode)

## Expected Behavior

- Release `key1` reset, design feeds 64 GAP values to classifier.
- `led_done` asserts active-low after Dense2 class 1 logit is captured.
- `led_class` indicates class by `logit1 > logit0` (active-low LED).

## Limitations

- This is classifier-only board evidence, not full-chain deployment.
- Input is fixed preloaded feature vector, not live EEG.
- Softmax/argmax remains host-side.

## Next Step

- Add UART logits output and then stage larger feature-extractor deployment.
