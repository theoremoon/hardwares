// vim: set ft=systemverilog:

// 32 bit cpu
module cpu(
    input clk,
    input rst,
    input [7:0] instructions [4*(2**M)-1:0], // instruction memory
    output reg is_halted
);
    localparam N = 32;
    localparam M = 10;

    reg [M-1:0] pc; // program counter
    reg [N-1:0] instr;
    reg controller_clk;
    reg mem_clk;
    reg reg_clk;
    reg reg_write_flag;
    reg alu_clk;
    reg [3:0] state;

    wire [3:0] r1;
    wire [3:0] r2;
    wire [3:0] w1;
    wire [N-1:0] imm;
    wire imm_flag;
    wire [N-1:0] mask;
    wire reg_write;
    wire mem_write;
    wire mem_read;
    wire [3:0] alu_mode;
    wire pc_read;
    wire is_branch;
    wire is_jump;
    wire halted_flag;

    wire [N-1:0] v1;
    wire [N-1:0] v2;
    wire [N-1:0] m1;  // imm or v2
    wire [N-1:0] memv;  // value readed from memory

    wire [N-1:0] z;
    wire [N-1:0] w;

    controller controller(
        // input
        .clk(controller_clk),
        .instr(instr),
        // output
        .alu_mode(alu_mode),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .imm(imm),
        .imm_flag(imm_flag),
        .mask(mask),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .pc_read(pc_read),
        .is_branch(is_branch),
        .is_jump(is_jump),
        .is_halted(halted_flag));
    defparam registers.M = 4;
    registers registers(
        .clk(reg_clk),
        .r1(r1),
        .r2(r2),
        .w1(w1),
        .mask(mask),
        .wf(reg_write_flag),
        .w(w),
        .v1(v1),
        .v2(v2));
    mux2 aluinputmux(
        .x(v2),
        .y(imm),
        .sel(imm_flag),
        .z(m1));
    alu alu(
        .clk(alu_clk),
        .x(v1),
        .y(m1),
        .mode(alu_mode),
        .z(z));
    memory memory(
        .clk(mem_clk),
        .address(z[M+2-1:0]),
        .mask(mask),
        .wf(mem_write),
        .w(v2),
        .v(memv));
    mux4 regwritemux(
        .v(z),
        .w({22'b0, pc + 10'd4}),
        .x(memv),
        .y(32'hx),
        .sel({mem_read, pc_read}),
        .z(w));


    initial begin
        pc = 0;
        is_halted = 0;
    end

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            pc = 0;
            state = 4'b0000;
            controller_clk = 0;
            mem_clk = 0;
            reg_clk = 0;
            alu_clk = 0;
        end
        else if (halted_flag == 0) begin
            case (state)
                4'b0000: begin
                    instr <= {instructions[pc],instructions[pc+1],instructions[pc+2],instructions[pc+3]};
                    controller_clk <= 1;
                    state <= 4'b0001;
                end
                4'b0001: begin
                    controller_clk <= 0;
                    reg_write_flag <= 0;
                    reg_clk <= 1;
                    state <= 4'b0010;
                end
                4'b0010: begin
                    reg_clk <= 0;
                    alu_clk <= 1;
                    state <= 4'b0011;
                end
                4'b0011: begin
                    alu_clk <= 0;
                    mem_clk <= 1;
                    state <= 4'b0100;
                end
                4'b0100: begin
                    mem_clk <= 0;
                    reg_write_flag <= reg_write;
                    reg_clk <= 1;
                    state <= 4'b0101;
                end
                4'b0101: begin
                    reg_clk <= 0;
                    if (is_jump) begin
                        pc <= z[M-1:0];
                    end
                    else if (is_branch & z[0] == 1) begin
                        pc <= imm;
                    end
                    else begin
                        pc <= pc + 4;
                    end
                    state <= 4'b0000;
                end
            endcase
        end
        else begin
            is_halted = 1;
        end
    end


endmodule
