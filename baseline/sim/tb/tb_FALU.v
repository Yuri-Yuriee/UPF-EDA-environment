`timescale 1ns/1ps
`include "../../src/src_clean_baseline/CPU/stage/EXE_stage/FALU.v"
`define test
`define VCD

// DUT
// module FALU (input [31:0] A, B,
//              input [2:0]  funct3,   // rm
//              input [4:0]  funct5,   // op selector
//              input [6:0]  opcode,   // 1010011
//              output [31:0] F_result);

module FALU_tb;

  // I/O
  reg  [31:0] A, B;
  reg  [2:0]  funct3;
  reg  [4:0]  funct5;
  reg  [6:0]  opcode;
  wire [31:0] F_result;

  FALU dut (
    .A(A), .B(B),
    .funct3(funct3),
    .funct5(funct5),
    .opcode(opcode),
    .F_result(F_result)
  );

    // ---- RV32F encodings ----
    localparam [6:0] OPC_FPU   = 7'b1010011; // F-extension
    localparam [2:0] RM_DYN    = 3'b111;     // rm=111 (dynamic/ignored by this tb)
    localparam [4:0] F5_FADD_S = 5'b00000;   // FADD.S
    localparam [4:0] F5_FSUB_S = 5'b00001;   // FSUB.S

    // ---- Useful IEEE-754 single constants ----
    localparam [31:0] F32_P0      = 32'h00000000; // 0.0
    localparam [31:0] F32_N0      = 32'h80000000; // -0.0
    localparam [31:0] F32_P1      = 32'h3f800000; // 1.0
    localparam [31:0] F32_P2      = 32'h40000000; // 2.0
    localparam [31:0] F32_P3      = 32'h40400000; // 3.0
    localparam [31:0] F32_P5      = 32'h40a00000; // 5.0
    localparam [31:0] F32_P0_5    = 32'h3f000000; // 0.5
    localparam [31:0] F32_P0_25   = 32'h3e800000; // 0.25
    localparam [31:0] F32_P0_75   = 32'h3f400000; // 0.75
    localparam [31:0] F32_N1      = 32'hbf800000; // -1.0
    localparam [31:0] F32_N2      = 32'hc0000000; // -2.0
    localparam [31:0] F32_N3      = 32'hc0400000; // -3.0
      // Handy named constants
    localparam [31:0] F_P1 = 32'h3f800000; // 1.0
    localparam [31:0] F_N1 = 32'hbf800000; // -1.0
    localparam [31:0] F_P2 = 32'h40000000; // 2.0
    localparam [31:0] F_P3 = 32'h40400000; // 3.0
    localparam [31:0] F_P5 = 32'h40a00000; // 5.0
    localparam [31:0] F_P6 = 32'h40c00000; // 6.0
    localparam [31:0] F_N2 = 32'hc0000000; // -2.0
    localparam [31:0] F_N3 = 32'hc0400000; // -3.0
    localparam [31:0] F_MAX = 32'h7f7fffff; // max finite
    localparam [31:0] F_NMAX= 32'hff7fffff; // -max finite
    localparam [31:0] F_INF = 32'h7f800000;
    localparam [31:0] F_NINF= 32'hff800000;
    localparam [31:0] F_SN_MIN = 32'h00000001; // min subnormal
    localparam [31:0] F_SN_MAX = 32'h007fffff; // max subnormal
    localparam [31:0] F_N_MIN  = 32'h00800000; // min normal
    localparam [31:0] F_POS0   = 32'h00000000; // +0
    localparam [31:0] F_NEG0   = 32'h80000000; // -0
    localparam [31:0] F_QNAN   = 32'h7fc00000; // quiet NaN

  integer pass_cnt = 0, fail_cnt = 0, total_cnt = 0;

  // ---- Runner ----
  task run_case;
    input [127:0] name;
    input [31:0]  a, b;
    input [4:0]   f5;
    input [31:0]  expected;
    begin
      A = a; B = b;
      opcode = OPC_FPU;
      funct3 = RM_DYN;
      funct5 = f5;
      #1; // settle (combinational)
      total_cnt = total_cnt + 1;
      if (F_result === expected) begin
        pass_cnt = pass_cnt + 1;
        $display("PASS %-8s A=%h B=%h -> %h", name, a, b, F_result);
      end else begin
        fail_cnt = fail_cnt + 1;
        $display("FAIL %-8s A=%h B=%h -> got=%h exp=%h (f5=%b rm=%b opc=%b)",
                 name, a, b, F_result, expected, f5, funct3, opcode);
      end
    end
  endtask

  // ---- Vector suites (exactly representable cases) ----
  // FADD.S tests: result = A + B
    task t_FADD; begin
        run_case("FADD.S", F32_P1,    F32_P2,    F5_FADD_S, F32_P3);      // 1 + 2 = 3
        run_case("FADD.S", F32_P0_5,  F32_P0_25, F5_FADD_S, F32_P0_75);   // 0.5 + 0.25 = 0.75
        run_case("FADD.S", F32_P5,    F32_N2,    F5_FADD_S, F32_P3);      // 5 + (-2) = 3
        run_case("FADD.S", F32_N1,    F32_P1,    F5_FADD_S, F32_P0);      // -1 + 1 = 0
        run_case("FADD.S", F32_P0,    F32_N0,    F5_FADD_S, F32_P0);      // +0 + -0 = +0 (allow +0)
    end endtask

    // FSUB.S tests: result = A - B
    task t_FSUB; begin
        run_case("FSUB.S", F32_P5,   F32_P2,   F5_FSUB_S, F32_P3);  // 5 - 2 = 3
        run_case("FSUB.S", F32_P1,   F32_P2,   F5_FSUB_S, F32_N1);  // 1 - 2 = -1
        run_case("FSUB.S", F32_N1,   F32_N2,   F5_FSUB_S, F32_P1);  // -1 - (-2) = 1
        run_case("FSUB.S", F32_P0,   F32_P0,   F5_FSUB_S, F32_P0);  // 0 - 0 = 0
        run_case("FSUB.S", F32_P3,   F32_N3,   F5_FSUB_S, F32_P6()); // 3 - (-3) = 6
    end endtask
    // Example calls (assuming your tb has a runner like run_case(name,a,b,f5,expected)):
    task t_HARD; begin
        // Overflow
        run_case("FADD ovf +inf", F_MAX, F_MAX, F5_FADD_S, F_INF);
        run_case("FSUB ovf +inf", F_MAX, F_NMAX, F5_FSUB_S, F_INF);
        // Negative overflow
        run_case("FADD ovf -inf", F_NMAX, F_NMAX, F5_FADD_S, F_NINF);
        // Subnormal normalization boundaries
        run_case("SN+SN -> Nmin", F_SN_MAX, F_SN_MIN, F5_FADD_S, F_N_MIN);
        run_case("Nmin+SNmin",     F_N_MIN,  F_SN_MIN, F5_FADD_S, 32'h00800001);
        run_case("Nmin-SNmin",     F_N_MIN,  F_SN_MIN, F5_FSUB_S, F_SN_MAX);
        run_case("SNmin+SNmin",    F_SN_MIN, F_SN_MIN, F5_FADD_S, 32'h00000002);
        // Cancellations / signed zero
        run_case("1+(-1)=+0",      F_P1,     F_N1,     F5_FADD_S, F_POS0);
        run_case("1-1=+0",         F_P1,     F_P1,     F5_FSUB_S, F_POS0);
        run_case("-0+0=+0",        F_NEG0,   F_POS0,   F5_FADD_S, F_POS0);
        // NaN propagation
        run_case("qNaN+1",         F_QNAN,   F_P1,     F5_FADD_S, F_QNAN);
        run_case("qNaN-1",         F_QNAN,   F_P1,     F5_FSUB_S, F_QNAN);
        // Large exponent gap absorption
        run_case("max+1 -> max",   F_MAX,    F_P1,     F5_FADD_S, F_MAX);
        // More exact cases
        run_case("5+(-2)=3",       F_P5,     F_N2,     F5_FADD_S, F_P3);
        run_case("6-(-3)=9",       F_P6,     F_N3,     F5_FSUB_S, 32'h41100000);
    end endtask
     // Helper to generate 6.0 (0x40C00000) without more constants
    function [31:0] F32_P6;
        begin
        F32_P6 = 32'h40c00000; // 6.0
        end
    endfunction

  initial begin
    // init
    A=0; B=0; opcode=0; funct3=0; funct5=0;
    #5;

    t_FADD();
    t_FSUB();
    //t_HARD();

    $display("--------------------------------------------------");
    $display("Summary: total=%0d, pass=%0d, fail=%0d", total_cnt, pass_cnt, fail_cnt);
    $display("--------------------------------------------------");
    #10 $finish;
  end
`ifdef VCD
    initial begin
        $dumpfile("FALU.vcd");
        $dumpvars();
        //$fsdbDumpvars("+struct", "+mda", tb);
    end
`endif
endmodule
