// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_memory();
    parameter N=32;
    parameter M=16;

    reg clk;
    reg rst;
    reg [M-1:0] address;
    reg wf;
    reg [N-1:0] w;
    wire [N-1:0] v;

    memory ram(
        .clk(clk),
        .rst(rst),
        .address(address),
        .wf(wf),
        .w(w),
        .v(v));

    always #5
        clk <= !clk;

    initial begin
        $dumpfile("memory_test.vcd");
        $dumpvars(0, test_memory);

        #1 rst = 0; clk = 0; wf = 0;
        #10 rst = 1;
        #10 wf = 1; address = 16'h0001; w = 32'hcafebabe;
        #10 wf = 1; address = 16'hffff; w = 32'hdeadbeef;
        #10 wf = 0; address = 16'h0000;
        #10 wf = 0; address = 16'h0001;
        #10 wf = 0; address = 16'hffff;
        #10 $finish;
    end
endmodule
