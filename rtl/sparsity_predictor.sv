module sparsity_predictor #(
    parameter DATA_WIDTH = 16,
    parameter MAC_LANES  = 8
)(
    input  logic                   clk,
    input  logic                   rst_n,
    
    input  logic [DATA_WIDTH-1:0]  qkv_data_i,
    input  logic [7:0]             sparsity_thresh_reg,
    
    output logic [MAC_LANES-1:0]   skip_mask_o,
    output logic [7:0]             score_est_o
);

    // We estimate the magnitude of the attention score by looking at the Q and K values.
    // Assuming qkv_data_i holds a packed Q and K value, or just a single value we use for estimation.
    // Let's use the absolute value of the lower and upper bytes as an approximation.
    logic [7:0] abs_lower;
    logic [7:0] abs_upper;

    assign abs_lower = qkv_data_i[7] ? (~qkv_data_i[7:0] + 1'b1) : qkv_data_i[7:0];
    assign abs_upper = qkv_data_i[15] ? (~qkv_data_i[15:8] + 1'b1) : qkv_data_i[15:8];

    // Simple estimation: Sum of absolute values
    logic [8:0] sum_abs;
    assign sum_abs = abs_lower + abs_upper;

    // Output the bounded estimation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            score_est_o <= 8'h00;
            skip_mask_o <= {MAC_LANES{1'b0}};
        end else begin
            score_est_o <= (sum_abs > 9'h0FF) ? 8'hFF : sum_abs[7:0];
            
            // Generate skip mask: if estimated score is less than threshold, skip all lanes for this tile.
            if ((sum_abs > 9'h0FF ? 8'hFF : sum_abs[7:0]) < sparsity_thresh_reg) begin
                skip_mask_o <= {MAC_LANES{1'b1}};
            end else begin
                skip_mask_o <= {MAC_LANES{1'b0}};
            end
        end
    end

endmodule
