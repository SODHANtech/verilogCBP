module cpu (
    input wire clk,
    input wire rst_n
);

    // PC signals
    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
    wire [31:0] pc_branch_target;

    // Instruction & Decoder signals
    wire [31:0] instruction;
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    // Control signals
    wire branch;
    wire mem_read;
    wire mem_to_reg;
    wire [1:0] alu_op;
    wire mem_write;
    wire alu_src;
    wire reg_write;

    // Datapath signals
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] imm_out;
    wire [31:0] alu_b_operand;
    wire [3:0] alu_control_out;
    wire [31:0] alu_result;
    wire zero;
    wire [31:0] writeback_data;

    // 1. Program Counter Module
    pc u_pc (
        .clk(clk),
        .rst_n(rst_n),
        .pc_next(pc_next),
        .pc_out(pc_current)
    );

    // PC + 4 adder
    assign pc_plus_4 = pc_current + 32'd4;

    // 2. Instruction Memory (ROM)
    instruction_memory u_imem (
        .pc(pc_current),
        .instruction(instruction)
    );

    // 3. Instruction Decoder
    decoder u_decoder (
        .instr(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );

    // 4. Main Control Unit
    control_unit u_control (
        .opcode(opcode),
        .branch(branch),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .reg_write(reg_write)
    );

    // 5. Immediate Generator
    immediate_gen u_imm_gen (
        .instr(instruction),
        .imm_out(imm_out)
    );

    // Writeback data mux (For now pointing directly to ALU result; data memory integration comes later)
    assign writeback_data = alu_result;

    // 6. Register File
    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .we(reg_write),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(writeback_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // ALU Source Mux (Chooses between rs2 register data or immediate value)
    assign alu_b_operand = alu_src ? imm_out : rs2_data;

    // 7. ALU Control
    alu_control u_alu_control (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7_5(funct7[5]),
        .alu_control(alu_control_out)
    );

    // 8. ALU
    alu u_alu (
        .a(rs1_data),
        .b(alu_b_operand),
        .alu_control(alu_control_out),
        .result(alu_result),
        .zero(zero)
    );

    // Branch target calculation (PC + Immediate offset)
    assign pc_branch_target = pc_current + imm_out;

    // Next PC Mux (Handles sequential execution vs conditional branching)
    assign pc_next = (branch & zero) ? pc_branch_target : pc_plus_4;

endmodule