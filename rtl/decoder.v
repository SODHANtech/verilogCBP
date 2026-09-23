module decoder (
    input wire [31:0] instr,       // 32-bit instruction from ROM
    output wire [6:0] opcode,      // Opcode field [6:0]
    output wire [4:0] rd,          // Destination register [11:7]
    output wire [2:0] funct3,      // Function 3-bit field [14:12]
    output wire [4:0] rs1,         // Source register 1 [19:15]
    output wire [4:0] rs2,         // Source register 2 [24:20]
    output wire [6:0] funct7       // Function 7-bit field [31:25]
);

    // Extract standard RISC-V instruction fields
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

endmodule