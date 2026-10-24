//////////////////////////////////////////////////////////////////////
//          ██╗       ██████╗   ██╗  ██╗    ██████╗            		//
//          ██║       ██╔══█║   ██║  ██║    ██╔══█║            		//
//          ██║       ██████║   ███████║    ██████║            		//
//          ██║       ██╔═══╝   ██╔══██║    ██╔═══╝            		//
//          ███████╗  ██║  	    ██║  ██║    ██║  	           		//
//          ╚══════╝  ╚═╝  	    ╚═╝  ╚═╝    ╚═╝  	           		//
//                                                             		//
// 	2025 Advanced VLSI System Design, Advisor: Lih-Yih, Chiou		//
//                                                             		//
//////////////////////////////////////////////////////////////////////
//                                                             		//
// 	Author: 		                           				  	    //
//	Filename:		top.sv		                                    //
//	Description:	top module for AVSD HW1                     	//
// 	Date:			2025/XX/XX								   		//
// 	Version:		1.0	    								   		//
//////////////////////////////////////////////////////////////////////
//`define test
//`define monitor
`define top_mem
`define top_sim
`define low_power_mode
`define interrupt_EN
//`define predict
//`define FALU_stall
`define BJ_forward
`ifdef predict
  `define  predictor_2b
	`include "predict.v"
`endif
`define AXI
//`define spyglass
//`define CSR_virtual_space
//`define behavior_MEM





// `include "./CPU/define_list.v"
// //`include "./CPU/SRAM_wrapper.sv"
// `include "./CPU/IF_stage.v"
// `include "./CPU/ID_stage.v"
// `include "./CPU/EXE_stage.v"
// `include "./CPU/MEM_stage.v"
// `include "./CPU/WB_stage.v"
`ifdef test
`ifdef monitor
    `include "monitor.sv"
`endif 
`endif 

module CPU(
input clk,
input rst
`ifdef	AXI
, 
output    [31:0] PC,
input   stall_IM,
input   [31:0] instr,
`ifdef interrupt_EN
input stall_wfi,
input MEIP, MTIP, MSIP,
input SEIP, STIP, SSIP,
input UEIP, UTIP, USIP,
output  interrupt,
output  EXE_detect_wfi,
input   CPU_restore_pulse,
`endif
`ifdef cache
output [31:0] EXE_I_result,
output        EXE_MEM_use,
`endif
output   [31:0] store_data,
output   [31:0] Addr,
output   [31:0] BWEB,
output 	WEB,
output	CEB,
input   stall_DM,
input   [31:0] read_data
`ifdef CPU_PG
    ,
    input CPU_CG
`endif 
`endif
);

//****************************************************************************************************
//                                      define
//****************************************************************************************************
// =========================
//      global control
// =========================
//wire interrupt;
wire [31:0] interrupt_mtvec;
wire [31:0] CSR_mip;
wire global_stall;
wire [31:0] out_mepc;
wire out_MRET;
`ifdef interrupt_EN
`else
wire MEIP=0, MTIP=0, MSIP=0;
wire SEIP=0, STIP=0, SSIP=0;
wire UEIP=0, UTIP=0, USIP=0;
`endif


// --------------------------//
//      outside mem
// --------------------------//
`ifdef top_mem
    wire  dcache_low_Eable;
    wire  dcache_WR;
    wire [31:0] dcache_hidden_map;
    wire [15:0] dcache_EXE_result_16;
    wire [31:0] dcache_store_data;
    wire [31:0] dcache_read_data;
    wire [15:0] icache_PC_counter_16;
    wire [31:0] icache_instr;
    wire [31:0] Addr32;
    wire [31:0] dcache_EXE_result;
    wire [31:0] icache_PC_counter;

`endif

  // =========================
  // IF → ID
  // =========================
  wire [31:0] ID_instr;
  wire [31:0] ID_PC;
  wire 		  ID_invalid;
  wire        stall;
  wire [31:0] BJ_target;  

  `ifdef predict
    wire  ID_J_type;
    wire  ID_B_result;
    wire  ID_predict_error;
  `else
    wire  BJ_control;
  `endif


  // =========================
  // ID → EXE（依規則命名 EXE_*）
  // =========================
  wire [31:0] EXE_rs1_data, EXE_rs2_data;
  wire        EXE_load_I, EXE_F_load_I;
  wire [4:0]  EXE_rs1, EXE_rs2, EXE_rd, EXE_frs1, EXE_frs2, EXE_frd;
  wire [6:0]  EXE_opcode;
  wire [31:0] EXE_PC;
  wire [31:0] EXE_imm;
  wire [2:0]  EXE_funct3;
  wire [4:0]  EXE_funct5;
  wire [6:0]  EXE_funct7;

`ifdef test
  wire [31:0] EXE_instr;
  wire        EXE_R_type_I, EXE_I_type_I, EXE_S_type_I, EXE_B_type_I, EXE_J_type_I, EXE_F_type_I, EXE_CSR_I;
`endif

  // =========================
  // EXE → MEM
  // =========================
  wire [31:0] MEM_result, MEM_store_data;
  wire        MEM_load_I, MEM_F_load_I;
  wire [4:0]  MEM_rd, MEM_frd;
  wire [2:0]  MEM_funct3;
  wire [6:0]  MEM_opcode;
  wire        MEM_WB_control, MEM_F_WB_control, MEM_store_I, MEM_F_operation;

`ifdef test
  wire [31:0] MEM_instr;
  wire        MEM_R_type_I, MEM_I_type_I, MEM_S_type_I, MEM_B_type_I, MEM_J_type_I, MEM_F_type_I, MEM_CSR_I;
  wire [31:0] MEM_PC;
  wire [4:0]  MEM_funct5_dbg;
  wire [6:0]  MEM_funct7_dbg;
`endif

  // =========================
  // MEM → WB
  // =========================
  wire [31:0] WB_result;
  wire        WB_WB_control, WB_F_WB_control;
  wire [4:0]  WB_rd, WB_frd;

`ifdef test
  wire [31:0] WB_instr;
  wire        WB_R_type_I, WB_I_type_I, WB_S_type_I, WB_B_type_I, WB_J_type_I, WB_F_type_I, WB_CSR_I;
  wire [31:0] WB_PC;
  wire [2:0]  WB_funct3;
  wire [4:0]  WB_funct5;
  wire [6:0]  WB_funct7;
  wire        WB_load_I, WB_F_load_I;
  wire [6:0]  WB_opcode;
  wire        WB_store_I;
`endif

  // =========================
  // WB → 回饋 ID (寫回端口)
  // =========================
  wire [31:0] WB_out_result;
  wire [4:0]  WB_out_rd, WB_out_frd;
  wire        WB_out_WB_control, WB_out_F_WB_control;

  wire [4:0] FW_PWB_rd, FW_PWB_frd;
  wire FW_PWB_WB_control, FW_PWB_F_WB_control;
  wire [31:0] FW_PWB_result;

//****************************************************************************************************
//                                      instance
//****************************************************************************************************
// =========================
//      global control
// =========================

assign CSR_mip[11:0] = {MEIP, 1'd0, SEIP, UEIP, MTIP, 1'd0, STIP, UTIP, MSIP, 1'd0, SSIP, USIP};

// --------------------------//
//      outside mem
// --------------------------//
`ifdef top_mem
	`ifdef	AXI
	`else 
    SRAM_wrapper DM1(
        .CLK(clk),
        .RST(rst),
        .CEB(dcache_low_Eable),
        .WEB(dcache_WR),
        .BWEB(dcache_hidden_map),
        .A(dcache_EXE_result_16),
        .DI(dcache_store_data),
        .DO(dcache_read_data)
    );
    SRAM_wrapper IM1(
      .CLK(clk),
      .RST(rst),
      .CEB(1'b0),
      .WEB(1'b1),
      .BWEB(32'b0),
      .A(icache_PC_counter_16),
      .DI(32'b0),
      .DO(icache_instr)
    );
`endif
`ifdef AXI
	assign icache_instr = instr;
	//assign PC = {16'd0 ,icache_PC_counter_16}; 
  assign PC = icache_PC_counter;

	assign store_data 	= dcache_store_data;
	assign Addr 		= Addr32;
	assign BWEB 		= dcache_hidden_map; 
	assign WEB 			= dcache_WR;
  assign CEB      = dcache_low_Eable;
	assign dcache_read_data 	= read_data;
	assign global_stall	= stall_IM | stall_DM;
`else
  assign global_stall	= 1'd0;
`endif
`endif
  // =======================
  // IF_stage
  // =======================
  IF_stage u_if (
    .global_stall(global_stall || stall_wfi),
    .interrupt(interrupt),
    .interrupt_mtvec(interrupt_mtvec),
    .stall_wfi(stall_wfi),
    `ifdef predict
      .ID_J_type(ID_J_type),
      .ID_B_result(ID_B_result),
      .ID_predict_error(ID_predict_error),
    `else
    .BJ_control (BJ_control),
    `endif
    .BJ_target  (BJ_target),
	  .stall      (stall),
    .clk        (clk),
    .rst        (rst),
	  .out_invalid	(ID_invalid),
    .out_instr      (ID_instr),
    .out_PC         (ID_PC)
    `ifdef top_mem
    ,
    .icache_PC_counter_16(icache_PC_counter_16),
    .icache_PC_counter(icache_PC_counter),
    .icache_instr(icache_instr)
    `endif
    `ifdef CPU_PG
    , .CPU_CG(CPU_CG)
    `endif 

  );


  // =======================
  // ID_stage
  // =======================
  ID_stage u_id (
    .clk        (clk),
    .rst        (rst),

    // from IF
    .in_instr      (ID_instr),
    .PC         (ID_PC),
	.invalid	(ID_invalid),
	.global_stall	(global_stall),
  .stall_wfi(stall_wfi),
  .interrupt(interrupt),
  .out_MRET(out_MRET),
  .in_mepc(out_mepc),   //need exe stage forward when exe csr write


    // from WB（回饋）
    .WB_data      (WB_out_result),
    .WB_rd        (WB_out_rd),
    .WB_control   (WB_out_WB_control),
    .F_WB_data      (WB_out_result),      // 浮點寫回資料共用 result 匯流排（依你架構可再分離）
    .WB_frd       (WB_out_frd),
    .F_WB_control (WB_out_F_WB_control),

    // forward for branch detector（來自 MEM，這裡直接用 MEM 結果）
    .FW1_MEM_rd_data (MEM_result),

    // hazard inputs：EXE 階段
    .EXE_rd      (EXE_rd),
    .MEM_rd      (MEM_rd),
    .EXE_frd     (EXE_frd),
    .EXE_opcode  (EXE_opcode),          // EXE out 是 7-bit，ID 需要 8-bit
    .MEM_load_I  (MEM_load_I),
	.MEM_F_load_I(MEM_F_load_I),
    .EXE_load_I  (EXE_load_I),
    .EXE_F_load_I(EXE_F_load_I),
    .MEM_F_operation(MEM_F_operation)

`ifdef test
   , .out_instr     (EXE_instr),
     .out_R_type_I  (EXE_R_type_I),
     .out_I_type_I  (EXE_I_type_I),
     .out_S_type_I  (EXE_S_type_I),
     .out_B_type_I  (EXE_B_type_I),
     .out_J_type_I  (EXE_J_type_I),
     .out_F_type_I  (EXE_F_type_I),
     .out_CSR_I     (EXE_CSR_I)
`endif

   , .out_rs1_data (EXE_rs1_data),
     .out_rs2_data (EXE_rs2_data),
     .out_load_I   (EXE_load_I),
     .out_F_load_I (EXE_F_load_I),
     .out_rs1      (EXE_rs1),
     .out_rs2      (EXE_rs2),
     .out_rd       (EXE_rd),
     .out_frs1     (EXE_frs1),
     .out_frs2     (EXE_frs2),
     .out_frd      (EXE_frd),
     .out_opcode   (EXE_opcode),
     .out_PC       (EXE_PC),
     .out_imm      (EXE_imm),
     .out_funct3   (EXE_funct3),
     .out_funct5   (EXE_funct5),
     .out_funct7   (EXE_funct7),
     .out_stall    (stall),
`ifdef predict
	.ID_J_type(ID_J_type),
    .ID_B_result(ID_B_result),
    .ID_predict_error(ID_predict_error),
`else
     .out_BJ_control (BJ_control),
`endif
     .out_BJ_target  (BJ_target)
`ifdef CPU_PG
    , .CPU_CG(CPU_CG)
`endif 
  );

  // =======================
  // EXE_stage
  // =======================
  EXE_stage u_exe (
    .clk        (clk),
    .rst        (rst),
    `ifdef cache
    .EXE_MEM_use(EXE_MEM_use),
    .EXE_I_result(EXE_I_result),
    `endif
    .global_stall(global_stall),
    .EXE_detect_wfi(EXE_detect_wfi),
    .stall_wfi(stall_wfi),
    .interrupt(interrupt),
    .interrupt_mtvec(interrupt_mtvec),
    .out_mepc(out_mepc),
    .CSR_mip(CSR_mip),
    // from ID（EXE_*）
    .rs1_data   (EXE_rs1_data),
    .rs2_data   (EXE_rs2_data),
    .rs1        (EXE_rs1),
    .rs2        (EXE_rs2),
    .rd         (EXE_rd),
    .frs1       (EXE_frs1),
    .frs2       (EXE_frs2),
    .frd        (EXE_frd),
    .load_I     (EXE_load_I),
    .F_load_I   (EXE_F_load_I),
    .opcode     (EXE_opcode),
    .PC         (EXE_PC),
    .imm        (EXE_imm),
    .funct3     (EXE_funct3),
    .funct5     (EXE_funct5),
    .funct7     (EXE_funct7),
    //.stall      (stall),

    // FW2：來自 MEM/WB（以原名 FW2_*）
`ifdef FALU_stall
`else
    `ifdef cache
      .FW2_WB_frd_data (FW_PWB_result),
      .WB_frd          (FW_PWB_frd),
    `else
      .FW2_WB_frd_data (WB_result),
      .WB_frd          (WB_frd),
    `endif
`endif

  `ifdef cache
      .FW2_WB_rd_data  (FW_PWB_result),
      .WB_rd          (FW_PWB_rd),
    `else
      .FW2_WB_rd_data  (WB_result),
      .WB_rd           (WB_rd),
    `endif
    .MEM_rd          (MEM_rd),
    .FW2_MEM_frd_data(MEM_result),
    .FW2_MEM_rd_data (MEM_result),
    .MEM_frd         (MEM_frd)



`ifdef test
   , .instr       (EXE_instr),
     .R_type_I    (EXE_R_type_I),
     .I_type_I    (EXE_I_type_I),
     .S_type_I    (EXE_S_type_I),
     .B_type_I    (EXE_B_type_I),
     .J_type_I    (EXE_J_type_I),
     .F_type_I    (EXE_F_type_I),
     .CSR_I       (EXE_CSR_I),

     .out_instr   (MEM_instr),
     .out_R_type_I(MEM_R_type_I),
     .out_I_type_I(MEM_I_type_I),
     .out_S_type_I(MEM_S_type_I),
     .out_B_type_I(MEM_B_type_I),
     .out_J_type_I(MEM_J_type_I),
     .out_F_type_I(MEM_F_type_I),
     .out_CSR_I   (MEM_CSR_I),
     .out_PC      (MEM_PC),
	   .out_opcode      (MEM_opcode),
     .out_funct5  (MEM_funct5_dbg),
     .out_funct7  (MEM_funct7_dbg)
`endif

   , .out_result      (MEM_result),
     .out_store_data  (MEM_store_data),
     .out_load_I      (MEM_load_I),
     .out_F_load_I    (MEM_F_load_I),
     .out_rd          (MEM_rd),
     .out_frd         (MEM_frd),
     .out_funct3      (MEM_funct3),
     .out_WB_control  (MEM_WB_control),
     .out_F_WB_control(MEM_F_WB_control),
     .out_store_I     (MEM_store_I),
	 .out_F_operation (MEM_F_operation)
  );







  // =======================
  // MEM_stage
  // =======================
  MEM_stage u_mem (
    .clk        (clk),
    .rst        (rst | CPU_restore_pulse),
    .global_stall(global_stall),
    .Addr32(Addr32)
`ifdef top_mem
  ,
    .dcache_low_Eable    (dcache_low_Eable),
    .dcache_WR           (dcache_WR),
    .dcache_hidden_map   (dcache_hidden_map),
    .dcache_EXE_result_16(dcache_EXE_result_16),
    .dcache_store_data   (dcache_store_data),
    .dcache_read_data    (dcache_read_data)
`endif 
`ifdef test
   , .instr     (MEM_instr),
     .R_type_I  (MEM_R_type_I),
     .I_type_I  (MEM_I_type_I),
     .S_type_I  (MEM_S_type_I),
     .B_type_I  (MEM_B_type_I),
     .J_type_I  (MEM_J_type_I),
     .F_type_I  (MEM_F_type_I),
     .CSR_I     (MEM_CSR_I),
     .PC        (MEM_PC),
	 .opcode       (MEM_opcode),
     .funct5    (MEM_funct5_dbg),
     .funct7    (MEM_funct7_dbg)
`endif

   , .EXE_result   (MEM_result),
     .load_I       (MEM_load_I),
     .F_load_I     (MEM_F_load_I),
     .rd           (MEM_rd),
     .frd          (MEM_frd),
     .funct3       (MEM_funct3),
     .WB_control   (MEM_WB_control),
     .F_WB_control (MEM_F_WB_control),
     .store_I      (MEM_store_I),
	 //.stall        (stall),
	 //.F_operation (MEM_F_operation),
     .store_data   (MEM_store_data)
     

`ifdef test
   , .out_instr    (WB_instr),
     .out_R_type_I (WB_R_type_I),
     .out_I_type_I (WB_I_type_I),
     .out_S_type_I (WB_S_type_I),
     .out_B_type_I (WB_B_type_I),
     .out_J_type_I (WB_J_type_I),
     .out_F_type_I (WB_F_type_I),
     .out_CSR_I    (WB_CSR_I),
     .out_PC       (WB_PC),
     .out_funct3   (WB_funct3),
     .out_funct5   (WB_funct5),
     .out_funct7   (WB_funct7),
     .out_load_I   (WB_load_I),
     .out_F_load_I (WB_F_load_I),
     .out_opcode   (WB_opcode),
     .out_store_I  (WB_store_I)
`endif

   , .out_rd          (WB_rd),
     .out_frd         (WB_frd),
     .out_WB_control  (WB_WB_control),
     .out_F_WB_control(WB_F_WB_control),
     .out_result      (WB_result)
  );

  // =======================
  // WB_stage（由 MEM 輸入）
  // =======================
  WB_stage u_wb (
    .clk(clk),
    .rst(rst | CPU_restore_pulse),
    .global_stall(global_stall),
`ifdef test
    .instr     (WB_instr),
    .R_type_I  (WB_R_type_I),
    .I_type_I  (WB_I_type_I),
    .S_type_I  (WB_S_type_I),
    .B_type_I  (WB_B_type_I),
    .J_type_I  (WB_J_type_I),
    .F_type_I  (WB_F_type_I),
    .CSR_I     (WB_CSR_I),
    .PC        (WB_PC),
    .funct3    (WB_funct3),
    .funct5    (WB_funct5),
    .funct7    (WB_funct7),
    .load_I    (WB_load_I),
    .F_load_I  (WB_F_load_I),
    .opcode    (WB_opcode),
    .store_I   (WB_store_I),
`endif
    .rd            (WB_rd),
    .frd           (WB_frd),
    .WB_control    (WB_WB_control),
    .F_WB_control  (WB_F_WB_control),
    .result        (WB_result),

    .out_rd          (WB_out_rd),
    .out_frd         (WB_out_frd),
    .out_WB_control  (WB_out_WB_control),
    .out_F_WB_control(WB_out_F_WB_control),
    .out_result      (WB_out_result)
  `ifdef cache
  ,
    .FW_PWB_rd(FW_PWB_rd), 
    .FW_PWB_frd(FW_PWB_frd),
    .FW_PWB_WB_control(FW_PWB_WB_control), 
    .FW_PWB_F_WB_control(FW_PWB_F_WB_control),
    .FW_PWB_result(FW_PWB_result)
  `endif
  );
`ifdef test
`ifdef monitor
rv32_pipe_monitor #(
  .VERBOSE(1),
  .ENABLE_ASSERTS(1)
) u_mon (
  .clk   (clk),
  .rst_n (~rst),

  // ===== IF =====
  .if_valid        (1'b1),
  .if_stall        (stall),
  .if_dff_PC       (ID_PC),
  .if_dff_instr    (ID_instr),
  .if_dff_opcode   (7'd0),
  .if_dff_funct3   (3'd0),
  .if_dff_funct5   (5'd0),
  .if_dff_funct7   (7'd0),
  .if_dff_R_type_I (1'b0),
  .if_dff_I_type_I (1'b0),
  .if_dff_S_type_I (1'b0),
  .if_dff_B_type_I (1'b0),
  .if_dff_J_type_I (1'b0),
  .if_dff_F_type_I (1'b0),
  .if_dff_CSR_I    (1'b0),
  .if_dff_load_I   (1'b0),
  .if_dff_F_load_I (1'b0),
  .if_dff_store_I  (1'b0),

  // ===== ID (ID→EXE 邊界，用 EXE_* 接) =====
  .id_valid        (1'b1),
  .id_stall        (stall),
  .id_dff_PC       (EXE_PC),
  .id_dff_instr    (EXE_instr),
  .id_dff_opcode   (EXE_opcode),
  .id_dff_funct3   (EXE_funct3),
  .id_dff_funct5   (EXE_funct5),
  .id_dff_funct7   (EXE_funct7),
  .id_dff_R_type_I (EXE_R_type_I),
  .id_dff_I_type_I (EXE_I_type_I),
  .id_dff_S_type_I (EXE_S_type_I),
  .id_dff_B_type_I (EXE_B_type_I),
  .id_dff_J_type_I (EXE_J_type_I),
  .id_dff_F_type_I (EXE_F_type_I),
  .id_dff_CSR_I    (EXE_CSR_I),
  .id_dff_load_I   (EXE_load_I),
  .id_dff_F_load_I (EXE_F_load_I),
  .id_dff_store_I  (1'b0),        // ID 階段未明確提供 store_I，先接 0

  // ===== EX (EXE→MEM 邊界，用 EXE 輸出之 MEM_* 接) =====
  .ex_valid        (1'b1),
  .ex_stall        (stall),
  .ex_dff_PC       (MEM_PC),
  .ex_dff_instr    (MEM_instr),
  .ex_dff_opcode   (MEM_opcode),
  .ex_dff_funct3   (MEM_funct3),
  .ex_dff_funct5   (MEM_funct5_dbg),
  .ex_dff_funct7   (MEM_funct7_dbg),
  .ex_dff_R_type_I (MEM_R_type_I),
  .ex_dff_I_type_I (MEM_I_type_I),
  .ex_dff_S_type_I (MEM_S_type_I),
  .ex_dff_B_type_I (MEM_B_type_I),
  .ex_dff_J_type_I (MEM_J_type_I),
  .ex_dff_F_type_I (MEM_F_type_I),
  .ex_dff_CSR_I    (MEM_CSR_I),
  .ex_dff_load_I   (MEM_load_I),
  .ex_dff_F_load_I (MEM_F_load_I),
  .ex_dff_store_I  (MEM_store_I),

  // ===== MEM (MEM→WB 邊界，用 MEM 輸出之 WB_* 接) =====
  .mem_valid        (1'b1),
  .mem_stall        (stall),
  .mem_dff_PC       (WB_PC),
  .mem_dff_instr    (WB_instr),
  .mem_dff_opcode   (WB_opcode),
  .mem_dff_funct3   (WB_funct3),
  .mem_dff_funct5   (WB_funct5),
  .mem_dff_funct7   (WB_funct7),
  .mem_dff_R_type_I (WB_R_type_I),
  .mem_dff_I_type_I (WB_I_type_I),
  .mem_dff_S_type_I (WB_S_type_I),
  .mem_dff_B_type_I (WB_B_type_I),
  .mem_dff_J_type_I (WB_J_type_I),
  .mem_dff_F_type_I (WB_F_type_I),
  .mem_dff_CSR_I    (WB_CSR_I),
  .mem_dff_load_I   (WB_load_I),
  .mem_dff_F_load_I (WB_F_load_I),
  .mem_dff_store_I  (WB_store_I),

  // ===== WB（WB_stage 輸入即為 WB pipeline 內容） =====
  .wb_valid        (1'b1),
  .wb_stall        (stall),
  .wb_dff_PC       (WB_PC),
  .wb_dff_instr    (WB_instr),
  .wb_dff_opcode   (WB_opcode),
  .wb_dff_funct3   (WB_funct3),
  .wb_dff_funct5   (WB_funct5),
  .wb_dff_funct7   (WB_funct7),
  .wb_dff_R_type_I (WB_R_type_I),
  .wb_dff_I_type_I (WB_I_type_I),
  .wb_dff_S_type_I (WB_S_type_I),
  .wb_dff_B_type_I (WB_B_type_I),
  .wb_dff_J_type_I (WB_J_type_I),
  .wb_dff_F_type_I (WB_F_type_I),
  .wb_dff_CSR_I    (WB_CSR_I),
  .wb_dff_load_I   (WB_load_I),
  .wb_dff_F_load_I (WB_F_load_I),
  .wb_dff_store_I  (WB_store_I)
);
`endif
`endif

endmodule
