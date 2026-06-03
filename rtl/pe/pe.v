// =============================================================================
// Module      : pe (Processing Element)
// Project     : Systolic Array AI Accelerator
// Author      : Khush (NIT Warangal)
// Description : Parameterized MAC unit for systolic array.
//               Computes acc += a_in * b_in on each clock edge when enabled.
//               Passes a_in and b_in to neighboring PEs for systolic flow.
// Parameters  : DATA_WIDTH=8 (operand bits), ACC_WIDTH=32 (accumulator bits)
// Scalability : DATA_WIDTH=4 for INT4, DATA_WIDTH=16 for INT16
// =============================================================================

module pe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    input  wire [DATA_WIDTH-1:0] a_in,
    input  wire [DATA_WIDTH-1:0] b_in,
    output reg  [DATA_WIDTH-1:0] a_out,
    output reg  [DATA_WIDTH-1:0] b_out,
    output reg  [ACC_WIDTH-1:0]  acc
);
    always @(posedge clk) begin
        if (rst) begin
            a_out <= {DATA_WIDTH{1'b0}};
            b_out <= {DATA_WIDTH{1'b0}};
            acc   <= {ACC_WIDTH{1'b0}};
        end else if (en) begin
            a_out <= a_in;
            b_out <= b_in;
            acc   <= acc + (a_in * b_in);
        end
    end
endmodule
