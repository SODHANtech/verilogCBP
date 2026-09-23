module regfile (
    input wire clk,
    input wire rst_n,          // Active-low reset
    input wire we,             // Write Enable
    input wire [4:0] rs1_addr, // Source Register 1 Address
    input wire [4:0] rs2_addr, // Source Register 2 Address
    input wire [4:0] rd_addr,  // Destination Register Address
    input wire [31:0] rd_data, // Data to write
    output wire [31:0] rs1_data, // Data from Source Register 1
    output wire [31:0] rs2_data  // Data from Source Register 2
);

    // 32 registers, each 32 bits wide
    reg [31:0] rf [31:0];

    // Read Port 1: If address is 0, hardwire to 0. Otherwise read array.
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : rf[rs1_addr];

    // Read Port 2: If address is 0, hardwire to 0. Otherwise read array.
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : rf[rs2_addr];

    // Write Port: Synchronous write on positive clock edge
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Optional: Zero out registers on reset
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'd0;
            end
        end else if (we && (rd_addr != 5'd0)) begin
            // Write data only if Write Enable is high AND destination isn't x0
            rf[rd_addr] <= rd_data;
        end
    end

endmodule