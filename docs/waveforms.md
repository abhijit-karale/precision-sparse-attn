# Simulation Timing Waveforms

These waveforms represent the actual behavior of the `precision_ctrl_fsm.sv` derived directly from the execution of the SystemVerilog testbench (`tb_precision_sparse_attn.sv`). 

## 1. Unified Control Pipeline
The Control FSM follows a strict 7-state pipeline cycle. The predictor evaluates the tile, and the FSM orchestrates the appropriate dynamic adjustments before data enters the compute stage.

```mermaid
timing
    title FSM Core Pipeline
    
    clock clk with period 10
    signal "start"            as start
    signal "tile_done_o"      as done
    signal "FSM State"        as state
    signal "precision_sel_o"  as precision
    
    @0  start:0, done:0, state:"S0_IDLE", precision:"INT8"
    @10 start:1
    @20 start:0, state:"S1_LOAD"
    @30 state:"S2_PREDICT"
    @40 state:"S3_SELECT"
    @50 state:"S4_COMPUTE", precision:"FP16"
    @70 state:"S5_ACCUM"
    @80 state:"S6_WB"
    @90 state:"S0_IDLE", done:1
```

## 2. Dynamic Sparsity Gating & Precision Switch
The following scenario perfectly illustrates the synergy between the two mechanisms. Initially, the system targets INT4 precision. The sparsity predictor identifies a near-zero attention score (`skip_mask_i[0]` asserts), and the FSM immediately fires `power_gate_o[0]` to shut down Lane 0. 

Later, the host software requests a higher accuracy target (FP16). The FSM properly drains the existing pipeline and executes the precision switch in the subsequent cycle.

```mermaid
timing
    title Sparsity Gating combined with Precision Switching
    
    clock clk with period 10
    signal "accuracy_target"  as target
    signal "precision_sel_o"  as psel
    signal "skip_mask_i[0]"   as skip0
    signal "power_gate_o[0]"  as pg0
    
    @0  target:"INT4", psel:"INT4", skip0:0, pg0:0
    @10 skip0:1
    @20 pg0:1
    @30 skip0:0
    @40 pg0:0
    @50 target:"FP16"
    @60 psel:"INT4"
    @70 psel:"FP16", skip0:0, pg0:0
```
