`timescale 1ns/1ps
`define VCD
`include "../../src/src_clean_baseline/CPU/stage/IF_stage.v"

module tb_IF_stage;

  // ---------------- DUT 介面 ----------------
  reg         clk, rst;
  reg         stall;
  reg         BJ_control;
  reg  [31:0] BJ_target;     // 32-bit 跳躍目標
  wire [31:0] instr;
  wire [31:0] PC;

  // 例化 DUT
  IF_stage DUT (
    .BJ_control (BJ_control),
    .BJ_target  (BJ_target),
    .stall      (stall),
    .clk        (clk),
    .rst        (rst),
    .out_instr      (instr),
    .out_PC         (PC)
  );

  // ---------------- 時脈/重置 ----------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  task do_reset;
    begin
      rst        = 1;
      stall      = 0;
      BJ_control = 0;
      BJ_target  = 32'd0;
      repeat (4) @(posedge clk);
      rst = 0;
      //@(posedge clk);
    end
  endtask

  // 依 PC 取 i-cache 索引：16384 x 32-bit，word 位址 PC[15:2]
  function [13:0] f_mem_idx(input [31:0] pc);
    f_mem_idx = pc[15:2];
  endfunction

  // ---------------- 初始化 i-cache 並放可辨識的「指令序列」 ----------------
  // base 段：從 PC=0x0000_0000 起，8 筆
  // tgt  段：從 PC=0x0000_0040 起，8 筆（作為 branch 目標）
  // 指令碼選一些常見 RISC-V 指令（RV32I）；DUT 只取值，不需解碼也能驗證正確讀出。
  localparam integer BASE_CNT = 8;
  localparam integer TGT_CNT  = 8;

  // 一些現成 opcode（僅作為「值」，不用真的執行）
  localparam [31:0] NOP          = 32'h00000013; // addi x0,x0,0
  localparam [31:0] ADDI_X1_1    = 32'h00100093; // addi x1,x0,1
  localparam [31:0] ADDI_X2_2    = 32'h00200113; // addi x2,x0,2
  localparam [31:0] ADDI_X3_3    = 32'h00300193; // addi x3,x0,3
  localparam [31:0] ADDI_X4_4    = 32'h00400213; // addi x4,x0,4
  localparam [31:0] OR_X5_X1X2   = 32'h0020A2B3; // or   x5,x1,x2 (手寫範例碼)
  localparam [31:0] AND_X6_X2X3  = 32'h003122B3; // and  x5,x2,x3（僅作辨識）
  localparam [31:0] XOR_X7_X3X4  = 32'h0041C3B3; // xor  x7,x3,x4（僅作辨識）

  localparam [31:0] TGT_ADDI_X8_8  = 32'h00800413; // addi x8 ,x0,8
  localparam [31:0] TGT_ADDI_X9_9  = 32'h00900493; // addi x9 ,x0,9
  localparam [31:0] TGT_ADDI_X10_10= 32'h00A00513; // addi x10,x0,10
  localparam [31:0] TGT_ADDI_X11_11= 32'h00B00593; // addi x11,x0,11
  localparam [31:0] TGT_ADDI_X12_12= 32'h00C00613; // addi x12,x0,12
  localparam [31:0] TGT_ADDI_X13_13= 32'h00D00693; // addi x13,x0,13
  localparam [31:0] TGT_ADDI_X14_14= 32'h00E00713; // addi x14,x0,14
  localparam [31:0] TGT_ADDI_X15_15= 32'h00F00793; // addi x15,x0,15

  reg [31:0] base_prog [0:BASE_CNT-1];
  reg [31:0] tgt_prog  [0:TGT_CNT-1];

  task init_icache_and_programs;
    integer i;
    begin
      // 全部清成 NOP，避免 X
      for (i=0; i<16384; i=i+1) begin
        DUT.IM1.i_SRAM.memory[i] = NOP;
      end

      // 準備兩段程式
      base_prog[0]=ADDI_X1_1;  base_prog[1]=ADDI_X2_2;
      base_prog[2]=ADDI_X3_3;  base_prog[3]=ADDI_X4_4;
      base_prog[4]=OR_X5_X1X2; base_prog[5]=AND_X6_X2X3;
      base_prog[6]=XOR_X7_X3X4;base_prog[7]=NOP;

      tgt_prog[0]=TGT_ADDI_X8_8;   tgt_prog[1]=TGT_ADDI_X9_9;
      tgt_prog[2]=TGT_ADDI_X10_10; tgt_prog[3]=TGT_ADDI_X11_11;
      tgt_prog[4]=TGT_ADDI_X12_12; tgt_prog[5]=TGT_ADDI_X13_13;
      tgt_prog[6]=TGT_ADDI_X14_14; tgt_prog[7]=TGT_ADDI_X15_15;

      // 寫入 i-cache：base 段從 PC=0x0000_0000；tgt 段從 PC=0x0000_0040（索引 16）
      for (i=0; i<BASE_CNT; i=i+1)
        DUT.IM1.i_SRAM.memory[ i ] = base_prog[i];

      for (i=0; i<TGT_CNT; i=i+1)
        DUT.IM1.i_SRAM.memory[ 16+i ] = tgt_prog[i];
    end
  endtask

  // ---------------- 期望模型（檢查 PC 與 instr） ----------------
  reg        valid_d1;
  reg [31:0] prev_PC;
  reg [31:0] exp_PC_d1, exp_instr_d1;
  reg       pre_stall;

  task model_next_expect(input do_branch, input [31:0] tgt, input do_stall);
    reg [31:0] next_pc;
    begin
      if (!valid_d1) begin
        // reset 後第一個可見輸出拍（PC 從 0 開始）
        next_pc     = 32'h8000_0000;
        exp_PC_d1   = next_pc;
        exp_instr_d1= DUT.IM1.i_SRAM.memory[ f_mem_idx(next_pc) ];
        valid_d1    = 1'b1;
      end else begin
        if (pre_stall) begin
          next_pc     = prev_PC;                // hold
        end else if (do_branch) begin
          next_pc     = tgt;                    // 跳到目標
        end else begin
          next_pc     = prev_PC + 32'd4;        // 正常 +4
        end
        exp_PC_d1    = next_pc;
        exp_instr_d1 = DUT.IM1.i_SRAM.memory[ f_mem_idx(next_pc) ];
      end
    end
  endtask

  task check_outputs;
    begin
      if (PC !== exp_PC_d1)
        $fatal(1, "[PC] mismatch: got=%h exp=%h", PC, exp_PC_d1);
      if (instr !== exp_instr_d1 && !stall)
        $fatal(1, "[instr] mismatch: got=%h exp=%h (PC=%h)", instr, exp_instr_d1, PC);
      // 更新上一拍 PC
      prev_PC = PC;
       pre_stall = stall;
    end
  endtask

  // ---------------- 測試流程 ----------------
  initial begin
`ifdef VCD
    $dumpfile("IF_stage.vcd");
    $dumpvars(0, tb_IF_stage);
`endif

    valid_d1 = 1'b0;
    prev_PC  = 32'h8000_0000;

    do_reset;
    init_icache_and_programs;
    $display("%h",  DUT.IM1.i_SRAM.memory[0]);
    @(negedge clk);
    // T1：直線抓取 base 段前 5 筆
    repeat (5) begin
    //posedge clk);
      BJ_control = 1'b0; BJ_target = 32'd0; stall = 1'b0;
      model_next_expect(1'b0, 32'd0, 1'b0);
      check_outputs();
      @(negedge clk);
    end
    $display("[T1] linear fetch base OK");

    // T2：stall 兩拍（PC 與 instr 都應 hold）
    //@(negedge clk);
    BJ_control = 1'b0; BJ_target = 32'd0; stall = 1'b1;
    model_next_expect(1'b0, 32'd0, 1'b1);
    @(negedge clk); 
    check_outputs();

    @(negedge clk);
    BJ_control = 1'b0; BJ_target = 32'd0; stall = 1'b1;
    model_next_expect(1'b0, 32'd0, 1'b1);
    //@(posedge clk); 
    check_outputs();
    $display("[T2] stall hold OK");

    // 解除 stall 後再走 2 拍（仍在 base 段）
    BJ_control = 1'b0; BJ_target = 32'd0; stall = 1'b0;
    prev_PC =  prev_PC  + 32'd4;
    exp_PC_d1    = prev_PC + 32'd4;
    exp_instr_d1 = DUT.IM1.i_SRAM.memory[ f_mem_idx(prev_PC + 32'd4) ];
    repeat (2) begin
      //@(posedge clk);
      BJ_control = 1'b0; BJ_target = 32'd0; stall = 1'b0;
      model_next_expect(1'b0, 32'd0, 1'b0);
      @(negedge clk); 
      check_outputs();
    end

    // T3：branch 跳到 0x40（tgt 段），下一拍應讀到 tgt_prog[0]，之後連續 +4
   
    BJ_control = 1'b1; BJ_target = 32'h0000_0040; stall = 1'b0;
    model_next_expect(1'b1, 32'h0000_0040, 1'b0);
    @(negedge clk);
    BJ_control = 1'b0; BJ_target = 32'h0000_0040; stall = 1'b0;
    @(negedge clk); 
    check_outputs();
    $display("[T3] branch redirect to tgt OK");

    // 在 tgt 段再取 4 筆
    repeat (4) begin
      @(negedge clk);
      BJ_control = 1'b0; BJ_target = 32'd0; stall = 1'b0;
      model_next_expect(1'b0, 32'd0, 1'b0);
      //@(posedge clk); 
      check_outputs();
    end
    $display("[T3] fetch on tgt segment OK");

    $display("ALL TESTS PASSED.");
    #20 $finish;
  end

endmodule
