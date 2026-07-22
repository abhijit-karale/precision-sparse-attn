`timescale 1ns/1ps

module tb_precision_sparse_attn;

    parameter DATA_WIDTH   = 16;
    parameter MAC_LANES    = 8;
    parameter ADDR_WIDTH   = 16;

    logic                   clk;
    logic                   rst_n;
    logic                   start;

    // Q/K/V memory interface
    logic [ADDR_WIDTH-1:0]  qkv_addr_o;
    logic                   mem_ren_o;
    logic [DATA_WIDTH-1:0]  qkv_data_i;
    logic                   tile_valid_i;

    // config registers
    logic [7:0]             sparsity_thresh_reg;
    logic [1:0]             accuracy_target_reg;

    // MAC array control (exposed for testing/visibility)
    logic [MAC_LANES-1:0]   mac_en_o;
    logic [1:0]             precision_sel_o;
    logic [MAC_LANES-1:0]   power_gate_o;

    // accumulator / output
    logic [31:0]            acc_out_o;
    logic                   overflow_flag_o;

    // writeback
    logic [ADDR_WIDTH-1:0]  wb_addr_o;
    logic [DATA_WIDTH-1:0]  wb_data_o;
    logic                   wb_valid_o;

    // status
    logic                   busy_o;
    logic                   tile_done_o;

    // DUT Instantiation
    precision_sparse_attn_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAC_LANES(MAC_LANES),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .*
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Memory Model (Simple ROM/RAM for QKV)
    logic [DATA_WIDTH-1:0] qkv_mem [0:255];
    
    always_ff @(posedge clk) begin
        if (mem_ren_o) begin
            // Add a simple 1 cycle read delay to mimic SRAM
            qkv_data_i <= qkv_mem[qkv_addr_o[7:0]];
            tile_valid_i <= 1'b1;
        end else begin
            tile_valid_i <= 1'b0;
        end
    end

    // Coverage definition
`ifndef IVERILOG
    covergroup cg_fsm @(posedge clk);
        cp_precision: coverpoint precision_sel_o {
            bins int4 = {2'b00};
            bins int8 = {2'b01};
            bins fp16 = {2'b10};
        }
        cp_sparsity: coverpoint sparsity_thresh_reg {
            bins zero = {0};
            bins low  = {[1:63]};
            bins med  = {[64:127]};
            bins high = {[128:255]};
        }
        cross cp_precision, cp_sparsity;
    endgroup
    
    cg_fsm cg_inst;
`endif

    // Task to apply reset
    task reset_dut();
        rst_n = 0;
        start = 0;
        sparsity_thresh_reg = 0;
        accuracy_target_reg = 0;
        #20;
        rst_n = 1;
        #10;
    endtask

    // Simple test sequences
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_precision_sparse_attn);

`ifndef IVERILOG
        cg_inst = new();
`endif

        // 1. Reset
        reset_dut();

        // Initialize Memory
        for (int i=0; i<256; i++) begin
            qkv_mem[i] = i * 10; // some values
        end

        // Test 1: Basic dense FP16
        $display("[%0t] --- Test 1: Basic Dense FP16 ---", $time);
        sparsity_thresh_reg = 8'h00; // 0 threshold, dense
        accuracy_target_reg = 2'b10; // FP16
        start = 1;
        #10 start = 0;
        wait(tile_done_o);
        $display("[%0t] Test 1 Completed.", $time);
        #20;

        // Test 2: Basic sparse INT4
        $display("[%0t] --- Test 2: Basic Sparse INT4 ---", $time);
        sparsity_thresh_reg = 8'h40;
        accuracy_target_reg = 2'b00; // INT4
        start = 1;
        #10 start = 0;
        wait(tile_done_o);
        $display("[%0t] Test 2 Completed.", $time);
        #20;
        
        // Test 3: Dynamic Precision Switch (simulated by changing accuracy target mid-run)
        $display("[%0t] --- Test 3: Dynamic Precision Switch ---", $time);
        sparsity_thresh_reg = 8'h10;
        accuracy_target_reg = 2'b01; // INT8
        start = 1;
        #10 start = 0;
        // switch target mid-run
        #50 accuracy_target_reg = 2'b10; // FP16
        wait(tile_done_o);
        $display("[%0t] Test 3 Completed.", $time);
        #20;

        // Test 4: Accumulator overflow
        $display("[%0t] --- Test 4: Accumulator Overflow (Large values) ---", $time);
        // Load very large values to trigger overflow handling
        for (int i=0; i<256; i++) begin
            qkv_mem[i] = 16'h7FFF; // Large positive values
        end
        sparsity_thresh_reg = 8'h00;
        accuracy_target_reg = 2'b10; // FP16
        start = 1;
        #10 start = 0;
        wait(tile_done_o);
        $display("[%0t] Test 4 Completed.", $time);
        #20;

        // Test 5: Constrained Randomized testing
        $display("[%0t] --- Test 5: Randomized testing ---", $time);
        for (int i=0; i<10; i++) begin
            sparsity_thresh_reg = $urandom_range(0, 255);
            accuracy_target_reg = $urandom_range(0, 2);
            
            // Randomize memory contents
            for (int j=0; j<256; j++) begin
                qkv_mem[j] = $urandom_range(0, 65535); 
            end

            start = 1;
            #10 start = 0;
            wait(tile_done_o);
            #20;
        end

        $display("All tests completed successfully.");
        $finish;
    end

    // Add SVA properties directly here
`ifndef IVERILOG
    property p_valid_precision;
        @(posedge clk) disable iff (!rst_n)
        (precision_sel_o != 2'b11);
    endproperty
    assert property (p_valid_precision) else $error("Illegal precision selected!");

    property p_no_hang;
        @(posedge clk) disable iff (!rst_n)
        start |=> ##[1:1000] tile_done_o;
    endproperty
    assert property (p_no_hang) else $error("FSM hung and never asserted tile_done_o!");
`endif

endmodule
