`timescale 1ns / 1ps

module tb_cpu;

    reg clk;
    reg rst_n;

    // Instantiate CPU
    cpu u_cpu (
        .clk(clk),
        .rst_n(rst_n)
    );

    // 10ns clock period (100 MHz)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_trace.vcd");
        $dumpvars(0, tb_cpu);

        clk = 0;
        rst_n = 0;

        $display("================================================================================");
        $display("                         RISC-V SINGLE-CYCLE CPU EXECUTION                      ");
        $display("================================================================================");

        // Hold reset for 15ns
        #15;
        rst_n = 1;

        // Monitor each clock cycle
        repeat (10) @(posedge clk) begin
            #1; // Sample shortly after clock edge
            $display("[Time: %4t ns] PC = 0x%08h | Instr = 0x%08h", $time, u_cpu.pc_current, u_cpu.instruction);
            $display("               ALU Result = 0x%08h (%0d) | Zero = %b", u_cpu.alu_result, u_cpu.alu_result, u_cpu.zero);
            $display("               Regs: x1=%0d, x2=%0d, x3=%0d, x4=%0d, x5=%0d, x6=%0d, x7=%0d",
                     u_cpu.u_regfile.rf[1],
                     u_cpu.u_regfile.rf[2],
                     u_cpu.u_regfile.rf[3],
                     u_cpu.u_regfile.rf[4],
                     u_cpu.u_regfile.rf[5],
                     u_cpu.u_regfile.rf[6],
                     u_cpu.u_regfile.rf[7]);
            $display("--------------------------------------------------------------------------------");
        end

        $display("================================================================================");
        $display("FINAL VERIFICATION OF REGISTER STATE:");
        $display("  x1 (expected 20) : %0d --> %s", u_cpu.u_regfile.rf[1], (u_cpu.u_regfile.rf[1] == 20) ? "PASS" : "FAIL");
        $display("  x2 (expected 22) : %0d --> %s", u_cpu.u_regfile.rf[2], (u_cpu.u_regfile.rf[2] == 22) ? "PASS" : "FAIL");
        $display("  x3 (expected 42) : %0d --> %s", u_cpu.u_regfile.rf[3], (u_cpu.u_regfile.rf[3] == 42) ? "PASS" : "FAIL");
        $display("  x4 (expected 22) : %0d --> %s", u_cpu.u_regfile.rf[4], (u_cpu.u_regfile.rf[4] == 22) ? "PASS" : "FAIL");
        $display("  x5 (expected 20) : %0d --> %s", u_cpu.u_regfile.rf[5], (u_cpu.u_regfile.rf[5] == 20) ? "PASS" : "FAIL");
        $display("  x6 (expected 22) : %0d --> %s", u_cpu.u_regfile.rf[6], (u_cpu.u_regfile.rf[6] == 22) ? "PASS" : "FAIL");
        $display("  x7 (expected  2) : %0d --> %s", u_cpu.u_regfile.rf[7], (u_cpu.u_regfile.rf[7] == 2)  ? "PASS" : "FAIL");
        $display("================================================================================");

        $finish;
    end

endmodule
