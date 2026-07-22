module softmax_approx (
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [31:0]            acc_out_i,
    input  logic [1:0]             precision_sel_i,
    output logic [31:0]            softmax_out_o
);
    // Piecewise-linear or lookup-table based softmax for skipped/reduced-precision paths
    // For this RTL, we will do a simple shift-based approximation (e^x ~ 2^(x*const)).
    
    logic [31:0] softmax_q;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            softmax_q <= '0;
        end else begin
            // Depending on precision, the scaling factor of the accumulator varies.
            // We use simple right-shifts to approximate Softmax scaling.
            if (acc_out_i[31]) begin // Negative value
                softmax_q <= 32'd0;  // approx e^x = 0 for large negative x
            end else begin
                case (precision_sel_i)
                    2'b00: softmax_q <= (acc_out_i >> 2); // INT4 scaling
                    2'b01: softmax_q <= (acc_out_i >> 4); // INT8 scaling
                    2'b10: softmax_q <= (acc_out_i >> 8); // FP16/INT16 scaling
                    default: softmax_q <= acc_out_i;
                endcase
            end
        end
    end
    
    assign softmax_out_o = softmax_q;

endmodule
