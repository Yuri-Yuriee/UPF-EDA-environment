`include "monitor.sv"
// Local simulation timing and timeout settings.
`define CPU_CYCLE 1.0
`define DRAM_CYCLE 20
`define ROM_CYCLE 50
`define AXI_CYCLE 10
`define MAX 300000000
`include "../include/TOP.svh"
`timescale 1ns/10ps
// clock define (don't modify)
`define DRAM_CYCLE    5.0    // 200Mhz
`define ROM_CYCLE     50.1   // 100Mhz
`define AXI_CYCLE     2.5    // 200Mhz

//**************
//    tb define
//**************
`define Dual_MEM
//`define test
`define UPF

`include "../sim/filelist/mem.f"
`include "../sim/filelist/cell.f"
`include "ROM/ROM.v"
`include "DRAM/DRAM.sv"
`include "regulator/regulator.sv"

`ifdef SYN
  `include "../src/src_clean_baseline/IP/TD/TD_local_unit_behavior.sv"
  // `include "../src/src_clean_baseline/AXI-4/slave_simple.sv"
  // `include "../src/src_clean_baseline/AXI-4/master_simple.sv"
  `include "../src/src_clean_baseline/CDC/FIFO.sv"
  `include "../src/src_clean_baseline/CDC/G_converter.sv"

`endif

`resetall
`timescale 1ns/1ps


`define ismem_word(addr) \
  {chip.u_TOP.DM1.i_SRAM.MEMORY[(addr) >> 4][(addr) & 4'hF]}

`define mem_word(addr) \
  {chip.u_TOP.DM1.i_SRAM.MEMORY[(addr) >> 4][(addr) & 4'hF]}

`define dram_word(addr) \
  {i_DRAM.Memory_byte3[addr], \
  i_DRAM.Memory_byte2[addr], \
  i_DRAM.Memory_byte1[addr], \
  i_DRAM.Memory_byte0[addr]}

`define SIM_END 'h3fff
`define SIM_END_CODE -32'd1
`define TEST_START 'h40000
`define BOOT_END 'h40002	//DRAM
`define BOOT_END_CODE -32'd1 //flag
`define FOR_LOOP_ADDR 'h153 //SRAM 1054C
`define FOR_LOOP_DEAD_LOOP 'h6f
`define FOR_LOOP_COUNT_INIT 'ha00793
`define mask  2000

module top_tb;

  logic cpu_clk;
  logic axi_clk;
  logic dram_clk;
  logic rom_clk;
  logic rst;
  logic [31:0] GOLDEN[4096];
  logic [7:0] Memory_byte0[16383:0];
  logic [7:0] Memory_byte1[16383:0];
  logic [7:0] Memory_byte2[16383:0];
  logic [7:0] Memory_byte3[16383:0];
  logic [31:0] Memory_word[16383:0];
  //HW4
  logic [31:0] ROM_out;
  logic [31:0] DRAM_Q;
  logic ROM_enable;
  logic ROM_read;
  logic [11:0] ROM_address;
  logic DRAM_CSn;
  logic [3:0]DRAM_WEn;
  logic DRAM_RASn;
  logic DRAM_CASn;
  logic [10:0] DRAM_A;
  logic [31:0] DRAM_D; 
  logic DRAM_valid;

  logic [31:0] sensor_mem [0:511];  
  logic [9:0] data_counter;  
  //HW4
  integer gf, i, num,delay_c;
  logic [31:0] temp;
  integer err;
  string prog_path;
  logic cpu_rst ;
  logic axi_rst ;
  logic rom_rst ;
  logic dram_rst;
  
  localparam real TB_INIT_CELL_DELAY_PS    = 200.0;
  localparam real TB_VOLTAGE_DELAY_SCALE  = 1.05;
  real        tb_cell_delay_ps;
  logic [1:0] v_ctrl;
  
  always #(`CPU_CYCLE/2)    cpu_clk     = ~cpu_clk;
  always #(`AXI_CYCLE/2)    axi_clk     = ~axi_clk;
  always #(`DRAM_CYCLE/2)   dram_clk    = ~dram_clk;
  always #(`ROM_CYCLE/2)    rom_clk     = ~rom_clk;


  // module instantiation
  CHIP chip(
    .cpu_clk		    (cpu_clk    ),      //  
    .axi_clk		    (axi_clk    ),      //  
    .rom_clk        (rom_clk    ),      //  
    .dram_clk       (dram_clk   ),      //  
    .cpu_rst		    (cpu_rst    ),      //  
    .axi_rst		    (axi_rst    ),      //  
    .rom_rst        (rom_rst    ),      //  
    .dram_rst       (dram_rst   ),      //  
    .ROM_out        (ROM_out    ),      //  
    .DRAM_valid     (DRAM_valid ),      //  
    .DRAM_Q         (DRAM_Q     ),      //  
    .ROM_read       (ROM_read   ),      //  
    .ROM_enable     (ROM_enable ),      //  
    .ROM_address    (ROM_address),      //  
    .DRAM_CSn       (DRAM_CSn   ),      //  
    .DRAM_WEn       (DRAM_WEn   ),      //  
    .DRAM_RASn      (DRAM_RASn  ),      //  
    .DRAM_CASn      (DRAM_CASn  ),      //  
    .DRAM_A         (DRAM_A     ),      //  
    .DRAM_D         (DRAM_D     ),      //
    .v_ctrl_idx     (           ),
    .v_ctrl         (v_ctrl     )  
  );


  ROM i_ROM(
    .CK             (rom_clk      ), // ROM CLOCK DOMAIN
    .CS             (ROM_enable   ),
    .OE             (ROM_read     ),
    .A              (ROM_address  ),
    .DO             (ROM_out      )
  );

   DRAM i_DRAM(
    .CK             (dram_clk     ), // DRAM CLOCK DOMAIN
    .Q              (DRAM_Q       ),
    .RST            (dram_rst     ),
    .CSn            (DRAM_CSn     ),
    .WEn            (DRAM_WEn     ),
    .RASn           (DRAM_RASn    ),
    .CASn           (DRAM_CASn    ),
    .A              (DRAM_A       ),
    .D              (DRAM_D       ),
    .VALID          (DRAM_valid   )
  );
  

  regulator #(
    .INIT_CELL_DELAY_PS  (TB_INIT_CELL_DELAY_PS),
    .VOLTAGE_DELAY_SCALE (TB_VOLTAGE_DELAY_SCALE)
  ) u_regulator (
      .clk           (axi_clk),
      .rst           (axi_rst),
      .v_ctrl        (v_ctrl),
      .cell_delay_ps (tb_cell_delay_ps)
  );
  
  
  initial begin
    int boot_end_flag = 0;
    int only_pose1 = 0;
    int only_pose2 = 0;
    int cycle_number = 0;
    while (1) begin
      #(`CPU_CYCLE)
      if (`dram_word(`TEST_START) != only_pose1 && `dram_word(`TEST_START) == `BOOT_END_CODE && boot_end_flag == 0) begin
        $display("`dram_word(`TEST_START) = %x, cycle_number = %d",`dram_word(`TEST_START),cycle_number);
        boot_end_flag = 1;
        `ismem_word(`FOR_LOOP_ADDR) = `FOR_LOOP_DEAD_LOOP;
        $display("`ismem_word(`FOR_LOOP_ADDR) = %x",`ismem_word(`FOR_LOOP_ADDR));
        $display($time);
      end else if (`dram_word(`TEST_START) != only_pose1 && `dram_word(`TEST_START) == `BOOT_END_CODE && boot_end_flag == 1) begin
        $display("`dram_word(`TEST_START)2 = %x, cycle_number = %d",`dram_word(`TEST_START),cycle_number);
        boot_end_flag = 2;
        `ismem_word(`FOR_LOOP_ADDR) = `FOR_LOOP_COUNT_INIT;
        $display($time);
      end
      cycle_number = cycle_number + 1;
      only_pose1 = `dram_word(`TEST_START);
    end
  end
  
  // reset release sequence (DRAM -> ROM -> SRAM -> AXI -> CPU)
  initial begin
    dram_rst = 1;
    rom_rst  = 1;
    axi_rst  = 1;
    cpu_rst  = 1;
	// mask     = 0;
	#(`mask)
	// mask     = 1;
    @(posedge dram_clk)
    #(1); // small number 
    dram_rst = 0;
    @(posedge rom_clk)
    #(1); // small number 
    rom_rst = 0;
    @(posedge axi_clk)
    #(1); // small number 
    axi_rst = 0;
    @(posedge cpu_clk)
    #(15); // small number 
    cpu_rst = 0;
  end
  
  initial
  begin
    // reset
    cpu_clk         = 0;  	
    axi_clk         = 0;
    dram_clk        = 0;
    rom_clk         = 0;
    data_counter    = 0;
    $value$plusargs("prog_path=%s", prog_path);
    // wait for dram reset = 0 
    wait(dram_rst)
    wait(~dram_rst)
    $readmemh({prog_path, "/rom0.hex"}, i_ROM.Memory_byte0);
    $readmemh({prog_path, "/rom1.hex"}, i_ROM.Memory_byte1);
    $readmemh({prog_path, "/rom2.hex"}, i_ROM.Memory_byte2);
    $readmemh({prog_path, "/rom3.hex"}, i_ROM.Memory_byte3);
    $readmemh({prog_path, "/dram0.hex"}, i_DRAM.Memory_byte0);
    $readmemh({prog_path, "/dram1.hex"}, i_DRAM.Memory_byte1);
    $readmemh({prog_path, "/dram2.hex"}, i_DRAM.Memory_byte2);
    $readmemh({prog_path, "/dram3.hex"}, i_DRAM.Memory_byte3);

    num = 0;
    gf = $fopen({prog_path, "/golden.hex"}, "r");
    while (!$feof(gf)) begin
      $fscanf(gf, "%h\n", GOLDEN[num]);
      num++;
    end
    $fclose(gf);

    while (1) begin
      @(negedge cpu_clk)
      if (`mem_word(`SIM_END) == `SIM_END_CODE) break;

    end	
    $display("\nDone\n");
    err = 0;

    for (i = 0; i < num; i++) begin
      if (`dram_word(`TEST_START + i) !== GOLDEN[i]) begin
        $display("DRAM[%4d] = %h, expect = %h", `TEST_START + i, `dram_word(`TEST_START + i), GOLDEN[i]);
        err = err + 1;
      end else begin
        $display("DRAM[%4d] = %h, pass", `TEST_START + i, `dram_word(`TEST_START + i));
      end
    end
    result(err, num);
    // mem_monitor; // get memory value
    $finish;
  end

  `ifdef SYN
    //initial $sdf_annotate("../syn/CHIP_syn.sdf", chip);
  `elsif PR
    // initial $sdf_annotate("../pr/CHIP_pr.sdf", chip);
    //initial $sdf_annotate("../APR_new/innovus_stylus/APR/outputs/CHIP_min.sdf", chip);
  `endif

  initial begin
    `ifdef FSDB
      $fsdbDumpfile("chip.fsdb");
      //$fsdbDumpvars(0, TOP);
    $fsdbDumpvars;
    `elsif FSDB_ALL
      $fsdbDumpfile("chip.fsdb");
      $fsdbDumpvars(0);
      $fsdbDumpMDA();
      // $fsdbDumpvars("+struct", "+mda", chip);
      // $fsdbDumpvars("+struct", "+mda", i_DRAM);
      // $fsdbDumpvars("+struct", i_DRAM);
    `endif
    // if reach maximum simulation time
    #(`CPU_CYCLE*`MAX)
    for (i = 0; i < num; i++) begin
      if (`dram_word(`TEST_START + i) !== GOLDEN[i]) begin
        $display("DRAM[%4d] = %h, expect = %h", `TEST_START + i, `dram_word(`TEST_START + i), GOLDEN[i]);
        err=err+1;
      end else begin
        $display("DRAM[%4d] = %h, pass", `TEST_START + i, `dram_word(`TEST_START + i));
      end
    end
    $display("SIM_END(%5d) = %h, expect = %h", `SIM_END, `dram_word(`SIM_END), `SIM_END_CODE);
    result(num, num);
    // mem_monitor; // get memory value
    $finish;
  end
  
  task result;
    input integer err;
    input integer num;
    integer rf;
    begin
      `ifdef SYN
        rf = $fopen({prog_path, "/result_syn.txt"}, "w");
      `elsif PR
        rf = $fopen({prog_path, "/result_pr.txt"}, "w");
      `else
        rf = $fopen({prog_path, "/result_rtl.txt"}, "w");
      `endif
      $fdisplay(rf, "%d,%d", num - err, num);
      if (err === 0) begin
        $display("\n");
        $display("\n");
        $display("        **************************               ");
        $display("        *                        *       |\__||  ");
        $display("        *  Congratulations !!    *      / O.O  | ");
        $display("        *                        *    /_____   | ");
        $display("        *  Simulation PASS!!     *   /^ ^ ^ \\  |");
        $display("        *                        *  |^ ^ ^ ^ |w| ");
        $display("        **************************   \\m___m__|_|");
        $display("\n");
      end else begin
        $display("\n");
        $display("\n");
        $display("        **************************               ");
        $display("        *                        *       |\__||  ");
        $display("        *  OOPS!!                *      / X,X  | ");
        $display("        *                        *    /_____   | ");
        $display("        *  Simulation Failed!!   *   /^ ^ ^ \\  |");
        $display("        *                        *  |^ ^ ^ ^ |w| ");
        $display("        **************************   \\m___m__|_|");
        $display("         Totally has %d errors                     ", err); 
        $display("\n");
      end
      $display("                  %10s %10s", "CYCLE", "FREQ");
      $display("        DRAM    : %10f %10f", `DRAM_CYCLE, (1000/`DRAM_CYCLE));
      $display("        ROM     : %10f %10f", `ROM_CYCLE, (1000/`ROM_CYCLE));
      $display("        CPU     : %10f %10f", `CPU_CYCLE, (1000/`CPU_CYCLE));
      $display("        AXI     : %10f %10f", `AXI_CYCLE, (1000/`AXI_CYCLE));
      `ifdef test
        $display("\n");
        $display("\n");
        $display("        D cache miss       : %10d ",chip.u_TOP.u_cpu.u_cpu_plug.MEM_miss_counter);
        $display("        D cache use        : %10d ",chip.u_TOP.u_cpu.u_cpu_plug.MEM_use_counter);
        $display("        D cache miss rate  : %10f ",chip.u_TOP.u_cpu.u_cpu_plug.MEM_miss_counter*(100)/chip.u_TOP.u_cpu.u_cpu_plug.MEM_use_counter);
        $display("        I cache miss       : %10d ",chip.u_TOP.u_cpu.u_cpu_plug.IF_miss_counter);
        $display("        I cache use        : %10d ",chip.u_TOP.u_cpu.u_cpu_plug.IF_use_counter);
        $display("        I cache miss rate  : %10f ",chip.u_TOP.u_cpu.u_cpu_plug.IF_miss_counter*(100)/chip.u_TOP.u_cpu.u_cpu_plug.IF_use_counter);
      `endif
    end
  endtask
// ============================================================
// Compare Log Monitor
// cmp_log base address = 0x0002_E000
// dmem base address    = 0x0002_0000
// word index           = 0x3800
// ============================================================

`define CMP_LOG_BASE_WORD   32'h3800
`define CMP_LOG_MAGIC       32'hC0A60001

// result code from SSBL.c
`define CMP_RESULT_PASS     32'h5555_AAAA
`define CMP_RESULT_FAIL     32'hDEAD_0000

// phase code from SSBL.c
`define CMP_PHASE_NOERROR   32'h0000_0001
`define CMP_PHASE_ERROR     32'h0000_0002
`define CMP_PHASE_REALTEST  32'h0000_0003

// ------------------------------------------------------------
// TODO: 改成你真正的 DM memory path
// 例如：
// `define mem_word(IDX) top.u_soc.u_dmem.mem[IDX]
// `define mem_word(IDX) tb.u_dut.u_dmem.mem[IDX]
// ------------------------------------------------------------



// ------------------------------------------------------------
// cmp_log word offset
// ------------------------------------------------------------
// DM[BASE + 0] = magic
// DM[BASE + 1] = total_count
// DM[BASE + 2] = write_idx
//
// DM[BASE + 3] = last_phase
// DM[BASE + 4] = last_loop_id
// DM[BASE + 5] = last_iter
// DM[BASE + 6] = last_result
// DM[BASE + 7] = last_diff_offset
// DM[BASE + 8] = last_mem0_value
// DM[BASE + 9] = last_mem1_value
//
// entry[0] starts from BASE + 10
// each entry uses 8 words

reg [31:0] cmp_log_prev_count;
reg [31:0] cmp_log_magic;
reg [31:0] cmp_log_total_count;
reg [31:0] cmp_log_write_idx;

reg [31:0] cmp_log_last_phase;
reg [31:0] cmp_log_last_loop_id;
reg [31:0] cmp_log_last_iter;
reg [31:0] cmp_log_last_result;
reg [31:0] cmp_log_last_diff_offset;
reg [31:0] cmp_log_last_mem0_value;
reg [31:0] cmp_log_last_mem1_value;

initial begin
    cmp_log_prev_count = 32'h0;

    // 等 reset 結束，訊號名稱請依照你的 TB 修改
    wait (axi_rst === 1'b0);

    $display("[CMP_LOG_MON] Start monitor cmp_log at DM word index 0x%08h", `CMP_LOG_BASE_WORD);

    forever begin
        @(posedge axi_clk);

        cmp_log_magic       = `mem_word(`CMP_LOG_BASE_WORD + 0);
        cmp_log_total_count = `mem_word(`CMP_LOG_BASE_WORD + 1);

        // cmp_log_init() 跑完後 magic 會變成 0xC0A60001
        if (cmp_log_magic == `CMP_LOG_MAGIC) begin

            // total_count 有變化，代表 C code 剛寫入一筆新的 compare result
            if (cmp_log_total_count != cmp_log_prev_count) begin
                cmp_log_prev_count = cmp_log_total_count;

                cmp_log_write_idx         = `mem_word(`CMP_LOG_BASE_WORD + 2);
                cmp_log_last_phase        = `mem_word(`CMP_LOG_BASE_WORD + 3);
                cmp_log_last_loop_id      = `mem_word(`CMP_LOG_BASE_WORD + 4);
                cmp_log_last_iter         = `mem_word(`CMP_LOG_BASE_WORD + 5);
                cmp_log_last_result       = `mem_word(`CMP_LOG_BASE_WORD + 6);
                cmp_log_last_diff_offset  = `mem_word(`CMP_LOG_BASE_WORD + 7);
                cmp_log_last_mem0_value   = `mem_word(`CMP_LOG_BASE_WORD + 8);
                cmp_log_last_mem1_value   = `mem_word(`CMP_LOG_BASE_WORD + 9);

                $display("");
                $display("============================================================");
                $display("[CMP_LOG_MON] New compare result");
                $display("[CMP_LOG_MON] time        = %0t", $time);
                $display("[CMP_LOG_MON] total_count = %0d", cmp_log_total_count);
                $display("[CMP_LOG_MON] write_idx   = %0d", cmp_log_write_idx);
                $display("[CMP_LOG_MON] phase       = 0x%08h", cmp_log_last_phase);
                $display("[CMP_LOG_MON] loop_id     = %0d", cmp_log_last_loop_id);
                $display("[CMP_LOG_MON] iter        = %0d", cmp_log_last_iter);
                $display("[CMP_LOG_MON] result      = 0x%08h", cmp_log_last_result);
                $display("[CMP_LOG_MON] diff_offset = 0x%08h", cmp_log_last_diff_offset);
                $display("[CMP_LOG_MON] mem0_value  = 0x%08h", cmp_log_last_mem0_value);
                $display("[CMP_LOG_MON] mem1_value  = 0x%08h", cmp_log_last_mem1_value);

                if (cmp_log_last_phase == `CMP_PHASE_NOERROR) begin
                    $display("[CMP_LOG_MON] phase_name  = NOERROR_LOOP");
                end
                else if (cmp_log_last_phase == `CMP_PHASE_ERROR) begin
                    $display("[CMP_LOG_MON] phase_name  = ERROR_LOOP");
                end
                else if (cmp_log_last_phase == `CMP_PHASE_REALTEST) begin
                    $display("[CMP_LOG_MON] phase_name  = REAL_TEST_LOOP");
                end
                else begin
                    $display("[CMP_LOG_MON] phase_name  = UNKNOWN");
                end

                if (cmp_log_last_result == `CMP_RESULT_PASS) begin
                    $display("[CMP_LOG_MON] compare     = PASS");
                end
                else if (cmp_log_last_result == `CMP_RESULT_FAIL) begin
                    $display("[CMP_LOG_MON] compare     = FAIL");
                    $display("[CMP_LOG_MON] mismatch at byte offset 0x%08h", cmp_log_last_diff_offset);
                    $display("[CMP_LOG_MON] test   value = 0x%08h", cmp_log_last_mem0_value);
                    $display("[CMP_LOG_MON] golden value = 0x%08h", cmp_log_last_mem1_value);
                end
                else begin
                    $display("[CMP_LOG_MON] compare     = UNKNOWN");
                end

                $display("============================================================");
                $display("");
            end
        end
    end
end  


  
endmodule