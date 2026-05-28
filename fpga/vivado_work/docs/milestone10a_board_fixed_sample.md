# Milestone 10A Board Fixed-Sample Deployment

## Purpose

Prepare a first board-deployable inference wrapper for AV7K325 using fixed-sample mode and full verified CNN chain.

## Architecture

`inference_top_av7k325.v` instantiates:

- Conv1 -> ReLU1 -> Pool1
- Conv2 -> Pool2
- Conv3 -> ReLU3
- GAP
- Dense1 -> ReLU
- Dense2 logits

Top-level ports:

- `sys_clk_p`, `sys_clk_n`
- `key1`
- `led_done`
- `led_class`

## Files Created

- `src/inference_top_av7k325.v`
- `constraints/inference_top_av7k325.xdc`
- `run_milestone10a_synth_impl.tcl`

## Fixed-Sample Load Behavior

- Wrapper includes internal input memory (`6000` samples).
- Input memory is initialized from:
  - `data/conv1d_input.mem`
- Expected reference logits source remains:
  - `data/dense2_expected_int32.mem`

## LED Behavior

- `led_done`: active-low done indicator.
- `led_class`: active-low class indicator based on `logit1 > logit0`.

## Synthesis/Implementation Command

In Vivado Tcl console (with `project_1.xpr` open):

```tcl
source D:/Users/Lenovo/project_1/muse_cnn_sources/run_milestone10a_synth_impl.tcl
```

Generated reports:

- `reports/m10a_synth_util.rpt`
- `reports/m10a_impl_util.rpt`
- `reports/m10a_timing.rpt`
- `reports/m10a_power.rpt`

## Limitations

- Current compute modules still use simulation-style weight/bias loading (`$fopen` with absolute paths).
- This milestone is synthesis-prep and smoke-test oriented, not final production data path.
- Softmax/argmax remains host-side.

## Next Step

- Add UART logits output for board-observable inference result.
