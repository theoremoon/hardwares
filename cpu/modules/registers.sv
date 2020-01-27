// vim: set ft=systemverilog:

// registers has 4 general registers to read/write
// and be able to read 2 registers simultaneously
// to write 1 register at once
module registers #(
    parameter N = 32, // N is bit width of registers
    parameter M = 2  // 2^M numbers of registers
)(
    input clk, // clock
    input [M-1:0] r1,  // register id 1 to read
    input [M-1:0] r2,  // register id 2 to read
    input [M-1:0] w1,  // register id to write
    input [N-1:0] mask, // write mask (if bit is 1 overwite else keep)
    input wf,  // write flag
    input [N-1:0] w,  // value to write
    output [N-1:0] v1, // register 1 value to read
    output [N-1:0] v2 // register 2 value to read
);
    reg [N-1:0] regs[2**M-1:0]; // internal registers (4 items default)
    integer i;

    initial begin
        for (i = 0; i < 2**M; i++) begin
            regs[i] = 0;
        end
    end

    assign v1 = (r1 == 0) ? 0 : regs[r1];
    assign v2 = (r2 == 0) ? 0 : regs[r2];
    always @(posedge clk) begin
        if (wf == 1'b1) begin
            regs[w1] <= (regs[w1]&(~mask))|(w&mask);
        end
    end
endmodule
