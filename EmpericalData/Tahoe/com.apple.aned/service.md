# Apple Neural Engine Hardware Accelerator Daemon — aned

## Basics

- **Main label:** `system/com.apple.aned`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.aned.plist`
- **Binary:** `/usr/libexec/aned`
- **Domain:** `system`
- **Category:** `ai_hardware_neural_engine_ane`
- **Risk:** `2` (Conditional for AI/CoreML workflows)
- **Verdict:** `RESTORED / KEPT ENABLED FOR NEURAL ENGINE NPU ACCELERATION`

## What It Does

`aned` (Apple Neural Engine Daemon) manages Apple Silicon's NPU hardware acceleration (`AppleNeuralEngine.framework`):

1. **Hardware NPU Acceleration**: Offloads tensor calculations, CoreML model execution, MLX models, and local LLMs to dedicated Apple Neural Engine hardware cores on Apple Silicon M-series chips (M1/M2/M3/M4).
2. **System AI Feature Engine**: Powers Xcode predictive code completion, Live Text image recognition, Whisper local voice transcription, and CoreML frameworks.

## Why It Was Kept Enabled

- Preserves Apple Neural Engine NPU hardware acceleration for developer local AI models, Xcode Predictive IntelliSense, and CoreML inference. Kept enabled per user decision.

## Status

**KEPT ENABLED.**
