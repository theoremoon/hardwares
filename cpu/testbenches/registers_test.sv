// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_registers();
    parameter N=32;

    reg clk;
    reg [1:0] r1;
    reg [1:0] r2;
    reg [2:0] w1;
    reg [N-1:0] w;
    wire [N-1:0] v1;
    wire [N-1:0] v2;

    registers regs(
        .clk(clk),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .w(w),
        .v1(v1),
        .v2(v2));

    always #5
        clk <= !clk;

    initial begin
        $dumpfile("registers_test.vcd");
        $dumpvars(0, test_registers);

        #1 clk = 0; r1 = 0; r2 = 0; w1 = 0; w = 0;
        #10 w1 = 0; w = 32'd01;
        #10 w1 = 1; w = 32'b11;
        #10 w1 = 2; w = 32'b111;
        #10 w1 = 3; w = 32'hffffffff;
        #10 w1 = 4;
        #10 r1 = 0; r2 = 1;
        #10 r1 = 2; r2 = 3;
        #10 w1 = 3; w = 0;
        #10 w1 = 4; w = 32'd100;
        #10 $finish;
    end
endmodule
