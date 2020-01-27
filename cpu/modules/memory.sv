// vim: set ft=systemverilog:

module memory #(
    parameter M = 10  // 2^M number of words
)(
    input clk, // clock
    input [2+M-1:0] address, // address to read/write (2 is log2(B))
    input [N-1:0] mask, // 0 to keep memory value, 1 to overwrite
    input wf, // write flag
    input [N-1:0] w,  // value to write
    output reg [N-1:0] v // read value
);
    localparam N = 32;  // N is word size
    localparam B = N/8;  // B is octet form of N

    reg [7:0] ram [B*(2**M)-1:0];
    integer i;

    initial begin
        for (i = 0; i < B*(2**M); i++) begin
            ram[i] = 8'h00;
        end
    end

    always @(posedge clk) begin
        v <= {ram[address+0],ram[address+1],ram[address+2],ram[address+3]};
        if (wf == 1) begin
            for (i = 0; i < B; i++) begin
                ram[address+i] <= (ram[address+i]&((~mask)>>((B-i-1)*8)))|((w>>((B-i-1)*8))&((mask)>>((B-i-1)*8)));
            end
        end
    end

endmodule
