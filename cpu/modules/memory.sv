// vim: set ft=systemverilog:

// registers has 4 general registers to read/write
// and be able to read 2 registers simultaneously
// to write 1 register at once
module memory #(
    parameter N = 32, // N is bit width of entry
    parameter M = 16  // 2^M numbers of entries
)(
    input clk, // clock
    input [M-1:0] address, // address to read/write
    input wf,  // write flag
    input [N-1:0] w, // value to write
    output [N-1:0] v // memory value
);
    reg [N-1:0] values [2**M-1:0];
    integer i;

    initial begin
        for (i = 0; i < 2**M; i++) begin
            values[i] = 0;
        end
    end

    always @(posedge clk) begin
        if (wf == 1) begin
            values[address] = w;
        end
    end
    assign v = values[address];
endmodule
