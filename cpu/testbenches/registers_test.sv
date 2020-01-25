// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_registers();
    parameter N=32;

    reg clk;
    reg [1:0] r1;
    reg [1:0] r2;
    reg [1:0] w1;
    reg [N-1:0] mask;
    reg [N-1:0] w;
    wire [N-1:0] v1;
    wire [N-1:0] v2;

    registers regs(
        .clk(clk),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .mask(mask),
        .w(w),
        .v1(v1),
        .v2(v2));

    always #5
        clk <= !clk;

    initial begin
        $dumpfile("registers_test.vcd");
        $dumpvars(0, test_registers);

        #1 clk = 0; r1 = 0; r2 = 0; w1 = 0; mask = 0; w = 0;
        #10 w1 = 0; mask = 32'hffffffff; w = 32'hBABEC0FF;
        #10 w1 = 1; mask = 32'hffffffff; w = 32'h0000CAFE;
        #10 w1 = 2; mask = 32'hf0f0f0f0; w = 32'hCfBfBfEf;
        #10 w1 = 2; mask = 32'h0f0f0f0f; w = 32'hf0fEfEfF;
        #10 w1 = 3; mask = 32'hffffffff; w = 32'hffffffff;
        #10 r1 = 0; r2 = 1; w1 = 0; mask=32'hffffffff; w = 32'h0; // v1 should be BABEC0FF
        #10 // at here then v1 is 0
        #10 r1 = 2; r2 = 3;
        #10 $finish;
    end
endmodule
