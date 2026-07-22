module precision_sparse_attn_top #(
    parameter DATA_WIDTH   = 16,
    parameter MAC_LANES    = 8,
    parameter ADDR_WIDTH   = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   start,

    // Q/K/V memory interface
    output logic [ADDR_WIDTH-1:0]  qkv_addr_o,
    output logic                   mem_ren_o,
    input  logic [DATA_WIDTH-1:0]  qkv_data_i,
    input  logic                   tile_valid_i,

    // config registers
    input  logic [7:0]             sparsity_thresh_reg,
    input  logic [1:0]             accuracy_target_reg,

    // MAC array control (exposed for testing/visibility)
    output logic [MAC_LANES-1:0]   mac_en_o,
    output logic [1:0]             precision_sel_o,
    output logic [MAC_LANES-1:0]   power_gate_o,

    // accumulator / output
    output logic [31:0]            acc_out_o,
    output logic                   overflow_flag_o,

    // writeback
    output logic [ADDR_WIDTH-1:0]  wb_addr_o,
    output logic [DATA_WIDTH-1:0]  wb_data_o,
    output logic                   wb_valid_o,

    // status
    output logic                   busy_o,
    output logic                   tile_done_o
);

    logic [MAC_LANES-1:0] skip_mask_w;
    logic [7:0]           score_est_w;
    logic [1:0]           precision_sel_w;
    logic [MAC_LANES-1:0] mac_en_w;
    logic [MAC_LANES-1:0] power_gate_w;
    logic [31:0]          mac_result_w [MAC_LANES];
    logic [31:0]          acc_out_w;
    logic                 overflow_flag_w;

    // Output assignments for visibility
    assign precision_sel_o = precision_sel_w;
    assign mac_en_o = mac_en_w;
    assign power_gate_o = power_gate_w;
    assign overflow_flag_o = overflow_flag_w;
    assign acc_out_o = acc_out_w;

    // Writeback mapping (simplified)
    assign wb_data_o = acc_out_w[15:0];
    assign wb_addr_o = qkv_addr_o; // just echoing for now

    sparsity_predictor #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAC_LANES(MAC_LANES)
    ) i_sparsity_predictor (
        .clk(clk),
        .rst_n(rst_n),
        .qkv_data_i(qkv_data_i),
        .sparsity_thresh_reg(sparsity_thresh_reg),
        .skip_mask_o(skip_mask_w),
        .score_est_o(score_est_w)
    );

    precision_ctrl_fsm #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .MAC_LANES(MAC_LANES)
    ) i_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .qkv_addr_o(qkv_addr_o),
        .mem_ren_o(mem_ren_o),
        .tile_valid_i(tile_valid_i),
        .score_est_i(score_est_w),
        .skip_mask_i(skip_mask_w),
        .sparsity_thresh_reg(sparsity_thresh_reg),
        .accuracy_target_reg(accuracy_target_reg),
        .mac_en_o(mac_en_w),
        .precision_sel_o(precision_sel_w),
        .power_gate_o(power_gate_w),
        .overflow_flag_i(overflow_flag_w),
        .wb_valid_o(wb_valid_o),
        .busy_o(busy_o),
        .tile_done_o(tile_done_o)
    );

    fracturable_mac_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAC_LANES(MAC_LANES)
    ) i_mac_array (
        .clk(clk),
        .rst_n(rst_n),
        .mac_en_i(mac_en_w),
        .precision_sel_i(precision_sel_w),
        .q_data_i(qkv_data_i),  // simplified operand routing
        .k_data_i(qkv_data_i),
        .mac_result_o(mac_result_w)
    );

    err_comp_accumulator #(
        .MAC_LANES(MAC_LANES)
    ) i_accumulator (
        .clk(clk),
        .rst_n(rst_n),
        .mac_result_i(mac_result_w),
        .precision_sel_i(precision_sel_w),
        .acc_out_o(acc_out_w),
        .overflow_flag_o(overflow_flag_w)
    );

endmodule
