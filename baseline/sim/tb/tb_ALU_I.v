`timescale 1ns/1ps
`include "../../src/src_clean_baseline/CPU/stage/EXE_stage/ALU.v"
`define VCD  
// Assumed DUT:
// module ALU (input [31:0] A, B,
//             input [6:0] opcode,
//             input [2:0] funct3,
//             input [6:0] funct7,
//             input [31:0] imm,
//             output reg [31:0] result);

// ---------- Macros ----------
`define LW      {3'b010, 7'b0000011}
`define ADDI    {3'b000, 7'b0010011}
`define SLTI    {3'b010, 7'b0010011}
`define SLTIU   {3'b011, 7'b0010011}
`define XORI    {3'b100, 7'b0010011}
`define ORI     {3'b110, 7'b0010011}
`define ANDI    {3'b111, 7'b0010011}
`define LB      {3'b000, 7'b0000011}
`define JALR    {3'b000, 7'b1100111}
`define LH      {3'b001, 7'b0000011}
`define LBU     {3'b100, 7'b0000011}
`define LHU     {3'b101, 7'b0000011}

module ALU_Itype_tb;

  // DUT I/O
  reg  [31:0] A, B;
  reg  [6:0]  opcode;
  reg  [2:0]  funct3;
  reg  [6:0]  funct7;
  reg  [31:0] imm;
  wire [31:0] result;

  ALU dut(
    .A(A), .B(B),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .imm(imm),
    .result(result)
  );

  // ---- Helpers ----
  function [31:0] sext12(input [11:0] imm12);
    sext12 = {{20{imm12[11]}}, imm12};
  endfunction

  // Expected values
  function [31:0] exp_addi (input [31:0] a, input [11:0] imm12); exp_addi = a + sext12(imm12); endfunction
  function [31:0] exp_slti (input [31:0] a, input [11:0] imm12); exp_slti = ($signed(a) <  $signed(sext12(imm12))) ? 32'd1 : 32'd0; endfunction
  function [31:0] exp_sltiu(input [31:0] a, input [11:0] imm12); exp_sltiu = (a < sext12(imm12)) ? 32'd1 : 32'd0; endfunction
  function [31:0] exp_xori (input [31:0] a, input [11:0] imm12); exp_xori = a ^ sext12(imm12); endfunction
  function [31:0] exp_ori  (input [31:0] a, input [11:0] imm12); exp_ori  = a | sext12(imm12); endfunction
  function [31:0] exp_andi (input [31:0] a, input [11:0] imm12); exp_andi = a & sext12(imm12); endfunction

  // Effective address for loads
  function [31:0] exp_ea(input [31:0] a, input [11:0] imm12); exp_ea = a + sext12(imm12); endfunction
  // JALR target (LSB cleared)
  function [31:0] exp_jalr(input [31:0] a, input [11:0] imm12); exp_jalr = (a + sext12(imm12)) & ~32'h1; endfunction

  integer pass_cnt = 0, fail_cnt = 0, total_cnt = 0;

  task run_case;
    input [127:0] name;
    input [31:0]  a;
    input [11:0]  imm12;
    input [2:0]   f3;
    input [6:0]   opc;
    input [31:0]  expected;
    begin
      A = a;
      B = 32'h0000_0000;        // B unused for I-type in this test
      imm = sext12(imm12);      // feed immediate through imm port
      funct3 = f3;
      opcode = opc;
      funct7 = 7'b0000000;
      #1;
      total_cnt = total_cnt + 1;
      if (result === expected) begin
        pass_cnt = pass_cnt + 1;
        $display("PASS %-8s A=%h imm=%h -> result=%h", name, a, imm, result);
      end else begin
        fail_cnt = fail_cnt + 1;
        $display("FAIL %-8s A=%h imm=%h -> got=%h exp=%h f3=%b opc=%b",
                 name, a, imm, result, expected, f3, opc);
      end
    end
  endtask

// ------------ I-type encodings as localparams ------------
localparam [6:0] F7_I       = 7'b0000000;   // funct7 for these I-type ops

// I-ALU ops (opcode = 0010011)
localparam [2:0] F3_ADDI    = 3'b000;  localparam [6:0] OPC_ADDI  = 7'b0010011;
localparam [2:0] F3_SLTI    = 3'b010;  localparam [6:0] OPC_SLTI  = 7'b0010011;
localparam [2:0] F3_SLTIU   = 3'b011;  localparam [6:0] OPC_SLTIU = 7'b0010011;
localparam [2:0] F3_XORI    = 3'b100;  localparam [6:0] OPC_XORI  = 7'b0010011;
localparam [2:0] F3_ORI     = 3'b110;  localparam [6:0] OPC_ORI   = 7'b0010011;
localparam [2:0] F3_ANDI    = 3'b111;  localparam [6:0] OPC_ANDI  = 7'b0010011;

// Loads (opcode = 0000011)
localparam [6:0] OPC_LOAD   = 7'b0000011;
localparam [2:0] F3_LB      = 3'b000;
localparam [2:0] F3_LH      = 3'b001;
localparam [2:0] F3_LW      = 3'b010;
localparam [2:0] F3_LBU     = 3'b100;
localparam [2:0] F3_LHU     = 3'b101;

// JALR (opcode = 1100111)
localparam [2:0] F3_JALR    = 3'b000;  localparam [6:0] OPC_JALR  = 7'b1100111;


// ------------ Wrappers per instruction (use localparams) ------------
task test_ADDI (input [31:0] a, input [11:0] im);
  begin run_case("ADDI", a, im,  F3_ADDI,  OPC_ADDI,  exp_addi(a,im)); end
endtask

task test_SLTI (input [31:0] a, input [11:0] im);
  begin run_case("SLTI", a, im,  F3_SLTI,  OPC_SLTI,  exp_slti(a,im)); end
endtask

task test_SLTIU(input [31:0] a, input [11:0] im);
  begin run_case("SLTIU",a, im,  F3_SLTIU, OPC_SLTIU, exp_sltiu(a,im)); end
endtask

task test_XORI (input [31:0] a, input [11:0] im);
  begin run_case("XORI", a, im,  F3_XORI,  OPC_XORI,  exp_xori(a,im)); end
endtask

task test_ORI  (input [31:0] a, input [11:0] im);
  begin run_case("ORI",  a, im,  F3_ORI,   OPC_ORI,   exp_ori(a,im));  end
endtask

task test_ANDI (input [31:0] a, input [11:0] im);
  begin run_case("ANDI", a, im,  F3_ANDI,  OPC_ANDI,  exp_andi(a,im)); end
endtask

// Loads: verify effective address only (A + signext(imm))
task test_LB  (input [31:0] a, input [11:0] im);
  begin run_case("LB_EA",  a, im,  F3_LB,  OPC_LOAD,  exp_ea(a,im)); end
endtask

task test_LH  (input [31:0] a, input [11:0] im);
  begin run_case("LH_EA",  a, im,  F3_LH,  OPC_LOAD,  exp_ea(a,im)); end
endtask

task test_LW  (input [31:0] a, input [11:0] im);
  begin run_case("LW_EA",  a, im,  F3_LW,  OPC_LOAD,  exp_ea(a,im)); end
endtask

task test_LBU (input [31:0] a, input [11:0] im);
  begin run_case("LBU_EA", a, im,  F3_LBU, OPC_LOAD,  exp_ea(a,im)); end
endtask

task test_LHU (input [31:0] a, input [11:0] im);
  begin run_case("LHU_EA", a, im,  F3_LHU, OPC_LOAD,  exp_ea(a,im)); end
endtask

// JALR: verify target calculation ((A + imm) & ~1)
task test_JALR(input [31:0] a, input [11:0] im);
  begin run_case("JALR", a, im,  F3_JALR, OPC_JALR,  exp_jalr(a,im)); end
endtask
  // Test vectors
  reg [31:0]  VA [0:7];
  reg [11:0]  VI [0:7];
  integer i;

  initial begin
    // A values
    VA[0]=32'h0000_0000; VA[1]=32'h0000_0001; VA[2]=32'h7FFF_FFFF; VA[3]=32'h8000_0000;
    VA[4]=32'hF0F0_F0F0; VA[5]=32'h0F0F_0F0F; VA[6]=32'hFFFF_FFFF; VA[7]=32'h1234_5678;
    // imm12 values (mix of positive/negative)
    VI[0]=12'h000; VI[1]=12'h001; VI[2]=12'h7FF; // +2047
    VI[3]=12'h800; // -2048
    VI[4]=12'hF00; // -256
    VI[5]=12'h055; // +85
    VI[6]=12'hA3B; // -1477
    VI[7]=12'h3C0; // +960

    // init
    A=0; B=0; imm=0; opcode=0; funct3=0; funct7=0; #5;

    for (i=0; i<8; i=i+1) begin
      test_ADDI (VA[i], VI[i]);
      test_SLTI (VA[i], VI[i]);
      test_SLTIU(VA[i], VI[i]);
      test_XORI (VA[i], VI[i]);
      test_ORI  (VA[i], VI[i]);
      test_ANDI (VA[i], VI[i]);

      test_LB   (VA[i], VI[i]);
      test_LH   (VA[i], VI[i]);
      test_LW   (VA[i], VI[i]);
      test_LBU  (VA[i], VI[i]);
      test_LHU  (VA[i], VI[i]);

      test_JALR (VA[i], VI[i]);
    end

    $display("--------------------------------------------------");
    $display("Summary: total=%0d, pass=%0d, fail=%0d", total_cnt, pass_cnt, fail_cnt);
    $display("--------------------------------------------------");
    #10 $finish;
  end
`ifdef VCD
    initial begin
        $dumpfile("ALU.vcd");
        $dumpvars();
        //$fsdbDumpvars("+struct", "+mda", tb);
    end
`endif
endmodule
