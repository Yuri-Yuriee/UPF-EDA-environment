
// seting 
`define test
//`define basic


// opcode type define
`define NOP         7'd0
`define R_type      7'b0110011
`define I_type_1    7'b0000011
`define I_type_2    7'b0010011  
`define I_type_3    7'b1100111
`define S_type      7'b0100011  
`define B_type      7'b1100011
`define U_type_1    7'b0010111  
`define U_type_2    7'b0110111
`define J_type      7'b1101111
`define F_type_1    7'b0000111
`define F_type_2    7'b0100111  
`define F_type_3    7'b1010011
`define CSR         7'b1110011

// R-type base instructions {funct7, funct3}
`define ADD     {7'b0000000, 3'b000} // Add
`define SUB     {7'b0100000, 3'b000} // Subtract
`define SLL     {7'b0000000, 3'b001} // Shift left logical
`define SLT     {7'b0000000, 3'b010} // Set less than (signed)
`define SLTU    {7'b0000000, 3'b011} // Set less than (unsigned)
`define XOR     {7'b0000000, 3'b100} // Bitwise XOR
`define SRL     {7'b0000000, 3'b101} // Shift right logical
`define SRA     {7'b0100000, 3'b101} // Shift right arithmetic
`define OR      {7'b0000000, 3'b110} // Bitwise OR
`define AND     {7'b0000000, 3'b111} // Bitwise AND

// M-extension (integer multiplication)
`define MUL     {7'b0000001, 3'b000} // Multiply (low bits)
`define MULH    {7'b0000001, 3'b001} // Multiply high (signed × signed)
`define MULHSU  {7'b0000001, 3'b010} // Multiply high (signed × unsigned)
`define MULHU   {7'b0000001, 3'b011} // Multiply high (unsigned × unsigned)

// I-type   {funct3, opcode}
`define LW      {3'b010, 7'b0000011} // Load Word
`define ADDI    {3'b000, 7'b0010011} // Add Immediate
`define SLTI    {3'b010, 7'b0010011} // Set Less Than Immediate (signed)
`define SLTIU   {3'b011, 7'b0010011} // Set Less Than Immediate (unsigned)
`define XORI    {3'b100, 7'b0010011} // XOR Immediate
`define ORI     {3'b110, 7'b0010011} // OR Immediate
`define ANDI    {3'b111, 7'b0010011} // AND Immediate
`define LB      {3'b000, 7'b0000011} // Load Byte
`define JALR    {3'b000, 7'b1100111} // Jump And Link Register
`define LH      {3'b001, 7'b0000011} // Load Halfword
`define LBU     {3'b100, 7'b0000011} // Load Byte Unsigned
`define LHU     {3'b101, 7'b0000011} // Load Halfword Unsigned

// I-type shift  {funct7 ,funct3, opcode}
`define SLLI    {7'b0000000, 3'b001, 7'b0010011} // Shift Left Logical Immediate
`define SRLI    {7'b0000000, 3'b101, 7'b0010011} // Shift Right Logical Immediate
`define SRAI    {7'b0100000, 3'b101, 7'b0010011} // Shift Right Arithmetic Immediate

//S-type    {funct3}
`define SW      {3'b010}
`define SB      {3'b000}
`define SH      {3'b001}

//B-type    {funct3}
`define BEQ     {3'b000} // Branch if Equal
`define BNE     {3'b001} // Branch if Not Equal
`define BLT     {3'b100} // Branch if Less Than (signed)
`define BGE     {3'b101} // Branch if Greater or Equal (signed)
`define BLTU    {3'b110} // Branch if Less Than (unsigned)
`define BGEU    {3'b111} // Branch if Greater or Equal (unsigned)

//U-type    {opcode}
`define AUIPC   {7'b0010111}
`define LUI     {7'b0110111}

//F-type    {funct3, opcode}
`define FLW     {3'b010, 7'b0000111}
`define FSW     {3'b010, 7'b0100111}

//  {funct5, opcode}
`define FADD_S  {5'b00000, 7'b1010011}
`define FSUB_S  {5'b00001, 7'b1010011}

//CSR   {funct3}
`define CSRRW   {3'b001} // Atomic Read/Write CSR
`define CSRRS   {3'b010} // Atomic Read and Set Bits in CSR
`define CSRRC   {3'b011} // Atomic Read and Clear Bits in CSR
`define CSRRWI  {3'b101} // Atomic Read/Write CSR (immediate)
`define CSRRSI  {3'b110} // Atomic Read and Set Bits in CSR (immediate)
`define CSRRCI  {3'b111} // Atomic Read and Clear Bits in CSR (immediate)

`define RDINSTRETH {12'b110010000010, 5'b00000, 3'd010} // Read Upper 32 bits of Instret
`define RDINSTRET  {12'b110000000010, 5'b00000, 3'd010} // Read Lower 32 bits of Instret
`define RDCYCLEH   {12'b110010000000, 5'b00000, 3'd010} // Read Upper 32 bits of Cycle Counter
`define RDCYCLE    {12'b110000000000, 5'b00000, 3'd010} // Read Lower 32 bits of Cycle Counter
`timescale 1ns/1ps
`define test
`define VCD
`include "../../src/src_clean_baseline/CPU/stage/ID_stage.v"
module tb_ID_stage;

  // ------------------------
  // DUT ports
  // ------------------------
  reg         clk, rst;
  reg  [31:0] instr;
  reg  [31:0] PC;
  reg  [31:0] WB_data;
  reg  [4:0]  WB_rd;
  reg         WB_control;
  reg  [31:0] FW1_MEM_rs1_data, FW1_MEM_rs2_data;
  reg  [4:0]  EXE_rd, MEM_rd, EXE_frd;
  reg  [7:0]  EXE_opcode, MEM_opcode;
  reg         EXE_load_I, MEM_load_I, EXE_F_load_I;

  wire [31:0] out_rs1_data, out_rs2_data;
  wire        out_load_I, out_F_load_I;
  wire [4:0]  out_rs1, out_rs2, out_rd, out_frs1, out_frs2, out_frd;
  wire [6:0]  out_opcode;
  wire [31:0] out_PC;
  wire [31:0] out_imm;
  wire [2:0]  out_funct3;
  wire [4:0]  out_funct5;
  wire [6:0]  out_funct7;
  wire        out_stall;
  wire        out_BJ_control;
  wire        out_BJ_target; // 實作若為 32-bit，請改為 [31:0]

`ifdef test
  wire [31:0] out_instr;
  wire out_R_type_I, out_I_type_I, out_S_type_I, out_B_type_I, out_J_type_I, out_F_type_I, out_CSR_I;
`endif

  // ------------------------
  // Instantiate DUT
  // ------------------------
  ID_stage ID_stage_u (
    .clk(clk), .rst(rst),
    .instr(instr), .PC(PC),
    .WB_data(WB_data), .WB_rd(WB_rd), .WB_control(WB_control),
    .FW1_MEM_rs1_data(FW1_MEM_rs1_data), .FW1_MEM_rs2_data(FW1_MEM_rs2_data),
    .EXE_rd(EXE_rd), .MEM_rd(MEM_rd), .EXE_frd(EXE_frd),
    .EXE_opcode(EXE_opcode), .MEM_opcode(MEM_opcode),
    .EXE_load_I(EXE_load_I), .MEM_load_I(MEM_load_I), .EXE_F_load_I(EXE_F_load_I)
`ifdef test
    , .out_instr(out_instr),
      .out_R_type_I(out_R_type_I), .out_I_type_I(out_I_type_I),
      .out_S_type_I(out_S_type_I), .out_B_type_I(out_B_type_I),
      .out_J_type_I(out_J_type_I), .out_F_type_I(out_F_type_I), .out_CSR_I(out_CSR_I)
`endif
    , .out_rs1_data(out_rs1_data), .out_rs2_data(out_rs2_data),
      .out_load_I(out_load_I), .out_F_load_I(out_F_load_I),
      .out_rs1(out_rs1), .out_rs2(out_rs2), .out_rd(out_rd),
      .out_frs1(out_frs1), .out_frs2(out_frs2), .out_frd(out_frd),
      .out_opcode(out_opcode), .out_PC(out_PC), .out_imm(out_imm),
      .out_funct3(out_funct3), .out_funct5(out_funct5), .out_funct7(out_funct7),
      .out_stall(out_stall), .out_BJ_control(out_BJ_control), .out_BJ_target(out_BJ_target)
  );
    wire opcode = instr[6:0];
  // ------------------------
  // Clock / Reset
  // ------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz
  end

  task do_reset;
    begin
      rst = 1;
      instr = 32'd0; PC = 32'd0;
      WB_data = 32'd0; WB_rd = 5'd0; WB_control = 1'b0;
      FW1_MEM_rs1_data = 32'd0; FW1_MEM_rs2_data = 32'd0;
      EXE_rd = 5'd0; MEM_rd = 5'd0; EXE_frd = 5'd0;
      EXE_opcode = 8'd0; MEM_opcode = 8'd0;
      EXE_load_I = 1'b0; MEM_load_I = 1'b0; EXE_F_load_I = 1'b0;
      repeat (4) @(posedge clk);
      rst = 0;
      @(posedge clk);
    end
  endtask

  // ------------------------
  // Golden decode helpers
  // ------------------------
  function [6:0] f_opcode(input [31:0] x);  f_opcode = x[6:0];  endfunction
  function [4:0] f_rd    (input [31:0] x);  f_rd     = x[11:7]; endfunction
  function [2:0] f_f3    (input [31:0] x);  f_f3     = x[14:12];endfunction
  function [4:0] f_rs1   (input [31:0] x);  f_rs1    = x[19:15];endfunction
  function [4:0] f_rs2   (input [31:0] x);  f_rs2    = x[24:20];endfunction
  function [6:0] f_f7    (input [31:0] x);  f_f7     = x[31:25];endfunction
  function [4:0] f_f5    (input [31:0] x);  f_f5     = x[31:27];endfunction

  // 依 opcode 決定立即數型別：I/S/B/U/J（RV32）
  // 加入 CSR 與 F-type（FLW/FSW/FPU）的立即數解碼
function [31:0] f_imm(input [31:0] x);
  reg [6:0] op; 
  reg [2:0] f3;
  reg [31:0] imm;
  begin
    op  = x[6:0];
    f3  = x[14:12];
    imm = 32'd0;
    case (op)
      // I-type / Loads / JALR
      7'b0010011,
      7'b0000011,
      7'b1100111: imm = {{20{x[31]}}, x[31:20]};

      // S-type
      7'b0100011: imm = {{20{x[31]}}, x[31:25], x[11:7]};

      // B-type
      7'b1100011: imm = {{19{x[31]}}, x[31], x[7], x[30:25], x[11:8], 1'b0};

      // U-type
      7'b0110111, // LUI
      7'b0010111: // AUIPC
                  imm = {x[31:12], 12'd0};

      // J-type
      7'b1101111: imm = {{11{x[31]}}, x[31], x[19:12], x[20], x[30:21], 1'b0};

      // ---------------- F-type ----------------
      // FLW（0000111）：I-type 立即數
      `F_type_1:  imm = {{20{x[31]}}, x[31:20]};
      // FSW（0100111）：S-type 立即數
      `F_type_2:  imm = {{20{x[31]}}, x[31:25], x[11:7]};
      // FPU ALU（1010011）：無立即數 → 0
      `F_type_3:  imm = 32'd0;

      // ---------------- CSR ----------------
      // opcode=1110011；若為 *I 類（CSRRWI/CSRRSI/CSRRCI），立即數在 rs1(zimm) 欄位，需零擴展；
      // 其他（CSRRW/CSRRS/CSRRC）沒有 ALU 立即數，可回傳 0（或回傳 csr[11:0] 視你設計）。
      `CSR: begin
        if (f3 == 3'b101 || f3 == 3'b110 || f3 == 3'b111) begin
          // *I variants：zimm = x[19:15]（零擴展）
          imm = {27'd0, x[19:15]};
        end else begin
          // 非 *I：無 ALU 立即數（你也可改成 {{20{1'b0}}, x[31:20]} 載回 csr 位址）
          imm = 32'd0;
        end
      end

      default:     imm = 32'd0;
    endcase
    f_imm = imm;
  end
endfunction


  // ------------------------
  // Scoreboard（皆假設經 1 級 DFF；不檢查 out_stall / out_BJ_* 的對齊）
  // ------------------------
  reg [31:0] exp_PC_d1, exp_imm_d1;
  reg [6:0]  exp_opcode_d1, exp_funct7_d1;
  reg [4:0]  exp_rs1_d1, exp_rs2_d1, exp_rd_d1, exp_funct5_d1, exp_frs1_d1, exp_frs2_d1, exp_frd_d1;
  reg [2:0]  exp_funct3_d1;
  reg [31:0] exp_rs1_data_d1, exp_rs2_data_d1;
  reg        exp_load_I_d1, exp_F_load_I_d1;

  task sb_capture_expected_from_instr(input [31:0] dinstr, input [31:0] dPC);
    reg [4:0] r1, r2;
    begin
      exp_PC_d1      <= dPC;
      exp_opcode_d1  <= f_opcode(dinstr);
      exp_rd_d1      <= f_rd(dinstr);
      exp_funct3_d1  <= f_f3(dinstr);
      exp_rs1_d1     <= f_rs1(dinstr);
      exp_rs2_d1     <= f_rs2(dinstr);
      exp_funct7_d1  <= f_f7(dinstr);
      exp_funct5_d1  <= f_f5(dinstr);
      exp_frs1_d1    <= f_rs1(dinstr);
      exp_frs2_d1    <= f_rs2(dinstr);
      exp_frd_d1     <= f_rd(dinstr);
      exp_imm_d1     <= f_imm(dinstr);

      r1 = f_rs1(dinstr);
      r2 = f_rs2(dinstr);
      exp_rs1_data_d1 <= ID_stage_u.RF[r1];
      exp_rs2_data_d1 <= ID_stage_u.RF[r2];

      exp_load_I_d1   <= (f_opcode(dinstr) == 7'b0000011);
      exp_F_load_I_d1 <= (f_opcode(dinstr) == `F_type_1);
    end
  endtask

  task sb_check_outputs_one_cycle;
    begin
        // PC
        if (^exp_PC_d1 !== 1'bx) begin
            if (out_PC !== exp_PC_d1)
            $fatal(1, "PC mismatch: got=%h exp=%h", out_PC, exp_PC_d1);
        end

        // opcode
        if (^exp_opcode_d1 !== 1'bx) begin
            if (out_opcode !== exp_opcode_d1)
            $fatal(1, "opcode mismatch: got=%0h exp=%0h", out_opcode, exp_opcode_d1);
        end

        // rd
        if (^exp_rd_d1 !== 1'bx) begin
            if (out_rd !== exp_rd_d1 && exp_opcode_d1 != `S_type && exp_opcode_d1 != `B_type && exp_opcode_d1 != `F_type_1 && exp_opcode_d1 != `F_type_2 && exp_opcode_d1 != `F_type_3)
            $fatal(1, "rd mismatch: got=%0d exp=%0d", out_rd, exp_rd_d1);
        end

        // funct3
        if (^exp_funct3_d1 !== 1'bx) begin
            if (out_funct3 !== exp_funct3_d1)
            $fatal(1, "funct3 mismatch: got=%0d exp=%0d", out_funct3, exp_funct3_d1);
        end

        // rs1
        if (^exp_rs1_d1 !== 1'bx) begin
            if (out_rs1 !== exp_rs1_d1 && exp_opcode_d1 != `U_type_1 && exp_opcode_d1 != `U_type_2 && exp_opcode_d1 != `J_type && exp_opcode_d1 != `F_type_3)
            $fatal(1, "rs1 mismatch: got=%0d exp=%0d", out_rs1, exp_rs1_d1);
        end

        // rs2
        if (^exp_rs2_d1 !== 1'bx && exp_opcode_d1 != `I_type_1 && exp_opcode_d1 != `I_type_2 && exp_opcode_d1 != `I_type_3 && exp_opcode_d1 != `J_type && exp_opcode_d1 != `F_type_1 && exp_opcode_d1 != `F_type_2 && exp_opcode_d1 != `F_type_3 && exp_opcode_d1 != `CSR) begin
            if (out_rs2 !== exp_rs2_d1 && exp_opcode_d1 != `U_type_1 && exp_opcode_d1 != `U_type_2)
            $fatal(1, "rs2 mismatch: got=%0d exp=%0d", out_rs2, exp_rs2_d1);
        end

        // funct7
        if (^exp_funct7_d1 !== 1'bx) begin
            if (out_funct7 !== exp_funct7_d1)
            $fatal(1, "funct7 mismatch: got=%0h exp=%0h", out_funct7, exp_funct7_d1);
        end

        // funct5
        if (^exp_funct5_d1 !== 1'bx) begin
            if (out_funct5 !== exp_funct5_d1)
            $fatal(1, "funct5 mismatch: got=%0h exp=%0h", out_funct5, exp_funct5_d1);
        end

        // F-type 檢查（只有 exp_opcode_d1 == F-type 且不是 x 才比對）
        if (exp_opcode_d1 == 7'b1010011 && ^exp_frs1_d1 !== 1'bx) begin
            if (out_frs1 !== exp_frs1_d1)
            $fatal(1, "frs1 mismatch: got=%0d exp=%0d", out_frs1, exp_frs1_d1);
            if (out_frs2 !== exp_frs2_d1)
            $fatal(1, "frs2 mismatch: got=%0d exp=%0d", out_frs2, exp_frs2_d1);
            if (out_frd !== exp_frd_d1)
            $fatal(1, "frd mismatch: got=%0d exp=%0d", out_frd, exp_frd_d1);
        end else if (exp_opcode_d1 != 7'b1010011) begin
            if (out_frs1 !== 5'd0) $fatal(1, "frs1 should be 0 for non-F-type: got=%0d", out_frs1);
            if (out_frs2 !== 5'd0 && exp_opcode_d1 != `F_type_2) $fatal(1, "frs2 should be 0 for non-F-type: got=%0d", out_frs2);
            if (out_frd !== 5'd0 && exp_opcode_d1 != `F_type_1)  $fatal(1, "frd should be 0 for non-F-type:  got=%0d", out_frd);
        end

        // imm
        if (^exp_imm_d1 !== 1'bx) begin
            if (out_imm !== exp_imm_d1 && exp_opcode_d1 != `CSR)
            $fatal(1, "imm mismatch: got=%h exp=%h", out_imm, exp_imm_d1);
        end

        // rs1_data
        if (^exp_rs1_data_d1 !== 1'bx) begin
            if (out_rs1_data !== exp_rs1_data_d1 && exp_opcode_d1 != `U_type_1 && exp_opcode_d1 != `U_type_2 && exp_opcode_d1 != `J_type)
            $fatal(1, "rs1_data mismatch: got=%h exp=%h", out_rs1_data, exp_rs1_data_d1);
        end

        // rs2_data
        if (^exp_rs2_data_d1 !== 1'bx && exp_opcode_d1 != `I_type_1 && exp_opcode_d1 != `I_type_2 && exp_opcode_d1 != `I_type_3  && exp_opcode_d1 != `U_type_1 && exp_opcode_d1 != `U_type_2  && exp_opcode_d1 != `J_type && exp_opcode_d1 != `F_type_1 && exp_opcode_d1 != `CSR) begin
            if (out_rs2_data !== exp_rs2_data_d1)
            $fatal(1, "rs2_data mismatch: got=%h exp=%h", out_rs2_data, exp_rs2_data_d1);
        end

        // load_I
        if (^exp_load_I_d1 !== 1'bx) begin
            if (out_load_I !== exp_load_I_d1)
            $fatal(1, "load_I mismatch: got=%0b exp=%0b", out_load_I, exp_load_I_d1);
        end

        // F_load_I
        if (^exp_F_load_I_d1 !== 1'bx) begin
            if (out_F_load_I !== exp_F_load_I_d1)
            $fatal(1, "F_load_I mismatch: got=%0b exp=%0b", out_F_load_I, exp_F_load_I_d1);
        end
        
          // ---- F-type 解碼旗標檢查 ----
        if (is_F_type(exp_opcode_d1)) begin
            // 期望 DUT 宣告為 F 類
            if (out_F_type_I !== 1'b1)
            $fatal(1, "F_type decode mismatch: expect out_F_type_I=1 (opcode=%0b)", exp_opcode_d1);
            // 非 F 類旗標應為 0（視你的設計而定，可保留/移除）
            if (out_CSR_I === 1'b1)
            $fatal(1, "F_type decode clash: out_CSR_I should be 0 for F-type");
        end else begin
            // 非 F 類時，F 旗標應為 0（若期望值未知就略過）
            if (out_F_type_I !== 1'b0)
            $fatal(1, "Non-F opcode but out_F_type_I=1 (opcode=%0b)", exp_opcode_d1);
        end

        // ---- CSR 解碼旗標檢查 ----
        if (is_CSR_type(exp_opcode_d1)) begin
            if (out_CSR_I !== 1'b1)
            $fatal(1, "CSR decode mismatch: expect out_CSR_I=1 (opcode=%0b)", exp_opcode_d1);
            if (out_F_type_I === 1'b1)
            $fatal(1, "CSR decode clash: out_F_type_I should be 0 for CSR");
        end else begin
            if (out_CSR_I !== 1'b0)
            $fatal(1, "Non-CSR opcode but out_CSR_I=1 (opcode=%0b)", exp_opcode_d1);
        end
    end

  endtask
// ------------------------
// 設定 RF 初值
// ------------------------
task set_RF_default_pattern;
    integer i;
    begin
    for (i=0; i<32; i=i+1) begin
        ID_stage_u.RF[i] = {24'hA5A5A5, i[7:0]}; // 0xA5A5A5ii
        ID_stage_u.F_RF[i] = {24'hA5A5A5, i[7:0]}; // 0xA5A5A5ii
    end
    ID_stage_u.RF[0] = 32'd0; // x0 永遠 0
    @(posedge clk);
    end
endtask

`ifdef basic
    // ------------------------
    // TASK 1：正緣送資料（PC 與 instr 同拍），兩拍後檢查
    // ------------------------
    reg [31:0] pc_drive; // 正緣要送出的 PC 值（與 instr 同步）

    task task1_decode_and_timing_alignment;
        reg [31:0] vec_instr [0:7];
        integer k;
        begin
        $display("\n[task1] start");
        set_RF_default_pattern;

        // 測資
        vec_instr[0] = 32'b0000000_00010_00001_000_00011_0110011; // R: ADD x3,x1,x2
        vec_instr[1] = {20'd10, 5'd1, 3'b000, 5'd5, 7'b0010011};  // I: ADDI x5,x1,10
        vec_instr[2] = {7'b0000000, 5'd5, 5'd1, 3'b010, 5'b00100, 7'b0100011}; // S: SW x5,4(x1)
        vec_instr[3] = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b0100, 1'b0, 7'b1100011}; // B: BEQ x1,x2,+8
        vec_instr[4] = {20'h12345, 5'd7, 7'b0110111}; // U: LUI x7, 0x12345
        vec_instr[5] = {20'h56789, 5'd8, 7'b0010111}; // U: AUIPC x8, 0x56789
        vec_instr[6] = 32'h0100006F;                  // J: JAL x0,+16
        vec_instr[7] = {20'd12, 5'd1, 3'b000, 5'd10, 7'b1100111}; // I: JALR x10,x1,12

        // 初始化 pc_drive
        pc_drive = 32'h1000_0000;

        // 逐筆：在同一個正緣送出 instr/PC，並以同一拍的 pc_drive 擷取期望
        for (k=0; k<8; k=k+1) begin
            @(posedge clk);
            instr   <= vec_instr[k];
            PC      <= pc_drive;
            sb_capture_expected_from_instr(vec_instr[k], pc_drive);
            pc_drive <= pc_drive + 32'd4;

            // 兩拍後檢查（因為：正緣送 → 下個正緣才被 DUT 取到 → 再因 1 級 DFF 延遲一拍輸出）
            @(posedge clk);
            @(posedge clk);
            sb_check_outputs_one_cycle();
            $display("[task1] vec %0d OK", k);
        end

        $display("[task1] done\n");
        end
    endtask
`else
    // ============================================================================
    // R-type funct7/funct3：以 localparam 取代原本的 `ADD[9:3] / [2:0] 用法
    // ============================================================================
    localparam [6:0] FUNCT7_ADD   = 7'b0000000; localparam [2:0] FUNCT3_ADD   = 3'b000;
    localparam [6:0] FUNCT7_SUB   = 7'b0100000; localparam [2:0] FUNCT3_SUB   = 3'b000;
    localparam [6:0] FUNCT7_SLL   = 7'b0000000; localparam [2:0] FUNCT3_SLL   = 3'b001;
    localparam [6:0] FUNCT7_SLT   = 7'b0000000; localparam [2:0] FUNCT3_SLT   = 3'b010;
    localparam [6:0] FUNCT7_SLTU  = 7'b0000000; localparam [2:0] FUNCT3_SLTU  = 3'b011;
    localparam [6:0] FUNCT7_XOR   = 7'b0000000; localparam [2:0] FUNCT3_XOR   = 3'b100;
    localparam [6:0] FUNCT7_SRL   = 7'b0000000; localparam [2:0] FUNCT3_SRL   = 3'b101;
    localparam [6:0] FUNCT7_SRA   = 7'b0100000; localparam [2:0] FUNCT3_SRA   = 3'b101;
    localparam [6:0] FUNCT7_OR    = 7'b0000000; localparam [2:0] FUNCT3_OR    = 3'b110;
    localparam [6:0] FUNCT7_AND   = 7'b0000000; localparam [2:0] FUNCT3_AND   = 3'b111;

    // M-extension
    localparam [6:0] FUNCT7_MUL   = 7'b0000001; localparam [2:0] FUNCT3_MUL   = 3'b000;
    localparam [6:0] FUNCT7_MULH  = 7'b0000001; localparam [2:0] FUNCT3_MULH  = 3'b001;
    localparam [6:0] FUNCT7_MULHSU= 7'b0000001; localparam [2:0] FUNCT3_MULHSU= 3'b010;
    localparam [6:0] FUNCT7_MULHU = 7'b0000001; localparam [2:0] FUNCT3_MULHU = 3'b011;
    // ==== CSR 常數（地址與 funct3）====
    localparam [11:0] CSR_ADDR_CYCLE   = 12'hC00; // RDCYCLE   下半
    localparam [11:0] CSR_ADDR_CYCLEH  = 12'hC80; // RDCYCLEH  上半
    localparam [11:0] CSR_ADDR_INSTRET = 12'hC02; // RDINSTRET 下半
    localparam [11:0] CSR_ADDR_INSTRETH= 12'hC82; // RDINSTRETH上半

    localparam [2:0] FUNCT3_CSRRW  = 3'b001;
    localparam [2:0] FUNCT3_CSRRS  = 3'b010;
    localparam [2:0] FUNCT3_CSRRC  = 3'b011;
    localparam [2:0] FUNCT3_CSRRWI = 3'b101;
    localparam [2:0] FUNCT3_CSRRSI = 3'b110;
    localparam [2:0] FUNCT3_CSRRCI = 3'b111;
    localparam [4:0] FUNCT5_FADD = 5'b00000;
    localparam [4:0] FUNCT5_FSUB = 5'b00001;


    // ============================================================================
    // 指令組碼 helper
    // ============================================================================
    function [31:0] enc_R(
    input [6:0] funct7, input [4:0] rs2, input [4:0] rs1,
    input [2:0] funct3, input [4:0] rd, input [6:0] opcode
    );
    enc_R = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function [31:0] enc_I(
    input [11:0] imm12, input [4:0] rs1,
    input [2:0] funct3, input [4:0] rd, input [6:0] opcode
    );
    enc_I = {{20{imm12[11]}}, imm12, rs1, funct3, rd, opcode};
    endfunction

    // I-type shift（SLLI/SRLI/SRAI）
    function [31:0] enc_I_shift(
    input [6:0] funct7, input [4:0] shamt, input [4:0] rs1,
    input [2:0] funct3, input [4:0] rd, input [6:0] opcode
    );
    enc_I_shift = {funct7, shamt, rs1, funct3, rd, opcode};
    endfunction

    function [31:0] enc_S(
    input [11:0] imm12, input [4:0] rs2, input [4:0] rs1,
    input [2:0] funct3, input [6:0] opcode
    );
    enc_S = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
    endfunction

    // imm13 是含 LSB=0 的分支位移（例如 +16 就填 13'd16）
    function [31:0] enc_B(
    input [12:0] imm13, input [4:0] rs2, input [4:0] rs1,
    input [2:0] funct3, input [6:0] opcode
    );
    enc_B = { imm13[12], imm13[10:5], rs2, rs1, funct3, imm13[4:1], imm13[11], opcode };
    endfunction

    function [31:0] enc_U(
    input [19:0] imm20, input [4:0] rd, input [6:0] opcode
    );
    enc_U = {imm20, rd, opcode};
    endfunction

    // imm21 是含 LSB=0 的 J 位移（例如 +32 就填 21'd32）
    function [31:0] enc_J(
    input [20:0] imm21, input [4:0] rd, input [6:0] opcode
    );
    enc_J = { imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opcode };
    endfunction

    // FADD.S/FSUB.S（{funct5,opcode}；rm 先給 0）
    function [31:0] enc_Fop5(
    input [4:0] funct5, input [4:0] rs2, input [4:0] rs1,
    input [2:0] rm, input [4:0] rd, input [6:0] opcode
    );
    enc_Fop5 = {funct5, 2'b00, rs2, rs1, rm, rd, opcode};
    endfunction

    // CSR（Zicsr）
    function [31:0] enc_CSR(
    input [11:0] csr, input [4:0] rs1_or_uimm,
    input [2:0] funct3, input [4:0] rd
    );
    enc_CSR = {csr, rs1_or_uimm, funct3, rd, `CSR};
    endfunction

    // ==== 型別判斷（依你先前的 opcode 巨集）====
    function is_F_type(input [6:0] op);
    begin
        is_F_type = (op == `F_type_1) || (op == `F_type_2) || (op == `F_type_3);
    end
    endfunction

    function is_CSR_type(input [6:0] op);
    begin
        is_CSR_type = (op == `CSR);
    end
    endfunction

    // ============================================================================
    // 擴充版 task1：正緣送資料（PC 同步），兩拍後檢查
    // ============================================================================
    reg [31:0] pc_drive;

    task task1_decode_and_timing_alignment;
    localparam VEC_N = 37;
    reg [31:0] vec_instr [0:VEC_N-1];
    integer k;
    begin
        $display("\n[task1: new with localparam] start");
        set_RF_default_pattern;

        // ---------------- R-type（含 M 擴充） ----------------
        vec_instr[0]  = enc_R(FUNCT7_ADD,   5'd2,  5'd1, FUNCT3_ADD,   5'd3,  `R_type);
        vec_instr[1]  = enc_R(FUNCT7_SUB,   5'd4,  5'd3, FUNCT3_SUB,   5'd5,  `R_type);
        vec_instr[2]  = enc_R(FUNCT7_SLL,   5'd6,  5'd5, FUNCT3_SLL,   5'd7,  `R_type);
        vec_instr[3]  = enc_R(FUNCT7_SLT,   5'd8,  5'd7, FUNCT3_SLT,   5'd9,  `R_type);
        vec_instr[4]  = enc_R(FUNCT7_SLTU,  5'd10, 5'd9, FUNCT3_SLTU,  5'd11, `R_type);
        vec_instr[5]  = enc_R(FUNCT7_XOR,   5'd12, 5'd11,FUNCT3_XOR,   5'd13, `R_type);
        vec_instr[6]  = enc_R(FUNCT7_SRL,   5'd14, 5'd13,FUNCT3_SRL,   5'd15, `R_type);
        vec_instr[7]  = enc_R(FUNCT7_SRA,   5'd16, 5'd15,FUNCT3_SRA,   5'd17, `R_type);
        vec_instr[8]  = enc_R(FUNCT7_OR,    5'd18, 5'd17,FUNCT3_OR,    5'd19, `R_type);
        vec_instr[9]  = enc_R(FUNCT7_AND,   5'd20, 5'd19,FUNCT3_AND,   5'd21, `R_type);
        vec_instr[10] = enc_R(FUNCT7_MUL,   5'd2,  5'd1, FUNCT3_MUL,   5'd22, `R_type);
        vec_instr[11] = enc_R(FUNCT7_MULH,  5'd4,  5'd3, FUNCT3_MULH,  5'd23, `R_type);

        // ---------------- I-type（算術/邏輯/Load/JALR） ----------------
        vec_instr[12] = enc_I(12'sd10, 5'd1, 3'b000, 5'd5,  `I_type_2); // ADDI
        vec_instr[13] = enc_I(12'sd3, 5'd5,  3'b010, 5'd6,  `I_type_2); // SLTI
        vec_instr[14] = enc_I(12'sd7,  5'd6,  3'b100, 5'd7,  `I_type_2); // XORI
        vec_instr[15] = enc_I(12'sd5,  5'd7,  3'b110, 5'd8,  `I_type_2); // ORI
        vec_instr[16] = enc_I(12'sd9,  5'd8,  3'b111, 5'd9,  `I_type_2); // ANDI
        vec_instr[17] = enc_I(12'sd16, 5'd1,  3'b010, 5'd10, `I_type_1); // LW
        vec_instr[18] = enc_I(12'sd4,  5'd2,  3'b001, 5'd11, `I_type_1); // LH
        vec_instr[19] = enc_I(12'sd3,  5'd3,  3'b100, 5'd12, `I_type_1); // LBU
        vec_instr[20] = enc_I(12'sd12, 5'd1,  3'b000, 5'd13, `I_type_3); // JALR

        // ---------------- I-shift ----------------
        vec_instr[21] = enc_I_shift(7'b0000000, 5'd3, 5'd5, 3'b001, 5'd6, `I_type_2); // SLLI x6,x5,3
        vec_instr[22] = enc_I_shift(7'b0000000, 5'd4, 5'd6, 3'b101, 5'd7, `I_type_2); // SRLI x7,x6,4
        vec_instr[23] = enc_I_shift(7'b0100000, 5'd5, 5'd7, 3'b101, 5'd8, `I_type_2); // SRAI x8,x7,5

        // ---------------- S-type ----------------
        vec_instr[24] = enc_S(12'sd8,  5'd10, 5'd2, 3'b000, `S_type); // SB
        vec_instr[25] = enc_S(12'sd12, 5'd11, 5'd3, 3'b001, `S_type); // SH
        vec_instr[26] = enc_S(12'sd16, 5'd12, 5'd4, 3'b010, `S_type); // SW

        // ---------------- B-type（imm13 = 含 LSB=0 的位移） ----------------
        vec_instr[27] = enc_B(13'd16, 5'd1, 5'd2, 3'b000, `B_type); // BEQ +16
        // 你也可再加：BNE/BLT/BGE/BLTU/BGEU

        // ---------------- U/J-type ----------------
        vec_instr[28] = enc_U(20'h12345, 5'd7, `U_type_2);         // LUI x7, 0x12345
        vec_instr[29] = enc_U(20'h56789, 5'd8, `U_type_1);         // AUIPC x8, 0x56789
        vec_instr[30] = enc_J(21'd32,    5'd0, `J_type);           // JAL x0, +32

        // ---------------- F/CSR（可選擇是否打開） ----------------
         vec_instr[31] = enc_CSR(CSR_ADDR_CYCLE, 5'd0, FUNCT3_CSRRS, 5'd5); // csrrs x5,cycle,x0
        // 若要加 F 指令，請同時確保 scoreboard 的 F-type 條件（只在 F-type 檢查 frs1/2/rd）
        // F-type 載入/存儲
        vec_instr[32] = enc_I(12'sd20, 5'd1, 3'b010, 5'd10, `F_type_1); // FLW  f10,20(x1)  （視你的設計，rd/rs1/rs2 對應 frd/frs*）
        vec_instr[33] = enc_S(12'sd24, 5'd10,5'd2, 3'b010, `F_type_2);  // FSW  f10,24(x2)

        // FADD.S / FSUB.S（rm=3'b000）
        vec_instr[34] = enc_Fop5(FUNCT5_FADD, 5'd2, 5'd1, 3'b000, 5'd3, `F_type_3); // FADD.S f3,f1,f2
        vec_instr[35] = enc_Fop5(FUNCT5_FSUB, 5'd4, 5'd3, 3'b000, 5'd5, `F_type_3); // FSUB.S f5,f3,f4

        // CSR 再多一筆：csrrw x6, instret, x0
        vec_instr[36] = enc_CSR(CSR_ADDR_INSTRET, 5'd0, FUNCT3_CSRRW, 5'd6);

        // ---------------- 送測：正緣送資料（PC 同步），兩拍後檢查 ----------------
        pc_drive = 32'h1000_0000;
        for (k = 0; k < VEC_N; k = k + 1) begin
        @(posedge clk);
        instr   <= vec_instr[k];
        PC      <= pc_drive;
        sb_capture_expected_from_instr(vec_instr[k], pc_drive);
        pc_drive <= pc_drive + 32'd4;

        @(posedge clk);
        @(posedge clk);
        sb_check_outputs_one_cycle();
        $display("[task1-new] vec %0d OK (PC=%h, instr=%h)", k, out_PC, `ifdef test out_instr `else instr `endif);
        end

        $display("[task1: new with localparam] done\n");
    end
    endtask

`endif 
  // ------------------------
  // TASK 2：功能驗證（正緣送資料；兩拍後檢查）
  // ------------------------
  task task2_functional_RF_branch_hazard;
    reg [31:0] beq_instr, addi_instr, lw_instr;
    begin
      $display("\n[task2] start");
      set_RF_default_pattern;

      // 覆蓋特定暫存器值
      ID_stage_u.RF[1] = 32'd10; // x1
      ID_stage_u.RF[2] = 32'd20; // x2
      ID_stage_u.RF[3] = 32'd30; // x3
      //$display("%d\n", ID_stage_u.RF[1]);
      //$display("%d\n", ID_stage_u.RF[2]);
      //$display("%d\n", ID_stage_u.RF[3]);
      @(posedge clk);

      // A: BEQ 不成立
      beq_instr = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b0100, 1'b0, 7'b1100011};
      WB_data = 32'd0; WB_rd = 5'd0; WB_control = 1'b0;
      FW1_MEM_rs1_data = 32'd0; FW1_MEM_rs2_data = 32'd0;
      EXE_load_I = 1'b0; MEM_load_I = 1'b0; EXE_F_load_I = 1'b0;
      EXE_rd = 5'd0; MEM_rd = 5'd0; EXE_opcode = 8'd0; MEM_opcode = 8'd0;

      @(posedge clk);
      instr   <= beq_instr;
      PC      <= 32'h2000_0000;
      sb_capture_expected_from_instr(beq_instr, 32'h2000_0000);
      @(posedge clk);
      @(posedge clk);
      if (out_BJ_control !== 1'b0) $fatal(2, "[task2.A] BEQ should NOT be taken");
      $display("[task2.A] branch detector (not taken) OK");

      // B: BEQ + MEM forward（讓 rs2 變 10 → 成立）
      FW1_MEM_rs2_data = 32'd10;
      MEM_opcode = `R_type;
      MEM_rd = 5'd2;

      @(posedge clk);
      instr   <= beq_instr;
      PC      <= 32'h2000_0004;
      sb_capture_expected_from_instr(beq_instr, 32'h2000_0004);
      @(posedge clk);
      @(posedge clk);
      if (out_BJ_control !== 1'b1) $fatal(2, "[task2.B] BEQ should be taken due to MEM forward");
      $display("[task2.B] branch detector with MEM forward OK");
      FW1_MEM_rs2_data = 32'd0;

      // C: Hazard detect（EXE 正在 load → 下一條使用該 rd）
      // 第1條：lw x1,0(x2)
      lw_instr = {12'd0, 5'd2, 3'b010, 5'd1, 7'b0000011};

      @(posedge clk);
      instr   <= lw_instr;
      PC      <= 32'h2000_0008;
      sb_capture_expected_from_instr(lw_instr, 32'h2000_0008);
      EXE_load_I <= 1'b1; EXE_rd <= 5'd1;

      // 下一條：ADDI x3,x1,1（使用 x1）
      addi_instr = {20'd1, 5'd1, 3'b000, 5'd3, 7'b0010011};
      @(posedge clk);
      instr   <= addi_instr;
      PC      <= 32'h2000_000C;
      sb_capture_expected_from_instr(addi_instr, 32'h2000_000C);
      EXE_load_I <= 1'b1; EXE_rd <= 5'd1;

      //@(posedge clk);
      @(posedge clk);
      if (out_stall !== 1'b1) $fatal(2, "[task2.C] expected out_stall=1 for load-use hazard");
      $display("[task2.C] hazard detect (load-use) OK");

      // 清除 hazard，檢查解除
      EXE_load_I <= 1'b0; EXE_rd <= 5'd0;
      @(posedge clk);
      @(posedge clk);
      if (out_stall !== 1'b0) $fatal(2, "[task2.C] expected out_stall=0 after hazard cleared");
      $display("[task2.C] hazard cleared OK");

      $display("[task2] done\n");
    end
  endtask

  // ------------------------
  // Test sequence
  // ------------------------
  initial begin
    do_reset;

    // Task 1：解碼＋時序 DFF 對齊（正緣送，兩拍後檢查）
    task1_decode_and_timing_alignment;
    

    // Task 2：RF 初值 + branch / forward / hazard（正緣送，兩拍後檢查）
    task2_functional_RF_branch_hazard;

    $display("ALL TESTS PASSED.");
    #20 $finish;
  end

`ifdef VCD
  initial begin
    $dumpfile("ID_stage.vcd");
    $dumpvars();
    //$fsdbDumpvars("+struct", "+mda", tb);
  end
`endif
endmodule
