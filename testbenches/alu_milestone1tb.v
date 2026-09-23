`timescale 1ns / 1ps

module alu_tb;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_control;
    wire [31:0] result;
    wire        zero;

    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_XOR = 4'b0100;

    integer errors = 0;

    // Instantiate Unit Under Test (UUT)
    alu uut (
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );

    initial begin
        // dump.vcd is default for EDA Playground EPWave
        $dumpfile("dump.vcd");
        $dumpvars(0, alu_tb);

        $display("=================================================");
        $display("          STARTING 32-BIT ALU TESTBENCH           ");
        $display("=================================================");

        // TEST 1: ADD (20 + 22 = 42)
        a = 32'd20;
        b = 32'd22;
        alu_control = ALU_ADD;
        #10;
        $display("[ADD] %0d + %0d = %0d (Expected: 42, zero=%b)", a, b, result, zero);
        if (result !== 32'd42 || zero !== 1'b0) begin
            $display("  --> FAILED: Expected 42, zero=0");
            errors = errors + 1;
        end else begin
            $display("  --> PASSED");
        end

        // TEST 2: SUB (50 - 8 = 42)
        a = 32'd50;
        b = 32'd8;
        alu_control = ALU_SUB;
        #10;
        $display("[SUB] %0d - %0d = %0d (Expected: 42, zero=%b)", a, b, result, zero);
        if (result !== 32'd42 || zero !== 1'b0) begin
            $display("  --> FAILED: Expected 42, zero=0");
            errors = errors + 1;
        end else begin
            $display("  --> PASSED");
        end

        // TEST 3: AND (42 & 63 = 42)
        a = 32'd42;  // binary: ...00101010
        b = 32'd63;  // binary: ...00111111
        alu_control = ALU_AND;
        #10;
        $display("[AND] %0d & %0d = %0d (Expected: 42, zero=%b)", a, b, result, zero);
        if (result !== 32'd42 || zero !== 1'b0) begin
            $display("  --> FAILED: Expected 42, zero=0");
            errors = errors + 1;
        end else begin
            $display("  --> PASSED");
        end

        // TEST 4: OR (40 | 2 = 42)
        a = 32'd40;  // binary: ...00101000
        b = 32'd2;   // binary: ...00000010
        alu_control = ALU_OR;
        #10;
        $display("[OR ] %0d | %0d = %0d (Expected: 42, zero=%b)", a, b, result, zero);
        if (result !== 32'd42 || zero !== 1'b0) begin
            $display("  --> FAILED: Expected 42, zero=0");
            errors = errors + 1;
        end else begin
            $display("  --> PASSED");
        end

        // TEST 5: Zero Flag (42 - 42 = 0, zero should be 1)
        a = 32'd42;
        b = 32'd42;
        alu_control = ALU_SUB;
        #10;
        $display("[ZERO-TEST 1] %0d - %0d = %0d (Expected: 0, zero=1)", a, b, result, zero);
        if (result !== 32'd0 || zero !== 1'b1) begin
            $display("  --> FAILED: Expected result=0, zero=1");
            errors = errors + 1;
        end else begin
            $display("  --> PASSED");
        end

        // TEST 6: Zero Flag Deasserted (42 - 1 = 41, zero should be 0)
        a = 32'd42;
        b = 32'd1;
        alu_control = ALU_SUB;
        #10;
        $display("[ZERO-TEST 2] %0d - %0d = %0d (Expected: 41, zero=0)", a, b, result, zero);
        if (result !== 32'd41 || zero !== 1'b0) begin
            $display("  --> FAILED: Expected result=41, zero=0");
            errors = errors + 1;
        end else begin
            $display("  --> PASSED");
        end

        $display("=================================================");
        if (errors === 0) begin
            $display("      ALL ALU TESTS PASSED SUCCESSFULLY!         ");
        end else begin
            $display("      ALU TESTBENCH COMPLETED WITH %0d ERRORS!   ", errors);
        end
        $display("=================================================");

        $finish;
    end

endmodule