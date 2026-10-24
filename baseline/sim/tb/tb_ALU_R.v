`timescale 1ns/1ps
`include "../../src/src_clean_baseline/CPU/stage/EXE_stage/ALU.v"
`define VCD
`timescale 1ns/1ps

// DUT:
// module ALU (input [31:0] A, B,
//             input [6:0] opcode,
//             input [2:0] funct3,
//             input [6:0] funct7,
//             output reg [31:0] result);

module ALU_tb;

  // DUT I/O
  reg  [31:0] A, B;
  reg  [6:0]  opcode;
  reg  [2:0]  funct3;
  reg  [6:0]  funct7;
  wire [31:0] result;

  ALU dut (
    .A(A), .B(B),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .result(result)
  );

  // Common opcode for R/M-type
  localparam [6:0] OPCODE_R = 7'b0110011;

  // R-type signatures {funct7, funct3}
  localparam [9:0] ADD_SIG   = {7'b0000000, 3'b000};
  localparam [9:0] SUB_SIG   = {7'b0100000, 3'b000};
  localparam [9:0] SLL_SIG   = {7'b0000000, 3'b001};
  localparam [9:0] SLT_SIG   = {7'b0000000, 3'b010};
  localparam [9:0] SLTU_SIG  = {7'b0000000, 3'b011};
  localparam [9:0] XOR_SIG   = {7'b0000000, 3'b100};
  localparam [9:0] SRL_SIG   = {7'b0000000, 3'b101};
  localparam [9:0] SRA_SIG   = {7'b0100000, 3'b101};
  localparam [9:0] OR_SIG    = {7'b0000000, 3'b110};
  localparam [9:0] AND_SIG   = {7'b0000000, 3'b111};

  // M-extension signatures {funct7, funct3}
  localparam [9:0] MUL_SIG    = {7'b0000001, 3'b000};
  localparam [9:0] MULH_SIG   = {7'b0000001, 3'b001};
  localparam [9:0] MULHSU_SIG = {7'b0000001, 3'b010};
  localparam [9:0] MULHU_SIG  = {7'b0000001, 3'b011};

  integer pass_cnt = 0, fail_cnt = 0, total_cnt = 0;

  // Expected value helpers (R-type)
  function [31:0] exp_add (input [31:0] a, b);   exp_add = a + b; endfunction
  function [31:0] exp_sub (input [31:0] a, b);   exp_sub = a - b; endfunction
  function [31:0] exp_sll (input [31:0] a, b);   exp_sll = a << b[4:0]; endfunction
  function [31:0] exp_slt (input [31:0] a, b);   exp_slt = ($signed(a) <  $signed(b)) ? 32'd1 : 32'd0; endfunction
  function [31:0] exp_sltu(input [31:0] a, b);   exp_sltu= (a < b) ? 32'd1 : 32'd0; endfunction
  function [31:0] exp_xor (input [31:0] a, b);   exp_xor = a ^ b; endfunction
  function [31:0] exp_srl (input [31:0] a, b);   exp_srl = a >> b[4:0]; endfunction
  function [31:0] exp_sra (input [31:0] a, b);   exp_sra = $signed(a) >>> b[4:0]; endfunction
  function [31:0] exp_or  (input [31:0] a, b);   exp_or  = a | b; endfunction
  function [31:0] exp_and (input [31:0] a, b);   exp_and = a & b; endfunction

  // Expected value helpers (M-extension)
  function [31:0] exp_mul(input [31:0] a, b);
    reg signed [63:0] prod;
    begin
      prod     = $signed(a) * $signed(b); // low 32 bits are identical for signed/unsigned
      exp_mul  = prod[31:0];
    end
  endfunction

  function [31:0] exp_mulh(input [31:0] a, b);
    reg signed [63:0] prod;
    begin
      prod      = $signed(a) * $signed(b);
      exp_mulh  = prod[63:32];
    end
  endfunction

  function [31:0] exp_mulhsu(input [31:0] a, b);
    reg  signed [63:0] a_s;
    reg  signed [63:0] b_u_signed; // zero-extended then treated as signed (non-negative)
    reg  signed [63:0] prod;
    begin
      a_s        = $signed(a);
      b_u_signed = $signed({32'b0, b});
      prod       = a_s * b_u_signed;
      exp_mulhsu = prod[63:32];
    end
  endfunction

  function [31:0] exp_mulhu(input [31:0] a, b);
    reg [63:0] prod;
    begin
      prod      = {32'b0, a} * {32'b0, b};
      exp_mulhu = prod[63:32];
    end
  endfunction

  // Generic runner
  task run_case;
    input [127:0] name;
    input [31:0] a, b;
    input [6:0]  f7;
    input [2:0]  f3;
    input [31:0] expected;
    begin
      A=a; B=b; opcode=OPCODE_R; funct7=f7; funct3=f3;
      #1;
      total_cnt = total_cnt + 1;
      if (result === expected) begin
        pass_cnt = pass_cnt + 1;
        $display("PASS %-8s A=%h B=%h -> result=%h", name, a, b, result);
      end else begin
        fail_cnt = fail_cnt + 1;
        $display("FAIL %-8s A=%h B=%h -> got=%h exp=%h f7=%b f3=%b",
                  name, a, b, result, expected, f7, f3);
      end
    end
  endtask

  // R-type wrappers
  task test_ADD (input [31:0] a, b); begin run_case("ADD",  a,b, ADD_SIG[9:3],  ADD_SIG[2:0],  exp_add(a,b));  end endtask
  task test_SUB (input [31:0] a, b); begin run_case("SUB",  a,b, SUB_SIG[9:3],  SUB_SIG[2:0],  exp_sub(a,b));  end endtask
  task test_SLL (input [31:0] a, b); begin run_case("SLL",  a,b, SLL_SIG[9:3],  SLL_SIG[2:0],  exp_sll(a,b));  end endtask
  task test_SLT (input [31:0] a, b); begin run_case("SLT",  a,b, SLT_SIG[9:3],  SLT_SIG[2:0],  exp_slt(a,b));  end endtask
  task test_SLTU(input [31:0] a, b); begin run_case("SLTU", a,b, SLTU_SIG[9:3], SLTU_SIG[2:0], exp_sltu(a,b)); end endtask
  task test_XOR (input [31:0] a, b); begin run_case("XOR",  a,b, XOR_SIG[9:3],  XOR_SIG[2:0],  exp_xor(a,b));  end endtask
  task test_SRL (input [31:0] a, b); begin run_case("SRL",  a,b, SRL_SIG[9:3],  SRL_SIG[2:0],  exp_srl(a,b));  end endtask
  task test_SRA (input [31:0] a, b); begin run_case("SRA",  a,b, SRA_SIG[9:3],  SRA_SIG[2:0],  exp_sra(a,b));  end endtask
  task test_OR  (input [31:0] a, b); begin run_case("OR",   a,b, OR_SIG[9:3],   OR_SIG[2:0],   exp_or(a,b));   end endtask
  task test_AND (input [31:0] a, b); begin run_case("AND",  a,b, AND_SIG[9:3],  AND_SIG[2:0],  exp_and(a,b));  end endtask

  // M-extension wrappers
  task test_MUL   (input [31:0] a, b); begin run_case("MUL",    a,b, MUL_SIG[9:3],    MUL_SIG[2:0],    exp_mul(a,b));    end endtask
  task test_MULH  (input [31:0] a, b); begin run_case("MULH",   a,b, MULH_SIG[9:3],   MULH_SIG[2:0],   exp_mulh(a,b));   end endtask
  task test_MULHSU(input [31:0] a, b); begin run_case("MULHSU", a,b, MULHSU_SIG[9:3], MULHSU_SIG[2:0], exp_mulhsu(a,b)); end endtask
  task test_MULHU (input [31:0] a, b); begin run_case("MULHU",  a,b, MULHU_SIG[9:3],  MULHU_SIG[2:0],  exp_mulhu(a,b));  end endtask

  // Vectors
  reg [31:0] vecA [0:9];
  reg [31:0] vecB [0:9];
  integer i;

  initial begin
    // Add more edge cases to stress MUL* high/low behavior
    vecA[0]=32'h0000_0000; vecB[0]=32'h0000_0000;
    vecA[1]=32'h0000_0003; vecB[1]=32'h0000_0007;
    vecA[2]=32'h7FFF_FFFF; vecB[2]=32'h0000_0002; // positive * small
    vecA[3]=32'h8000_0000; vecB[3]=32'h0000_0002; // negative * small
    vecA[4]=32'hFFFF_FFFF; vecB[4]=32'hFFFF_FFFF; // -1 * -1
    vecA[5]=32'h8000_0000; vecB[5]=32'hFFFF_FFFF; // min * -1
    vecA[6]=32'h7FFF_FFFF; vecB[6]=32'hFFFF_FFFF; // max * -1
    vecA[7]=32'h1234_5678; vecB[7]=32'h9ABC_DEF0;
    vecA[8]=32'hFFFF_0001; vecB[8]=32'h0000_FF00; // mixed sign/unsigned stress
    vecA[9]=32'h0000_8000; vecB[9]=32'h8000_0000;

    // Initialize lines
    A=0; B=0; opcode=0; funct3=0; funct7=0;
    #5;

    for (i=0; i<10; i=i+1) begin
      // R-type
      test_ADD (vecA[i], vecB[i]);
      test_SUB (vecA[i], vecB[i]);
      test_SLL (vecA[i], vecB[i]);
      test_SLT (vecA[i], vecB[i]);
      test_SLTU(vecA[i], vecB[i]);
      test_XOR (vecA[i], vecB[i]);
      test_SRL (vecA[i], vecB[i]);
      test_SRA (vecA[i], vecB[i]);
      test_OR  (vecA[i], vecB[i]);
      test_AND (vecA[i], vecB[i]);
      // M-extension
      test_MUL   (vecA[i], vecB[i]);
      test_MULH  (vecA[i], vecB[i]);
      test_MULHSU(vecA[i], vecB[i]);
      test_MULHU (vecA[i], vecB[i]);
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
