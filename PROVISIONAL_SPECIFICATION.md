# FORM 2: PROVISIONAL SPECIFICATION
*(See section 10; rule 13)*

**1. TITLE OF THE INVENTION**
Precision-Scalable Sparse Attention Accelerator with Unified FSM-Driven Datapath for Edge-AI LLM Inference

**2. APPLICANT(S)**
(a) **NAME:** Abhijit Karale
(b) **NATIONALITY:** Indian
(c) **ADDRESS:** Ahmedabad, Gujarat, India

**3. PREAMBLE TO THE DESCRIPTION**
The following specification describes the invention.

---

## 4. DESCRIPTION

### 4.1 Field of the Invention
The present invention relates generally to hardware accelerators for artificial neural networks. More specifically, it relates to a precision-scalable and sparsity-aware matrix multiplication architecture optimized for executing Large Language Model (LLM) attention mechanisms on resource-constrained edge computing devices.

### 4.2 Background of the Invention
Large Language Models (LLMs) rely heavily on transformer architectures, where attention layers consume a significant majority of compute cycles and memory bandwidth. In practice, attention matrices are highly sparse, containing numerous near-zero values that do not meaningfully impact the final output. Edge devices possess limited power and area budgets, making traditional full-precision (FP16/FP32) dense matrix multiplication highly inefficient. 

Prior art attempts to solve these inefficiencies using two disparate approaches:
1.  **Sparsity Accelerators:** Attempt to skip zero or near-zero attention weights to save compute cycles.
2.  **Precision-Scalable Accelerators:** Dynamically switch precision levels (e.g., INT4, INT8, FP16) based on target accuracy to conserve power.

A critical limitation in existing architectures is that these two optimization mechanisms are decoupled. They require separate control pathways, separate pipeline stages, and incur high control-path overhead, limiting overall energy efficiency and preventing optimal spatial utilization of the compute elements. There exists a need for a unified hardware architecture that natively integrates both sparsity prediction and precision scaling.

### 4.3 Summary of the Invention
The present invention provides a unified hardware architecture wherein sparsity detection and precision switching are managed dynamically on a per-tile basis within a single clock domain. 

The architecture comprises:
- **A Sparsity Predictor:** A magnitude estimator that evaluates incoming query, key, and value (Q/K/V) data blocks against a programmable threshold. It generates a sparsity skip mask, allowing the system to enact an "early-exit" and bypass unnecessary computations for near-zero values.
- **A Unified Control Finite State Machine (FSM):** A central controller executing a multi-stage pipeline. The FSM simultaneously evaluates the generated skip mask and a host-provided accuracy target to issue instantaneous power-gating signals for inactive compute lanes and precision-select signals for active lanes.
- **A Fracturable Multiply-Accumulate (MAC) Array:** A reconfigurable datapath array (e.g., 8-lane) that dynamically scales its compute logic to operate in multiple precisions (INT4, INT8, FP16). Clock-gating is applied to lanes marked inactive by the skip mask, severely reducing dynamic power consumption.
- **An Error-Compensation Accumulator:** Includes precision-aware saturation logic to prevent arithmetic overflow when the datapath dynamically shifts between lower and higher precision formats.

### 4.4 Brief Description of the Drawings (Placeholders)
*(Note: Formal black-and-white line drawings conforming to Patent Office Rule 15 will be provided with the Complete Specification.)*

- **Figure 1** is a block diagram illustrating the top-level system architecture, showing the data flow between the memory, Sparsity Predictor, Unified Control FSM, and Fracturable MAC Array. *(Ref: 100 - System Top, 102 - Memory, 104 - Sparsity Predictor, 106 - FSM, 108 - MAC Array, 110 - Accumulator)*
- **Figure 2** is a schematic diagram detailing the internal logic of the Fracturable MAC Array, illustrating precision routing multiplexers and power-gating control lines. *(Ref: 200 - Precision Mux, 202 - FP16 Logic, 204 - INT8 Logic, 206 - INT4 Logic)*
- **Figure 3** is a state diagram of the Unified Control FSM outlining the pipeline stages (IDLE, LOAD, PREDICT, SELECT, COMPUTE, ACCUMULATE, WRITEBACK).
- **Figure 4** is a timing diagram illustrating the dynamic sparsity gating and precision switching behavior during operation.

### 4.5 Best Method of Working the Invention
In the preferred embodiment, the hardware accelerator is integrated as a Neural Processing Unit (NPU) IP block within a System-on-Chip (SoC) for an edge device. 

During operation, the host processor configures the accelerator by setting a `sparsity_thresh_reg` (sparsity threshold) and an `accuracy_target_reg` (target precision). The accelerator fetches a tile of Q, K, and V data from the SRAM. The Sparsity Predictor immediately evaluates the magnitude of the data elements against the threshold. If an element's absolute value is below the threshold, the corresponding bit in the skip mask is asserted.

The Unified Control FSM evaluates the skip mask and the target precision. If the skip mask indicates an element is zero, the FSM issues a `power_gate` signal to the corresponding lane in the Fracturable MAC Array, disabling its clock tree and preventing toggle activity. Simultaneously, the FSM issues a `precision_sel` signal to configure the remaining active lanes into the optimal precision (e.g., splitting a 16-bit multiplier into multiple 4-bit multipliers for INT4 execution). The active lanes compute the MAC operation, and the Error-Compensation Accumulator stores the result, applying appropriate saturation before the final Softmax approximation and writeback to SRAM.

*(Claims are omitted as this is a Provisional Specification. Formal claims will be filed with the Complete Specification.)*

---
**Dated this _______ day of _____________, 2026**

**Signature:** __________________________
**Name:** Abhijit Karale 
*(Applicant)*
