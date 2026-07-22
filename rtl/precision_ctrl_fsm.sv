module precision_ctrl_fsm #(
    parameter ADDR_WIDTH = 16,
    parameter MAC_LANES  = 8
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   start,
    
    // Memory interface control
    output logic [ADDR_WIDTH-1:0]  qkv_addr_o,
    output logic                   mem_ren_o,
    input  logic                   tile_valid_i,
    
    // Predictor & Config interface
    input  logic [7:0]             score_est_i,
    input  logic [MAC_LANES-1:0]   skip_mask_i,
    input  logic [7:0]             sparsity_thresh_reg,
    input  logic [1:0]             accuracy_target_reg,
    
    // MAC array control
    output logic [MAC_LANES-1:0]   mac_en_o,
    output logic [1:0]             precision_sel_o,
    output logic [MAC_LANES-1:0]   power_gate_o,
    
    // Accumulator / WB
    input  logic                   overflow_flag_i,
    output logic                   wb_valid_o,
    
    // Status
    output logic                   busy_o,
    output logic                   tile_done_o
);

    typedef enum logic [2:0] {
        S0_IDLE          = 3'd0,
        S1_LOAD_TILE     = 3'd1,
        S2_PREDICT       = 3'd2,
        S3_SELECT_PREC   = 3'd3,
        S4_COMPUTE       = 3'd4,
        S5_ACCUMULATE    = 3'd5,
        S6_WRITEBACK     = 3'd6
    } state_t;

    state_t state_q, state_d;
    
    // Tile counter (simplified)
    logic [3:0] tile_count_q, tile_count_d;
    logic last_tile;
    assign last_tile = (tile_count_q == 4'd15); // Assume 16 tiles per block

    // Timer for pipeline delays
    logic [3:0] timer_q, timer_d;

    // Registers for outputs
    logic [1:0] precision_sel_q, precision_sel_d;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q         <= S0_IDLE;
            tile_count_q    <= '0;
            timer_q         <= '0;
            precision_sel_q <= 2'b10; // Default FP16
        end else begin
            state_q         <= state_d;
            tile_count_q    <= tile_count_d;
            timer_q         <= timer_d;
            precision_sel_q <= precision_sel_d;
        end
    end

    always_comb begin
        state_d         = state_q;
        tile_count_d    = tile_count_q;
        timer_d         = timer_q;
        precision_sel_d = precision_sel_q;
        
        qkv_addr_o      = {ADDR_WIDTH{1'b0}}; // Simplified address generation
        mem_ren_o       = 1'b0;
        mac_en_o        = '0;
        power_gate_o    = '0;
        wb_valid_o      = 1'b0;
        busy_o          = 1'b1;
        tile_done_o     = 1'b0;

        case (state_q)
            S0_IDLE: begin
                busy_o = 1'b0;
                tile_count_d = '0;
                if (start) begin
                    state_d = S1_LOAD_TILE;
                end
            end

            S1_LOAD_TILE: begin
                mem_ren_o = 1'b1;
                qkv_addr_o = {12'b0, tile_count_q}; 
                if (tile_valid_i) begin
                    state_d = S2_PREDICT;
                    timer_d = 4'd2; // Wait 2 cycles for prediction
                end
            end

            S2_PREDICT: begin
                if (timer_q == 4'd0) begin
                    state_d = S3_SELECT_PREC;
                end else begin
                    timer_d = timer_q - 1'b1;
                end
            end

            S3_SELECT_PREC: begin
                // Select precision based on target and estimated sparsity
                // If skip_mask_i is all 1s, we are power gating, precision doesn't matter as much, 
                // but we can set to INT4 to save power if not skipped.
                // Here we just map accuracy_target_reg directly for simplicity, but could be dynamic.
                if (&skip_mask_i) begin
                    precision_sel_d = 2'b00; // Drop to INT4 if skipped
                end else begin
                    precision_sel_d = accuracy_target_reg;
                end
                
                state_d = S4_COMPUTE;
                timer_d = 4'd4; // 4 cycle MAC pipeline
            end

            S4_COMPUTE: begin
                mac_en_o = ~skip_mask_i;     // Enable only if not skipped
                power_gate_o = skip_mask_i;  // Power gate skipped lanes
                
                if (timer_q == 4'd0) begin
                    state_d = S5_ACCUMULATE;
                    timer_d = 4'd2; // 2 cycles for accumulate
                end else begin
                    timer_d = timer_q - 1'b1;
                end
            end

            S5_ACCUMULATE: begin
                if (timer_q == 4'd0) begin
                    state_d = S6_WRITEBACK;
                end else begin
                    timer_d = timer_q - 1'b1;
                end
            end

            S6_WRITEBACK: begin
                wb_valid_o = 1'b1;
                tile_done_o = 1'b1;
                if (last_tile) begin
                    state_d = S0_IDLE;
                end else begin
                    tile_count_d = tile_count_q + 1'b1;
                    state_d = S1_LOAD_TILE;
                end
            end
            
            default: state_d = S0_IDLE;
        endcase
    end

    assign precision_sel_o = precision_sel_q;

    // --- SystemVerilog Assertions (SVA) ---
    // synthesis translate_off
`ifndef IVERILOG
    property p_valid_precision;
        @(posedge clk) disable iff (!rst_n)
        (precision_sel_o == 2'b00) || (precision_sel_o == 2'b01) || (precision_sel_o == 2'b10);
    endproperty
    assert property (p_valid_precision) else $error("Illegal precision selection detected");

    property p_power_gate_match;
        @(posedge clk) disable iff (!rst_n)
        (state_q == S4_COMPUTE) |-> (power_gate_o == skip_mask_i);
    endproperty
    assert property (p_power_gate_match) else $error("Power gate does not match skip mask in COMPUTE state");
`endif
    // synthesis translate_on

endmodule
