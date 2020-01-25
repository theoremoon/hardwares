// vim: set ft=systemverilog:

// 32 bit cpu
module cpu(
    input clk,
    input [N*(2**M)-1:0] instructions // instruction memory
);
    localparam N = 32;
    localparam M = 10;

    reg [M-1:0] pc; // program counter
    reg [N-1:0] instr;

    wire [1:0] r1;
    wire [1:0] r2;
    wire [1:0] w1;
    wire [N-1:0] imm;
    wire imm_flag;
    wire [N-1:0] mask;
    wire mem_read;
    wire pc_read;
    wire is_jz;
    wire is_jg;
    wire is_halted;

    wire [N-1:0] v1;
    wire [N-1:0] v2;
    wire [N-1:0] m1;  // imm or v2
    wire [N-1:0] memv;  // value readed from memory

    wire [N-1:0] z;
    wire zf;
    wire sf;
    wire [N-1:0] w;

    controller controller(
        .instr(instr),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .imm(imm),
        .imm_flag(imm_flag),
        .mask(mask),
        .mem_read(mem_read),
        .pc_read(pc_read),
        .is_jz(is_jz),
        .is_jg(is_jg),
        .is_halted(is_halted));
    registers registers(
        .clk(clk),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .mask(mask),
        .w(w),
        .v1(v1),
        .v2(v2));
    mux2 aluinputmux(
        .x(v2),
        .y(imm),
        .sel(imm_flag),
        .z(m1));
    alu alu(
        .x(v1),
        .y(m1),
        .z(z),
        .zf(zf),
        .sf(sf));
    memory memory(
        .clk(clk),
        .address(z[M+2-1:0]),
        .mask(mask),
        .w(v2),
        .v(memv));
    mux4 regwritemux(
        .v(z),
        .w({22'b0, pc}),
        .x(memv),
        .y(32'hz),
        .sel({mem_read, pc_read}),
        .z(w));

    initial begin
        pc = 0;
    end

    always @(posedge clk) begin
        if (is_halted == 0) begin
            // FETCH
            instr <= instructions[pc+:N];

            // automatically executed

            // UPDATE PC
            pc <= ((is_jz&zf)|(is_jg&(~sf))) ? z[M-1:0] : pc + 4;
        end
    end

endmodule
