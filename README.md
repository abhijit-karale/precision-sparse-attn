# Precision-Scalable Sparse Attention Accelerator

An advanced hardware accelerator designed for highly efficient Large Language Model (LLM) inference on edge devices. This accelerator dynamically adapts to the varying computational demands of attention layers by integrating **sparsity skipping** and **runtime precision scaling** into a single, unified control framework.

## Key Features
* **Unified Control FSM**: A central state machine that manages both precision scaling (FP16/INT8/INT4) and sparsity gating on a per-tile basis in the same clock domain.
* **Early-Exit Sparsity Predictor**: Evaluates attention scores to discard near-zero values, bypassing unnecessary computations.
* **Fracturable MAC Array**: An 8-lane datapath capable of dynamically reconfiguring its logic to process values in different precisions, maximizing spatial utilization.
* **Power-Gated Datapath**: Actively disables inactive lanes (based on the sparsity mask) to minimize dynamic power consumption.
* **Error-Bounded Accumulator**: Features saturation and error-compensation logic to prevent overflow during dynamic transitions between datatypes.

## Directory Structure
```
.
├── rtl/                        # Synthesizable RTL source files
│   ├── err_comp_accumulator.sv # Saturation and accumulation logic
│   ├── fracturable_mac_array.sv# Reconfigurable MAC datapath
│   ├── precision_ctrl_fsm.sv   # Unified FSM for precision & sparsity
│   ├── precision_sparse_attn_top.sv # Top-level integration module
│   ├── softmax_approx.sv       # Error-bounded approximation unit
│   └── sparsity_predictor.sv   # Magnitude estimator and skip mask generator
├── tb/                         # Simulation and verification files
│   └── tb_precision_sparse_attn.sv # Comprehensive self-checking testbench
├── docs/                       # Detailed project documentation
│   ├── PROJECT_INFORMATION.md  # Deep dive into motivation and component design
│   ├── architecture.md         # System architecture and block diagrams
│   └── waveforms.md            # Simulation timing waveforms
└── FINAL_PATENT_SUBMISSION.md  # Prepared patent disclosure document
```

## Simulation & Verification
The design is verified using a robust SystemVerilog testbench (`tb/tb_precision_sparse_attn.sv`) containing an SRAM memory model, constrained randomized testing, and SystemVerilog Assertions (SVA) for FSM lock-up prevention. 

### Running the Simulation
To compile and run the simulation using Icarus Verilog (`iverilog`) and `vvp`:
```bash
cd tb
iverilog -DIVERILOG -g2012 -o sim.vvp -I ../rtl ../rtl/*.sv tb_precision_sparse_attn.sv
vvp sim.vvp
```
*Note: The `-DIVERILOG` flag is required to bypass SystemVerilog `covergroup` and SVA constructs which Icarus Verilog does not natively support.*

## Status
- [x] RTL Implementation Complete
- [x] Self-Checking Testbench Developed
- [x] Simulation Verified (Directed & Randomized Edge Cases Passed)
- [x] Waveforms Generated
- [x] Patent Disclosure Drafted
