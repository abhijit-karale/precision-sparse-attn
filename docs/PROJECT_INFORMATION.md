# Project Information: Precision-Scalable Sparse Attention Accelerator

## 1. Motivation
Modern Large Language Model (LLM) inference, especially transformer-based architectures like GPT and Llama, allocates **60-80% of its compute cycles to attention layers**. These attention matrices are often highly sparse, meaning many attention scores are near-zero and contribute negligibly to the final output. Meanwhile, deploying these models on edge devices (smartphones, IoT, embedded AI chips) is severely constrained by strict power and area budgets, making full FP16/FP32 precision across all operations unfeasible.

Current industry solutions address these two problems separately:
1.  **Sparsity Accelerators**: Skip zero or near-zero attention weights to save cycles.
2.  **Precision-Scalable Accelerators**: Switch between precisions (INT4/INT8/FP16) based on required accuracy to save power.

This project introduces a **unified hardware architecture** where sparsity detection and precision switching happen dynamically, per-tile, within the **same clock domain**.

## 2. Core Components

### 2.1 Sparsity Predictor (`sparsity_predictor.sv`)
Acts as a magnitude estimator. It evaluates incoming Q/K/V data against a programmable `sparsity_thresh_reg`. If the estimated score falls below this threshold, it generates a `skip_mask` indicating which elements can be safely bypassed. This allows the system to execute an "early-exit" and avoid dispatching useless work to the MAC array.

### 2.2 Outlier-Aware Mixed-Precision Router (`outlier_router.sv`)
Inspired by the breakthroughs in the `LLM.int8()` quantization paper, this module intercepts the data stream before it reaches the MAC array. It detects "outlier" tokens—values whose magnitude exceeds a programmable threshold. While the FSM might dictate a baseline precision of INT4 or INT8 for power savings, the `outlier_router` will dynamically override this for outlier values, routing them exclusively to the high-fidelity FP16 lanes. This hardware-level outlier detection preserves model accuracy without relying on slow software-level branching.

### 2.3 Unified Control FSM (`precision_ctrl_fsm.sv`)
The brain of the accelerator. It operates a 7-stage pipeline (IDLE → LOAD → PREDICT → SELECT → COMPUTE → ACCUMULATE → WRITEBACK). It simultaneously ingests the `skip_mask` from the predictor and the `accuracy_target_reg` from the host. It ensures that precision switches only occur cleanly between tiles (pipeline draining) and instantly issues `power_gate` signals to disable inactive lanes based on the mask.

### 2.3 Fracturable MAC Array (`fracturable_mac_array.sv`)
An 8-lane compute datapath designed for ultimate flexibility. Instead of using isolated fixed-precision MAC units, this array fracturates its logic to compute dynamically in INT4, INT8, or FP16 modes. Furthermore, any lane flagged by the `power_gate` signal is clock-gated/disabled, halting toggle activity and drastically lowering dynamic power consumption.

### 2.4 Error-Compensation Accumulator (`err_comp_accumulator.sv`)
Transitions between lower precisions (INT4/INT8) and higher precisions (FP16) can lead to accumulator overflow or quantization errors. This module includes saturation logic mapped strictly to the current precision mode, ensuring data integrity is maintained as the output is accumulated and funneled toward the final Softmax approximation block.

## 3. Edge-AI Context
By collapsing the decision-making process for both sparsity and precision into a unified state machine, this accelerator minimizes control-path overhead. The resulting hardware profile presents an extremely low area and power footprint, making it an ideal neural processing unit (NPU) IP block for next-generation edge devices.
