module err_comp_accumulator #(
    parameter MAC_LANES = 8
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [31:0]            mac_result_i [MAC_LANES],
    input  logic [1:0]             precision_sel_i,
    
    output logic [31:0]            acc_out_o,
    output logic                   overflow_flag_o
);

    // Sums up the results from all MAC lanes and adds an error compensation
    // depending on the precision mode.
    
    logic signed [35:0] sum;
    logic signed [35:0] err_comp;
    logic signed [35:0] final_acc;
    
    always_comb begin
        sum = '0;
        for (int i = 0; i < MAC_LANES; i++) begin
            sum = sum + signed'(mac_result_i[i]);
        end
        
        // Error compensation logic
        case (precision_sel_i)
            2'b00: err_comp = 36'd12; // INT4 quantization error compensation
            2'b01: err_comp = 36'd4;  // INT8 quantization error compensation
            2'b10: err_comp = 36'd0;  // FP16/INT16 no extra comp
            default: err_comp = 36'd0;
        endcase
        
        final_acc = sum + err_comp;
    end
    
    logic [31:0] acc_q;
    logic        ovf_q;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_q <= '0;
            ovf_q <= 1'b0;
        end else begin
            // Saturation logic
            if (final_acc > 36'sh00000007FFFFFFF) begin
                acc_q <= 32'h7FFFFFFF;
                ovf_q <= 1'b1;
            end else if (final_acc < -36'sh000000080000000) begin
                acc_q <= 32'h80000000;
                ovf_q <= 1'b1;
            end else begin
                acc_q <= final_acc[31:0];
                ovf_q <= 1'b0;
            end
        end
    end
    
    assign acc_out_o = acc_q;
    assign overflow_flag_o = ovf_q;

endmodule
