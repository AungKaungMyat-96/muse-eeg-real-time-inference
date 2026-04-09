# Real-Time Muse EEG Inference Pipeline Notes

## System Overview
The live EEG inference pipeline uses Muse 2 for EEG acquisition and a CNN model for classification.

## Pipeline
Muse 2 EEG Headband
-> Bluetooth
-> muselsl stream
-> LSL inlet in Python
-> Muse adapter
-> Channel selection (AF7, AF8)
-> Resampling to 100 Hz
-> Sliding window buffer (30 seconds)
-> Normalization
-> CNN model inference
-> Prediction output
-> CSV logging

## Model Input Format
- Input shape: (3000, 2)
- Sampling rate: 100 Hz
- Window length: 30 seconds
- Channels used: AF7, AF8

## Real-Time Inference Behavior
- Muse streaming rate: approximately 256 Hz
- Prediction interval: every 5 seconds
- Buffer window: latest 30 seconds of EEG

## Result Summary
- Live Muse streaming worked successfully
- Real-time inference worked successfully
- Predictions were stable and highly confident
- CSV logs and plots were successfully generated