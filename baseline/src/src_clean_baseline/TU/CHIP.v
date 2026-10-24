`define top_def
`include "../include/TOP.svh"
module CHIP(
  input            cpu_clk,
  input            axi_clk,
  input            rom_clk,
  input            dram_clk,
  input            cpu_rst,
  input            axi_rst,
  input            rom_rst,
  input            dram_rst,
  input  [   31:0] ROM_out,
  input  [   31:0] DRAM_Q,
  output           ROM_read,
  output           ROM_enable,
  output [   11:0] ROM_address,
  output           DRAM_CSn,
  output [    3:0] DRAM_WEn,
  output           DRAM_RASn,
  output           DRAM_CASn,
  input            DRAM_valid, 
  output [   10:0] DRAM_A,
  output [   31:0] DRAM_D,
  output  [1:0] v_ctrl_idx,
  output  [1:0] v_ctrl

);

wire           cpu_clk_i;
wire           cpu_rst_i;
wire           axi_clk_i;
wire           axi_rst_i;
wire           rom_clk_i;
wire           rom_rst_i;
wire           dram_clk_i;
wire           dram_rst_i;
wire [   31:0] ROM_out_i;
wire           ROM_read_o;
wire           ROM_enable_o;
wire [   11:0] ROM_address_o;
wire [   31:0] DRAM_Q_i;
wire           DRAM_CSn_o;
wire [    3:0] DRAM_WEn_o;
wire           DRAM_RASn_o;
wire           DRAM_CASn_o;
wire [   10:0] DRAM_A_o;
wire [   31:0] DRAM_D_o;
wire           DRAM_valid_i;

wire [1:0]      v_ctrl_idx_o;
wire [1:0]      v_ctrl_o; 

//core instance
top u_TOP(
	.cpu_clk		    (cpu_clk_i      ), // CPU CLOCK DOMAIN
	.cpu_rst		    (cpu_rst_i      ),
  .axi_clk		    (axi_clk_i      ),
  .axi_rst		    (axi_rst_i      ),
	.rom_clk        (rom_clk_i      ),//rom
  .rom_rst        (rom_rst_i      ),
  .ROM_out        (ROM_out_i      ),//rom
  .ROM_read       (ROM_read_o     ),
  .ROM_enable     (ROM_enable_o   ),
  .ROM_address    (ROM_address_o  ),
	.dram_clk       (dram_clk_i     ),//DRAM
	.dram_rst       (dram_rst_i     ),
  .DRAM_valid     (DRAM_valid_i   ),
  .DRAM_Q         (DRAM_Q_i       ),
  .DRAM_CSn       (DRAM_CSn_o     ),
  .DRAM_WEn       (DRAM_WEn_o     ),
  .DRAM_RASn      (DRAM_RASn_o    ),
  .DRAM_CASn      (DRAM_CASn_o    ),
  .DRAM_A         (DRAM_A_o       ),
  .DRAM_D         (DRAM_D_o       ),
  .v_ctrl_idx     (v_ctrl_idx_o   ),
  .v_ctrl         (v_ctrl_o       )
);
wire io_rte;
 FILL_IN_CELL_RTE_BOUNDARY_PAD_013 pad_RTE (.IRTE(1'b0), .RTE(io_rte));
FILL_IN_CELL_IO_POWER_PAD_014 pad_POC (.RTE(io_rte));

//iopad example
//upper
//`ifdef IOPAD
//FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_DRAM_Q0    (.OEN(1'b1), .IE(1'b1), .I(1'b0), .PAD(DRAM_Q[0 ]), .C(DRAM_Q_i[0 ])); ///DRAM_Q


//left
//FILL_IN_CELL_DIGITAL_IO_PAD_016 opad_DRAM_CSn  (.OEN(1'b0), .IE(1'b0), .I(DRAM_CSn_o     ), .PAD(DRAM_CSn    ), .C());  ///DRAM control


//bottom
//FILL_IN_CELL_DIGITAL_IO_PAD_015 opad_DRAM_D15  (.OEN(1'b0), .IE(1'b0), .I(DRAM_D_o[15 ]  ), .PAD(DRAM_D[15]  ), .C());


///right
//FILL_IN_CELL_DIGITAL_IO_PAD_016 ipad_ROM_out0  (.OEN(1'b1), .IE(1'b1), .I(1'b0), .PAD(ROM_out[0 ]), .C(ROM_out_i[0 ])); ///DRAM_Q

/*=====================================
* DRAM_Q[31:0]  (input pad, V)
*=====================================*/

genvar i;
  generate
    for (i = 0; i < 2; i = i + 1) begin : GEN_v_ctrl_idx
      FILL_IN_CELL_DIGITAL_IO_PAD_015 opad_v_ctrl_idx (
        .OEN (1'b0),
        .IE  (1'b0),
        .I   (v_ctrl_idx_o[i]),
        .PAD (v_ctrl_idx[i]),
        .C   (),
        .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
      );
    end
  endgenerate;

    generate
    for (i = 0; i < 2; i = i + 1) begin : GEN_v_ctrl
      FILL_IN_CELL_DIGITAL_IO_PAD_015 opad_v_ctrl (
        .OEN (1'b0),
        .IE  (1'b0),
        .I   (v_ctrl_o[i]),
        .PAD (v_ctrl[i]),
        .C   (),
        .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
      );
    end
  endgenerate;

  generate
    for (i = 0; i < 32; i = i + 1) begin : GEN_DRAM_Q
      FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_DRAM_Q (
        .OEN (1'b1),
        .IE  (1'b1),
        .I   (1'b0),
        .PAD (DRAM_Q[i]),
        .C   (DRAM_Q_i[i]),
        .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte) 
      );
    end
  endgenerate

  /*=====================================
   * ROM_out[31:0]  (input pad, H)
   *=====================================*/
  generate
    for (i = 0; i < 32; i = i + 1) begin : GEN_ROM_OUT
      FILL_IN_CELL_DIGITAL_IO_PAD_016 ipad_ROM_out (
        .OEN (1'b1),
        .IE  (1'b1),
        .I   (1'b0),
        .PAD (ROM_out[i]),
        .C   (ROM_out_i[i]),
        .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
      );
    end
  endgenerate

  /*=====================================
   * DRAM_D[31:0]  (output pad, V)
   *=====================================*/
  generate
    for (i = 0; i < 32; i = i + 1) begin : GEN_DRAM_D
      FILL_IN_CELL_DIGITAL_IO_PAD_015 opad_DRAM_D (
        .OEN (1'b0),
        .IE  (1'b0),
        .I   (DRAM_D_o[i]),
        .PAD (DRAM_D[i]),
        .C   (),
        .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
      );
    end
  endgenerate

  /*=====================================
   * DRAM_A[10:0]  (output pad)
   *=====================================*/
  generate
    for (i = 0; i < 11; i = i + 1) begin : GEN_DRAM_A
      FILL_IN_CELL_DIGITAL_IO_PAD_016 opad_DRAM_A (
        .OEN (1'b0),
        .IE  (1'b0),
        .I   (DRAM_A_o[i]),
        .PAD (DRAM_A[i]),
        .C   (),
        .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
      );
    end
  endgenerate

  /*=====================================
   * ROM_address[11:0]  (output pad)
   *=====================================*/
  generate
    for (i = 0; i < 12; i = i + 1) begin : GEN_ROM_ADDR
      FILL_IN_CELL_DIGITAL_IO_PAD_016 opad_ROM_address (
        .OEN (1'b0),
        .IE  (1'b0),
        .I   (ROM_address_o[i]),
        .PAD (ROM_address[i]),
        .C   (),
        .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
      );
    end
  endgenerate

  /*=====================================
   * DRAM_WEn[3:0]  (output pad)
   *=====================================*/
  generate
    for (i = 0; i < 4; i = i + 1) begin : GEN_DRAM_WEN
      FILL_IN_CELL_DIGITAL_IO_PAD_016 opad_DRAM_WEn (
        .OEN (1'b0),
        .IE  (1'b0),
        .I   (DRAM_WEn_o[i]),
        .PAD (DRAM_WEn[i]),
        .C   (),
        .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
      );
    end
  endgenerate

  /*=====================================
   * Single-bit control pads
   *=====================================*/
  FILL_IN_CELL_DIGITAL_IO_PAD_016 opad_ROM_read (
    .OEN (1'b0),
    .IE  (1'b0),
    .I   (ROM_read_o),
    .PAD (ROM_read),
    .C   (),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)

  );

  FILL_IN_CELL_DIGITAL_IO_PAD_016 opad_ROM_enable (
    .OEN (1'b0),
    .IE  (1'b0),
    .I   (ROM_enable_o),
    .PAD (ROM_enable),
    .C   (),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  // );
  );

  FILL_IN_CELL_DIGITAL_IO_PAD_016 opad_DRAM_CSn (
    .OEN (1'b0),
    .IE  (1'b0),
    .I   (DRAM_CSn_o),
    .PAD (DRAM_CSn),
    .C   (),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  // );
  );

  FILL_IN_CELL_DIGITAL_IO_PAD_016 opad_DRAM_RASn (
    .OEN (1'b0),
    .IE  (1'b0),
    .I   (DRAM_RASn_o),
    .PAD (DRAM_RASn),
    .C   (),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  // );
  );

  FILL_IN_CELL_DIGITAL_IO_PAD_016 opad_DRAM_CASn (
    .OEN (1'b0),
    .IE  (1'b0),
    .I   (DRAM_CASn_o),
    .PAD (DRAM_CASn),
    .C   (),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  // );
  );

  FILL_IN_CELL_DIGITAL_IO_PAD_016 ipad_DRAM_valid (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (DRAM_valid),
    .C   (DRAM_valid_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );


/*=====================================
 * Clock pads
 *=====================================*/
`ifdef multi_clk
  FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_cpu_clk (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (cpu_clk),
    .C   (cpu_clk_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );
`endif

  FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_axi_clk (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (axi_clk),
    .C   (axi_clk_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );

  FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_rom_clk (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (rom_clk),
    .C   (rom_clk_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );

  FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_dram_clk (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (dram_clk),
    .C   (dram_clk_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );

/*=====================================
 * Reset pads
 *
 * single_reset defined:
 *   - Keep only the rom_rst pad.
 *   - cpu_rst_i/axi_rst_i/rom_rst_i/dram_rst_i all use rom_rst_i.
 *
 * single_reset undefined:
 *   - Preserve the original independent-reset pad configuration.
 *=====================================*/
`ifdef single_reset

  FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_rom_rst (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (rom_rst),
    .C   (rom_rst_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );

  assign cpu_rst_i  = rom_rst_i;
  assign axi_rst_i  = rom_rst_i;
  assign dram_rst_i = rom_rst_i;

`else

`ifdef multi_clk
  FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_cpu_rst (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (cpu_rst),
    .C   (cpu_rst_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );
`endif

  FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_axi_rst (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (axi_rst),
    .C   (axi_rst_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );

  FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_rom_rst (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (rom_rst),
    .C   (rom_rst_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );

  FILL_IN_CELL_DIGITAL_IO_PAD_015 ipad_dram_rst (
    .OEN (1'b1),
    .IE  (1'b1),
    .I   (1'b0),
    .PAD (dram_rst),
    .C   (dram_rst_i),
    .DS0(1'b0), .DS1(1'b1), .DS2(1'b1), .DS3(1'b0), .PU(1'b0), .PD(1'b0), .ST(1'b0), .RTE(io_rte)
  );

`endif


/*`else */
// assign   cpu_clk_i    =     cpu_clk  ;  
// assign   axi_clk_i    =     axi_clk  ;  
// assign   cpu_rst_i    =     cpu_rst  ;  
// assign   axi_rst_i    =     axi_rst  ;  
// assign   rom_clk_i    =     rom_clk  ;  
// assign   rom_rst_i    =     rom_rst ;

// assign   dram_clk_i   =     dram_clk  ;    
// assign   dram_rst_i   =     dram_rst ;    
// assign   ROM_out_i    =     ROM_out;
// assign   DRAM_Q_i     =     DRAM_Q;
// assign   DRAM_valid_i =     DRAM_valid;

// assign   ROM_read         =   ROM_read_o;
// assign   ROM_enable       =   ROM_enable_o;
// assign   ROM_address      =   ROM_address_o;
// assign   DRAM_CSn         =   DRAM_CSn_o;
// assign   DRAM_WEn         =   DRAM_WEn_o;
// assign   DRAM_RASn        =   DRAM_RASn_o;
// assign   DRAM_CASn        =   DRAM_CASn_o;
// assign   DRAM_A       =   DRAM_A_o;
// assign   DRAM_D       =   DRAM_D_o;
/*`endif*/

endmodule