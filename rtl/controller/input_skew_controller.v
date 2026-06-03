// =============================================================================
// Module      : input_skew_controller
// Project     : Systolic Array AI Accelerator
// Author      : Khush (NIT Warangal)
// Date        : 2026
// Description : Diagonal input skewing controller for NxN systolic array.
//               Row i of matrix A is delayed by i clock cycles.
//               Col j of matrix B is delayed by j clock cycles.
//               This ensures correct diagonal data flow through the PE mesh
//               for weight-stationary matrix multiplication C = A x B.
// Parameters  : N=4 (array dimension), DATA_WIDTH=8 (operand bits)
// Scalability : Works for any N — delay chain scales via generate loop.
// =============================================================================

module input_skew_controller #(
    parameter N          = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     en,
    // Raw un-skewed inputs (one element per row/col per cycle)
    input  wire [N*DATA_WIDTH-1:0]  a_raw,   // a_raw[i] = A[i][current_col]
    input  wire [N*DATA_WIDTH-1:0]  b_raw,   // b_raw[j] = B[current_row][j]
    // Skewed outputs — feed directly into PE mesh boundary
    output wire [N*DATA_WIDTH-1:0]  a_skewed,
    output wire [N*DATA_WIDTH-1:0]  b_skewed
);

    // Shift register banks: a_sr[i][d] = i-th row, d-th delay stage
    // Row i needs i delay stages (row 0 = no delay, row N-1 = N-1 delays)
    reg [DATA_WIDTH-1:0] a_sr [0:N-1][0:N-2];
    reg [DATA_WIDTH-1:0] b_sr [0:N-1][0:N-2];

    genvar i, d;

    generate
        for (i = 0; i < N; i = i + 1) begin : skew_row

            if (i == 0) begin : no_delay
                // Row 0 / Col 0 — zero delay, pass through directly
                assign a_skewed[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] =
                       en ? a_raw[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] : {DATA_WIDTH{1'b0}};
                assign b_skewed[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] =
                       en ? b_raw[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] : {DATA_WIDTH{1'b0}};
            end else begin : with_delay
                // Row/Col i — needs i delay stages
                // Stage 0: capture raw input
                always @(posedge clk) begin
                    if (rst)
                        a_sr[i][0] <= {DATA_WIDTH{1'b0}};
                    else if (en)
                        a_sr[i][0] <= a_raw[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
                    else
                        a_sr[i][0] <= {DATA_WIDTH{1'b0}};
                end

                always @(posedge clk) begin
                    if (rst)
                        b_sr[i][0] <= {DATA_WIDTH{1'b0}};
                    else if (en)
                        b_sr[i][0] <= b_raw[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
                    else
                        b_sr[i][0] <= {DATA_WIDTH{1'b0}};
                end

                // Stages 1..i-1: chain delay registers
                for (d = 1; d < i; d = d + 1) begin : delay_chain
                    always @(posedge clk) begin
                        if (rst) begin
                            a_sr[i][d] <= {DATA_WIDTH{1'b0}};
                            b_sr[i][d] <= {DATA_WIDTH{1'b0}};
                        end else begin
                            a_sr[i][d] <= a_sr[i][d-1];
                            b_sr[i][d] <= b_sr[i][d-1];
                        end
                    end
                end

                // Output: last stage of delay chain
                assign a_skewed[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] = a_sr[i][i-1];
                assign b_skewed[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH] = b_sr[i][i-1];
            end

        end
    endgenerate

endmodule
