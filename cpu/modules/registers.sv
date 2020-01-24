// vim: set ft=systemverilog:

// registers has 4 general registers to read/write
// and be able to read 2 registers simultaneously
// to write 1 register at once
module registers #(
    parameter N = 32, // N is bit width of registers
    parameter M = 2  // 2^M numbers of registers
)(
    input clk, // clock
    input rst, // reset
    input [M-1:0] r1,  // register id 1 to read
    input [M-1:0] r2,  // register id 2 to read
    input [M:0] w1,  // register id to write if MSB is 1 this is disabled
    input [N-1:0] w,  // value to write
    output reg [N-1:0] v1, // register 1 value to read
    output reg [N-1:0] v2 // register 2 value to read
);
    reg [N-1:0] regs[2**M-1:0]; // internal registers (4 items)
    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 2**M; i++) begin
                regs[i] = 0;
            end
        end

        if (w1[M] == 0) begin
            regs[w1] = w;
        end

        v1 = regs[r1];
        v2 = regs[r2];
    end
endmodule
