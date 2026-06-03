// =============================================================================
// Module      : systolic_array
// Project     : Systolic Array AI Accelerator
// Author      : Khush (NIT Warangal)
// Date        : 2026
// Description : Parameterized NxN weight-stationary systolic array.
//               Instantiates input_skew_controller for diagonal data feed,
//               and NxN PE mesh for MAC operations.
//               Computes C = A x B for NxN INT matrices at 100MHz.
//               Default: N=4, DATA_WIDTH=8. Change parameters to scale.
// Parameters  : N=4 (array dimension), DATA_WIDTH=8 (operand bits)
// Scalability : Set N=8 for 8x8, N=16 for 16x16 — no other changes needed.
// =============================================================================

module systolic_array #(
    parameter N          = 4,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32
)(
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          en,
    // Raw un-skewed flattened inputs (feeder handles skewing internally)
    input  wire [N*DATA_WIDTH-1:0]       a_flat,
    input  wire [N*DATA_WIDTH-1:0]       b_flat,
    // Flattened NxNxACC_WIDTH outputs
    output wire [N*N*ACC_WIDTH-1:0]      c_flat
);

    // Skewed wires from controller to PE mesh boundary
    wire [N*DATA_WIDTH-1:0] a_skewed;
    wire [N*DATA_WIDTH-1:0] b_skewed;

    // Input skewing controller — delays row i by i cycles, col j by j cycles
    input_skew_controller #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH)
    ) skew_ctrl (
        .clk      (clk),
        .rst      (rst),
        .en       (en),
        .a_raw    (a_flat),
        .b_raw    (b_flat),
        .a_skewed (a_skewed),
        .b_skewed (b_skewed)
    );

    // Internal mesh wires: a[row][col], b[row][col]
    wire [DATA_WIDTH-1:0] a_wire [0:N-1][0:N];
    wire [DATA_WIDTH-1:0] b_wire [0:N][0:N-1];

    // Connect skewed outputs to PE mesh boundaries
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : input_connect
            assign a_wire[i][0] = a_skewed[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
            assign b_wire[0][i] = b_skewed[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH];
        end
    endgenerate

    // Instantiate NxN PE mesh
    genvar row, col;
    generate
        for (row = 0; row < N; row = row + 1) begin : pe_row
            for (col = 0; col < N; col = col + 1) begin : pe_col
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) pe_inst (
                    .clk   (clk),
                    .rst   (rst),
                    .en    (en),
                    .a_in  (a_wire[row][col]),
                    .b_in  (b_wire[row][col]),
                    .a_out (a_wire[row][col+1]),
                    .b_out (b_wire[row+1][col]),
                    .acc   (c_flat[(row*N+col+1)*ACC_WIDTH-1 : (row*N+col)*ACC_WIDTH])
                );
            end
        end
    endgenerate

endmodule
