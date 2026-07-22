# Portfolio Profile: Precision-Scalable Sparse Attention Accelerator

**Role Target:** Senior RTL Design Engineer / ASIC Verification Engineer / ML Hardware Architect
**Applicant:** Abhijit Karale

---

## 🎯 Executive Pitch
I designed and verified an **industry-grade Neural Processing Unit (NPU) IP block** specifically optimized to accelerate transformer attention mechanisms on edge-AI chips. By fusing **Sparsity Gating** and **Dynamic Precision Scaling (FP16/INT8/INT4)** into a unified Finite State Machine (FSM), this architecture solves the critical Power, Performance, and Area (PPA) bottlenecks of running LLMs (like Llama or GPT) on battery-constrained devices.

This project demonstrates my ability to take a complex architectural concept, translate it into synthesizable SystemVerilog RTL, and prove its functional correctness through rigorous, UVM-inspired verification strategies.

---

## 🛠 Core Competencies Demonstrated

### 1. Advanced RTL Architecture (SystemVerilog)
- **Unified Control Plane**: Engineered a highly efficient 7-state FSM that manages zero-overhead precision switching and power gating in a single clock domain, avoiding the pipeline bubbles seen in legacy decoupled architectures.
- **Fracturable Compute**: Designed a dynamic MAC array that fractures wide FP16 multipliers into parallel INT8/INT4 ALUs on-the-fly, maximizing spatial utilization.
- **Computer Arithmetic**: Implemented an error-compensated accumulator with precision-aware saturation logic and an approximated hardware Softmax function.

### 2. Low-Power Design (PPA Optimization)
- **Early-Exit Sparsity Prediction**: Designed an inline magnitude estimator to aggressively filter near-zero attention scores.
- **Clock & Power Gating**: Embedded fine-grained lane-level clock-gating controlled dynamically by the FSM's `skip_mask`, reducing dynamic toggle power to absolute minimums during sparse operations.

### 3. Verification & DV Readiness
- **Constrained Randomization**: Developed a self-checking testbench injecting randomized memory states, dynamic precision shift targets, and varying sparsity thresholds.
- **SystemVerilog Assertions (SVA)**: Integrated robust inline assertions to mathematically prove FSM liveness (no-hang guarantees) and detect illegal datapath states.
- **Coverage-Driven Closure**: Modeled functional `covergroups` mapping precision states against sparsity thresholds to ensure 100% architectural corner-case coverage.

---

## 📈 Why This Matters for an MNC (Tape-out Readiness)
Tier-1 silicon vendors are in a race to put LLMs on edge devices (laptops, phones, IoT). Traditional FP32/FP16 accelerators burn too much power, and static INT8 quantizers lose too much accuracy on long-tail attention distributions. 

This IP block proves that I understand how to architect **Adaptive Silicon**. By bringing the decision logic (Sparsity Predictor) right next to the control logic (Unified FSM), I've designed an IP block that delivers maximum TOPS/W (Tera-Operations Per Second per Watt) without sacrificing model accuracy. 

**I am ready to bring this level of architectural thinking, RTL coding rigor, and verification discipline to your silicon engineering team.**
