// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_memory();
    parameter N=32;
    parameter M=10;

    reg clk;
    reg [M+2-1:0] address;
    reg [N-1:0] mask;
    reg wf;
    reg [N-1:0] w;
    wire [N-1:0] v;

    memory ram(
        .clk(clk),
        .address(address),
        .mask(mask),
        .wf(wf),
        .w(w),
        .v(v));

    always #5
        clk <= !clk;

    initial begin
        $dumpfile("memory_test.vcd");
        $dumpvars(0, test_memory);

        #1 clk = 0;
        #10 address = 12'h000; mask = 32'hffffffff; w = 32'hcafebabe; wf = 1;  //                         0 1 2 3 4 5 6 7
        #10 address = 12'h000; mask = 32'h0000ffff; w = 32'hdeadbeef; wf = 1;  // 000 is now cafebeef         vvvvvvvv
        #10 address = 12'h002; mask = 32'hffffffff; w = 32'hxxxxxxxx; wf = 0;  // 002 is beef0000 because cafebeef00000000
        #10 address = 12'h002; mask = 32'hffffffff; w = 32'hdeadbeef; wf = 0;  // do not write because wf is 0
        #10 address = 12'h002; mask = 32'h00000000; w = 32'hdeadbeef; wf = 1;  // do not write because mask is 0
        #10 address = 12'hff0; mask = 32'hffffffff; w = 32'hc0be5417; wf = 1;
        #10 address = 12'h000; mask = 32'h00000000; wf = 0;
        #10 address = 12'hff0; mask = 32'h00000000; wf = 0;  // at here, read value is still beef0000
        #10 $finish;  // at here, then value becomes c0be5417
    end
endmodule
