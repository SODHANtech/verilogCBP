module alu_control (
    input wire [1:0] alu_op,       // From main control unit
    input wire [2:0] funct3,       // From instruction decoder
    input wire funct7_5,           // Bit 31 of instruction (funct7[5])
    output reg [3:0] alu_control   // Control signal sent directly to ALU
);

    always @(*) begin
        case (alu_op)
            // 2'b00: Loads and Stores (always need ADD to calculate memory address)
            2'b00: alu_control = 4'b0000; // Assuming 4'b0000 is ADD

            // 2'b01: Branches (typically need SUB to compare values)
            2'b01: alu_control = 4'b0001; // Assuming 4'b0001 is SUB

            // 2'b10: R-type or I-type arithmetic instructions
            2'b10: begin
                case (funct3)
                    3'b000: begin // ADD / ADDI / SUB
                        // If it's an R-type and funct7 bit 5 is 1, it's SUB; otherwise ADD
                        if (funct7_5 == 1'b1) 
                            alu_control = 4'b0001; // SUB
                        else 
                            alu_control = 4'b0000; // ADD
                    end
                    3'b110: alu_control = 4'b0011; // OR / ORI
                    3'b111: alu_control = 4'b0010; // AND / ANDI
                    3'b100: alu_control = 4'b0100; // XOR / XORI
                    3'b010: alu_control = 4'b0101; // SLT / SLTI (Set Less Than)
                    default: alu_control = 4'b0000;
                endcase
            end

            default: alu_control = 4'b0000;
        endcase
    end

endmodule