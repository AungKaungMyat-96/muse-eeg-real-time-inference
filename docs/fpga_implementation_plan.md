# FPGA Implementation Plan

## Target Board
- ALINX AV7K325
- Xilinx Kintex-7 FPGA

## Model Chosen
- stroke_eeg_cnn_model_no_bn.keras

## Input Format
- Shape: (3000, 2)
- Quantized test vector: sample_input_int8.txt
- Scale factor: sample_input_scale.txt

## Exported Layers
- Conv1D 1: (7, 2, 16)
- Conv1D 2: (5, 16, 32)
- Conv1D 3: (3, 32, 64)
- Dense 1: (64, 32)
- Dense 2: (32, 2)

## Practical FPGA Scope
Phase 1:
- Validate file-based input format
- Implement Conv1D layer 1 only
- Compare FPGA output with Python reference

Phase 2:
- Add activation and pooling
- Expand to later layers if time allows

## Comparison Method
- Use the same quantized input vector in Python and FPGA
- Compare intermediate outputs and final class