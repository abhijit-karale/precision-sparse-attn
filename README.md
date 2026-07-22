# Precision-Scalable Sparse Attention Accelerator 

![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen?style=for-the-badge) 
![Language](https://img.shields.io/badge/SystemVerilog-IEEE%201800--2012-blue?style=for-the-badge)
![Verification](https://img.shields.io/badge/Verification-SVA%20%7C%20Covergroups-purple?style=for-the-badge)
![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Tape--out%20Ready-success?style=for-the-badge)

An **industry-grade hardware accelerator IP** optimized for highly efficient Large Language Model (LLM) inference on power-constrained edge devices (NPUs). This architecture tackles the primary bottlenecks of transformer attention layers by natively integrating **Sparsity Gating** and **Dynamic Precision Scaling (FP16/INT8/INT4)** within a unified control domain, yielding massive improvements in Power, Performance, and Area (PPA).

## 🚀 Key Architectural Innovations

### 1. Unified Control FSM (Zero-Cycle Overhead)
Unlike legacy architectures that decouple sparsity checking and precision quantization into isolated pipeline stages, this IP utilizes a **Unified Control Finite State Machine**. The FSM simultaneously evaluates incoming sparsity masks and host-driven accuracy targets in a single clock domain, dictating lane-level power states without stalling the compute pipeline.

### 2. Early-Exit Sparsity Predictor
An inline magnitude estimator intercepts Q/K/V memory streams. If the operand falls below a programmable threshold, the predictor generates a `skip_mask`. This deterministic "early-exit" prevents useless data from ever reaching the multipliers.

### 3. Fracturable MAC Array (Maximized Spatial Utilization)
At the heart of the datapath lies an 8-lane **Fracturable Multiply-Accumulate (MAC) Array**. Based on the `precision_sel` signal from the FSM, the arithmetic logic instantly reconfigures to compute in high-fidelity FP16 or fractures into highly parallel INT8/INT4 operations to maximize throughput and data reuse.

### 4. Hardware Outlier-Aware Router (LLM.int8)
Modern LLMs can run mostly in INT4/INT8, but specific "outlier" tokens must be computed in FP16 to preserve accuracy. This IP block features an `outlier_router` that intercepts operands on the fly. If an outlier threshold is breached, it instantaneously routes the computation to the FP16 MAC lane while keeping the rest of the tile in low-power modes.

### 5. Dynamic Sparsity Power-Gating
Lanes flagged by the `skip_mask` are actively power-gated/clock-gated by the FSM. This halts internal toggle activity across the multipliers and adders, reducing dynamic power consumption to near-zero for sparse blocks.

### 6. Error-Bounded Accumulation
To maintain structural integrity during mid-tile transitions between datatypes (e.g., jumping from INT4 to FP16), the `err_comp_accumulator` handles precision-aware saturation and error-compensation before the final Softmax approximation.

---

## 📂 Repository Structure
```
.
├── rtl/                        # Synthesizable SystemVerilog Source Files
│   ├── err_comp_accumulator.sv # Saturation and accumulation logic
│   ├── fracturable_mac_array.sv# Reconfigurable MAC datapath
│   ├── outlier_router.sv       # Hardware LLM.int8() outlier detector
│   ├── precision_ctrl_fsm.sv   # Unified FSM for precision & sparsity
│   ├── precision_sparse_attn_top.sv # Top-level integration module
│   ├── softmax_approx.sv       # Error-bounded approximation unit
│   └── sparsity_predictor.sv   # Magnitude estimator and skip mask generator
├── tb/                         # UVM-inspired self-checking testbench
│   └── tb_precision_sparse_attn.sv 
├── docs/                       # Technical Whitepapers & Visualizations
│   ├── PROJECT_INFORMATION.md  # Deep dive into PPA and Edge-AI context
│   ├── architecture.md         # High-Fidelity System Architecture Diagrams
│   ├── PORTFOLIO_PITCH.md      # Summary of skills and tape-out readiness
│   └── waveforms.md            # Simulation timing waveforms
├── 3d_visualization.html       # Interactive WebGL model of the MAC array
└── FINAL_PATENT_SUBMISSION.md  # Prepared patent disclosure document
```

---

## 🔬 Simulation & Verification Strategy

The design has been thoroughly vetted using a robust **SystemVerilog Testbench** designed to stress-test pipeline boundaries and state transitions.

* **SRAM Memory Modeling**: Cycle-accurate reads to mimic edge SoC memory fabric.
* **Constrained Randomization**: Randomized sparsity thresholds and precision targets to catch unhandled FSM edge-cases.
* **SystemVerilog Assertions (SVA)**: In-line properties aggressively checking for illegal precision states and FSM lock-ups.
* **Functional Coverage**: Comprehensive cross-coverage bins defined for sparsity-levels vs. target-precisions (requires VCS/Questa to compile).

### Running the Regression (Icarus Verilog)
To run the automated test suite locally:
```bash
cd tb
iverilog -DIVERILOG -g2012 -o sim.vvp -I ../rtl ../rtl/*.sv tb_precision_sparse_attn.sv
vvp sim.vvp
```
*(Note: SystemVerilog Assertions and Covergroups are guarded by `` `ifndef IVERILOG `` for open-source compatibility.)*

---
**Author**: Abhijit Karale  
**Focus Area**: ASIC Design, Digital Architecture, Low-Power Inference Accelerators  
**Contact / Portfolio**: Check `docs/PORTFOLIO_PITCH.md` for a comprehensive overview of my technical capabilities.
