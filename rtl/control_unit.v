module control_unit (
    input wire [6:0] opcode,
    output reg branch,
    output reg mem_read,
    output reg mem_to_reg,
    output reg [1:0] alu_op,
    output reg mem_write,
    output reg alu_src,
    output reg reg_write
);

    always @(*) begin
        // Set safe default control signals to prevent latches
        branch     = 1'b0;
        mem_read   = 1'b0;
        mem_to_reg = 1'b0;
        alu_op     = 2'b00;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        reg_write  = 1'b0;

        case (opcode)
            // R-type instructions (e.g., add, sub)
            7'b0110011: begin
                reg_write  = 1'b1;
                alu_src    = 1'b0;
                mem_to_reg = 1'b0;
                alu_op     = 2'b10;
            end

            // I-type ALU instructions (e.g., addi)
            7'b0010011: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = 1'b0;
                alu_op     = 2'b11;
            end

            // Load instructions (e.g., lw)
            7'b0000011: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00;
            end

            // Store instructions (e.g., sw)
            7'b0100011: begin
                alu_src    = 1'b1;
                mem_write  = 1'b1;
                alu_op     = 2'b00;
            end

            // Branch instructions (e.g., beq)
            7'b1100011: begin
                branch     = 1'b1;
                alu_op     = 2'b01;
            end

            default: begin
                // Keep default values for unknown opcodes
            end
        endcase
    end

endmodule