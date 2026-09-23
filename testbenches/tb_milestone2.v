    `timescale 1ns/1ps

module tb_milestone2;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg we;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    reg [4:0] rd_addr;
    reg [31:0] rd_data;
    reg [3:0] alu_op;

    // Outputs
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] alu_result;
    wire zero;

    // Instantiate Register File
    regfile u_regfile (
        .clk(clk),
        .rst_n(rst_n),
        .we(we),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Instantiate ALU (Adjust ports to match your alu.v naming if needed)
    alu u_alu (
        .a(rs1_data),
        .b(rs2_data),
        .alu_control(alu_op),
        .result(alu_result),
        .zero(zero)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        we = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        rd_addr = 0;
        rd_data = 0;
        alu_op = 4'b0000; // Assuming 4'b0000 is your ALU ADD operation

        // Release reset after 12ns
        #12;
        rst_n = 1; 
        #10;

        // Step 1: Write 20 into x1
        @(posedge clk);
        we = 1;
        rd_addr = 5'd1;
        rd_data = 32'd20;

        // Step 2: Write 22 into x2
        @(posedge clk);
        rd_addr = 5'd2;
        rd_data = 32'd22;

        // Step 3: Read x1 and x2, compute ADD, write result to x3
        @(posedge clk);
        we = 0;          // Stop writing momentarily to set up read addresses
        rs1_addr = 5'd1; // Select x1
        rs2_addr = 5'd2; // Select x2
        alu_op = 4'b0000;// Set ALU to ADD

        // Wait one cycle for combinatorial logic to settle, then write ALU result to x3
        @(posedge clk);
        we = 1;
        rd_addr = 5'd3;
        rd_data = alu_result; // This captures (rs1_data + rs2_data) = 42

        // Step 4: Verify by reading x3 back
        @(posedge clk);
        we = 0;
        rs1_addr = 5'd3;

        #10;
        $display("----------------------------------------");
        $display("Milestone 2 Test Result:");
        $display("x3 value read = %0d (Expected: 42)", rs1_data);
        if (rs1_data == 32'd42) begin
            $display("SUCCESS: Milestone 2 PASSED! 20 + 22 = 42 🎉");
        end else begin
            $display("FAILURE: Expected 42, got %0d ❌", rs1_data);
        end
        $display("----------------------------------------");

        $finish;
    end

endmodule