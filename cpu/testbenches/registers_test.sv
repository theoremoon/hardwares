// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_registers();
    parameter N=32;

    reg clk;
    reg [1:0] r1;
    reg [1:0] r2;
    reg [1:0] w1;
    reg [N-1:0] mask;
    reg wf;
    reg [N-1:0] w;
    wire [N-1:0] v1;
    wire [N-1:0] v2;

    registers regs(
        .clk(clk),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .mask(mask),
        .wf(wf),
        .w(w),
        .v1(v1),
        .v2(v2));

    always #5
        clk <= !clk;

    initial begin
        $dumpfile("registers_test.vcd");
        $dumpvars(0, test_registers);

        #1 clk = 0; r1 = 0; r2 = 1; w1 = 0; wf = 0; mask=32'h00000000;w = 0;
        #10 w1 = 0; wf = 1; mask=32'hffffffff; w = 32'hBABEC0FF;  // write to $0, but $0 is always 0
        #10 w1 = 1; wf = 1; mask=32'hf0f0f0f0; w = 32'h5417CAFE;
        #10 w1 = 1; wf = 1; mask=32'h0f0f0f0f; w = 32'h5417CAFE;  // at here $1 is 5010C0F0
        #10 w1 = 2; wf = 1; mask=32'hffffffff; w = 32'hDEADBEEF;  // here, $1 becomes 5417CAFE
        #10 w1 = 2; wf = 0; mask=32'hffffffff; w = 32'hxxxxxxxx;  // wf = 0
        #10 w1 = 3; wf = 1; mask=32'hffffffff; w = 32'hffffffff;
        #10 r1 = 0; r2 = 1; w1 = 1; wf=1; w = 32'h0; // v1($1) still be 5417CAFE, change is applied at next clk
        #10 r1 = 2; r2 = 3; // at here then v1 is 0
        #10 $finish;
    end
endmodule
