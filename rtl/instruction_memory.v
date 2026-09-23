`timescale 1ns / 1ps

module instruction_memory (
    input  wire [31:0] pc,
    output wire [31:0] instruction
);

    // 64-word (256 bytes) instruction memory
    reg [31:0] memory [0:63];

    // Word-aligned addressing (PC advances by 4 each instruction)
    // pc[7:2] selects one of the 64 words
    assign instruction = memory[pc[7:2]];

    integer i;
    initial begin
        // Initialize all locations with NOP (addi x0, x0, 0)
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'h00000013;
        end

        // Demo sample program:
        // 0x00: addi x1, x0, 20    (x1 = 20)
        memory[0] = 32'h01400093;
        // 0x04: addi x2, x0, 22    (x2 = 22)
        memory[1] = 32'h01600113;
        // 0x08: add  x3, x1, x2    (x3 = x1 + x2 = 42)
        memory[2] = 32'h002081b3;
        // 0x0C: sub  x4, x3, x1    (x4 = 42 - 20 = 22)
        memory[3] = 32'h40118233;
        // 0x10: and  x5, x1, x2    (x5 = 20 & 22 = 20)
        memory[4] = 32'h0020f2b3;
        // 0x14: or   x6, x1, x2    (x6 = 20 | 22 = 22)
        memory[5] = 32'h0020e333;
        // 0x18: xor  x7, x1, x2    (x7 = 20 ^ 22 = 2)
        memory[6] = 32'h0020c3b3;
    end

endmodule
