// vim: set ft=systemverilog:

`timescale 1ns/100ps
module test_cpu();
    parameter N=32;
    localparam M = 10;

    reg clk;
    reg rst;
    reg [7:0] instructions [0:4*(2**M)-1];
    wire is_halted;

    cpu cpu(
        .clk(clk),
        .instructions(instructions),
        .is_halted(is_halted));

    always #100 begin
        clk <= !clk;
        if (is_halted) begin
            $finish;
        end
    end

    initial begin
        $dumpfile("cpu_test.vcd");
        $dumpvars(0, test_cpu);
        $readmemh("program.hex", instructions);

        rst = 0; clk = 1;
        #10 rst = 0;
    end
endmodule
