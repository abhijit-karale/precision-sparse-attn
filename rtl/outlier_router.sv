`timescale 1ns / 1ps

module outlier_router #(
    parameter DATA_WIDTH = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,
    
    // Data stream
    input  logic [DATA_WIDTH-1:0] qkv_data_i,
    input  logic [7:0]            outlier_thresh_i, // Threshold to trigger FP16
    input  logic [1:0]            base_precision_i, // FSM's intended precision
    
    // Outputs
    output logic [DATA_WIDTH-1:0] routed_data_o,
    output logic [1:0]            final_precision_o,
    output logic                  outlier_mask_o
);

    logic outlier_detected;

    // Detect outliers (simplified magnitude check)
    always_comb begin
        outlier_detected = 1'b0;
        // If absolute value exceeds threshold, it's an outlier
        if (qkv_data_i[DATA_WIDTH-2:0] > {{(DATA_WIDTH-9){1'b0}}, outlier_thresh_i}) begin
            outlier_detected = 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            routed_data_o <= '0;
            final_precision_o <= 2'b01; // Default INT8
            outlier_mask_o <= 1'b0;
        end else begin
            routed_data_o <= qkv_data_i;
            outlier_mask_o <= outlier_detected;
            
            // Override FSM precision if an outlier is detected
            if (outlier_detected) begin
                final_precision_o <= 2'b10; // Force FP16
            end else begin
                final_precision_o <= base_precision_i; // Use base precision
            end
        end
    end

endmodule
