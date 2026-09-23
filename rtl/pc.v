module pc (
    input wire clk,
    input wire rst_n,          // Active-low reset
    input wire [31:0] pc_next, // Next instruction address coming in
    output reg [31:0] pc_out   // Current instruction address going out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // On reset, start execution at address 0
            pc_out <= 32'h00000000;
        end else begin
            // On every clock edge, update to the next address
            pc_out <= pc_next;
        end
    end

endmodule