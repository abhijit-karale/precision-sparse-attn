module fracturable_mac_array #(
    parameter DATA_WIDTH = 16,
    parameter MAC_LANES  = 8
)(
    input  logic                   clk,
    input  logic                   rst_n,
    
    input  logic [MAC_LANES-1:0]   mac_en_i,
    input  logic [1:0]             precision_sel_i, // 00=INT4, 01=INT8, 10=FP16 (or INT16 for simplicity in RTL)
    
    input  logic [DATA_WIDTH-1:0]  q_data_i,
    input  logic [DATA_WIDTH-1:0]  k_data_i,
    
    output logic [31:0]            mac_result_o [MAC_LANES]
);

    genvar i;
    generate
        for (i = 0; i < MAC_LANES; i++) begin : mac_lane_gen
            logic signed [15:0] op_a_16, op_b_16;
            logic signed [7:0]  op_a_8 [2], op_b_8 [2];
            logic signed [3:0]  op_a_4 [4], op_b_4 [4];

            // In a real design, these would take from different parts of an operand bus.
            // Here, we just duplicate the inputs for the sake of the structural interface.
            assign op_a_16 = q_data_i;
            assign op_b_16 = k_data_i;

            assign op_a_8[0] = q_data_i[7:0];
            assign op_a_8[1] = q_data_i[15:8];
            assign op_b_8[0] = k_data_i[7:0];
            assign op_b_8[1] = k_data_i[15:8];

            assign op_a_4[0] = q_data_i[3:0];
            assign op_a_4[1] = q_data_i[7:4];
            assign op_a_4[2] = q_data_i[11:8];
            assign op_a_4[3] = q_data_i[15:12];
            assign op_b_4[0] = k_data_i[3:0];
            assign op_b_4[1] = k_data_i[7:4];
            assign op_b_4[2] = k_data_i[11:8];
            assign op_b_4[3] = k_data_i[15:12];

            logic signed [31:0] result_16;
            logic signed [31:0] result_8;
            logic signed [31:0] result_4;

            always_comb begin
                result_16 = op_a_16 * op_b_16;
                // Sum of two 8-bit products
                result_8  = (op_a_8[0] * op_b_8[0]) + (op_a_8[1] * op_b_8[1]);
                // Sum of four 4-bit products
                result_4  = (op_a_4[0] * op_b_4[0]) + (op_a_4[1] * op_b_4[1]) + 
                            (op_a_4[2] * op_b_4[2]) + (op_a_4[3] * op_b_4[3]);
            end

            logic [31:0] mac_out_q;

            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    mac_out_q <= '0;
                end else if (mac_en_i[i]) begin
                    case (precision_sel_i)
                        2'b00: mac_out_q <= result_4;  // INT4 mode
                        2'b01: mac_out_q <= result_8;  // INT8 mode
                        2'b10: mac_out_q <= result_16; // FP16 mode (simulated as INT16 here)
                        default: mac_out_q <= '0;
                    endcase
                end
            end

            assign mac_result_o[i] = mac_out_q;
        end
    endgenerate

endmodule
