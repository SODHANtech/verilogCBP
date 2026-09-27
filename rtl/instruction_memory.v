`timescale 1ns / 1ps

module instruction_memory (
    input  wire [31:0] pc,
    output wire [31:0] instruction
);

    reg [31:0] memory [0:63];

    // Read the compiled C program from the text file automatically!
    initial begin
        $readmemh("program.hex", memory);
    end

    assign instruction = memory[pc[7:2]];

endmodule
