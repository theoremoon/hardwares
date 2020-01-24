// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_memory();
    parameter N=32;
    parameter M=10;

    reg clk;
    reg [M+2-1:0] address;
    reg [N-1:0] mask;
    reg [N-1:0] w;
    wire [N-1:0] v;

    memory ram(
        .clk(clk),
        .address(address),
        .mask(mask),
        .w(w),
        .v(v));

    always #5
        clk <= !clk;

    initial begin
        $dumpfile("memory_test.vcd");
        $dumpvars(0, test_memory);

        #1 clk = 0;
        #10 address = 12'h000; mask = 32'hffffffff; w = 32'hcafebabe;
        #10 address = 12'h000; mask = 32'h0000ffff; w = 32'hdeadbeef;
        #10 address = 12'h002; mask = 32'h00000000;
        #10 address = 12'hff0; mask = 32'hffffffff; w = 32'hc0be5417;
        #10 address = 12'h000; mask = 32'h00000000;
        #10 address = 12'hff0; mask = 32'h00000000;
        #10 $finish;
    end
endmodule
