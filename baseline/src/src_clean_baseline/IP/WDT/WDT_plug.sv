`define WDEN_addr   32'h1001_0100
`define WDLIVE_addr 32'h1001_0200
`define WTOCNT_addr 32'h1001_0300
`define WDT_idle    2'd0
`define WDT_WDEN    2'd1
`define WDT_WDLIVE  2'd2
`define WDT_WTOCNT  2'd3

typedef enum logic[1:0] { 
    WDT_idle_T = 2'd0,
    WDT_WDEN_T = 2'd1,
    WDT_WDLIVE_T = 2'd2,
    WDT_WTOCNT_T = 2'd3
} WDT_mode;

module WDT_plug (
  //******************************
  //			from slave
  //******************************	
    input           clk, rst,
    output  [31:0]  read_data,
    input 	        Read_Enable,
    input   [31:0]  Addr,
    input   [31:0]  Write_data,
    input 	        Write_Enable,
    input   [3:0]   WSTRB,
    output miss,
    output hit, 
  //******************************
  //			to SRAM
  //******************************	
    input clk2, rst2,
    output WDEN,
    output WDLIVE,
    output [31:0] WTOCNT
  `ifdef WDT_PG  
  , output WDT_restore_pulse, WDT_restore_pulse_n,
    output WDT_save_pulse,
    output WDT_ON, WDT_OFF, WDT_ISO, WDT_CG
  `endif
);
wire wfull;
wire [33:0] clk1_WDT_data, clk2_WDT_data;
wire [1:0] clk1_mode, clk2_mode;
reg dff_WDEN;
reg [31:0] dff_WTOCNT;
reg rinc;
reg out_valid;
wire rempty;

  //******************************
  //			Signal Define
  //******************************	
    always @(posedge clk or posedge rst) begin
      if(rst)begin
        out_valid <= 1'b0;
      end
      else if(Read_Enable || (Write_Enable && !wfull))begin
        out_valid <= 1'b1;
      end
      else begin
        out_valid <= 1'b0;
      end
    end 
  //******************************
  //			Out Signal
  //******************************	
    assign miss = 1'b0;
    assign hit = (out_valid) ? 1'b1 : 1'b0;
    assign WDEN = dff_WDEN;
    assign WDLIVE = (clk2_mode==`WDT_WDLIVE && rinc && !rempty) ? clk2_WDT_data[0] : 1'd0;
    assign WTOCNT = dff_WTOCNT;
   //******************************
   //			Control Signal
   //******************************	

    assign clk1_WDT_data = {clk1_mode, Write_data};
    assign clk2_mode = clk2_WDT_data[33:32];

    asyc_FIFO #(.width(34)) system_2_WDT_cdc (
        .w_clk(clk), .w_rst(rst), .r_clk(clk2), .r_rst(rst2),
        .wdata(clk1_WDT_data), .winc(Write_Enable), 
        .rinc(rinc), .rempty(rempty), .rdata(clk2_WDT_data),
        .wfull(wfull)
    );

    `ifdef test
    WDT_mode clk1_mode_test, clk2_mode_test;
    assign clk1_mode_test =  (Write_Enable && Addr == `WDEN_addr) ? WDT_WDEN_T :
                        (Write_Enable && Addr == `WDLIVE_addr) ? WDT_WDLIVE_T :
                        (Write_Enable && Addr == `WTOCNT_addr) ? WDT_WTOCNT_T : WDT_idle_T;
    assign clk2_mode_test = clk2_mode;
    `endif

    assign clk1_mode =  (Write_Enable && Addr == `WDEN_addr) ? `WDT_WDEN :
                        (Write_Enable && Addr == `WDLIVE_addr) ? `WDT_WDLIVE :
                        (Write_Enable && Addr == `WTOCNT_addr) ? `WDT_WTOCNT : `WDT_idle;
    
    always @(posedge clk2 or posedge rst2) begin
        if(rst2)begin
            rinc <= 1'd0;
        end
        else if(!rempty)begin
            rinc <= 1'd1;
        end
        else begin
            rinc <= 1'd0;
        end
    end

    // input dff
    always @(posedge clk2 or posedge rst2)begin
        if(rst2)begin
            dff_WDEN <= 1'd0;
            dff_WTOCNT <= 32'd0;
        end
        else begin
          if(rinc & !rempty)begin
            case (clk2_mode)
                `WDT_WDEN : dff_WDEN <= clk2_WDT_data[0];
                `WDT_WDLIVE : begin
                end
                `WDT_WTOCNT : dff_WTOCNT <= clk2_WDT_data[31:0];
                default: begin
                end
            endcase
          end
          else begin
            dff_WDEN <= dff_WDEN;
            dff_WTOCNT <= dff_WTOCNT;
          end
      end
    end

`ifdef WDT_PG
  typedef enum logic[2:0] { 
    WDT_PG_ON,
    WDT_PG_SAVE_ON,
    WDT_PG_SAVE,
    WDT_PG_SAVE_OFF,
    WDT_PG_OFF,
    WDT_PG_RESTORE_ON,
    WDT_PG_RESTORE,
    WDT_PG_RESTORE_OFF
  } WDT_PG_ST;

  WDT_PG_ST WDT_PG_state, WDT_PG_next_state;
  assign WDT_restore_pulse  = (WDT_PG_state == WDT_PG_RESTORE) ? 1'b1 : 1'b0;
  assign WDT_save_pulse     = (WDT_PG_state == WDT_PG_SAVE) ? 1'b1 : 1'b0;
  assign WDT_ON             = ~WDT_OFF;
  assign WDT_OFF            = (WDT_PG_state == WDT_PG_OFF) ? 1'b1 : 1'b0;
  assign WDT_ISO            = WDT_OFF | WDT_CG;
  assign WDT_restore_pulse_n = ~WDT_restore_pulse;
  assign WDT_CG             = (WDT_PG_state == WDT_PG_SAVE_ON) | (WDT_PG_state == WDT_PG_SAVE) | (WDT_PG_state == WDT_PG_SAVE_OFF) | 
                              (WDT_PG_state == WDT_PG_RESTORE_ON) | (WDT_PG_state == WDT_PG_RESTORE) | (WDT_PG_state == WDT_PG_RESTORE_OFF); 

  always @(posedge clk2 or posedge rst2) begin
    if(rst2)begin
      WDT_PG_state <= WDT_PG_ON;
    end
    else begin
      WDT_PG_state <= WDT_PG_next_state;
    end
  end

  always @(*) begin
    case (WDT_PG_state)
    WDT_PG_ON : if(!WDEN)begin
      WDT_PG_next_state = WDT_PG_SAVE_ON;
    end
    else begin
      WDT_PG_next_state = WDT_PG_ON;
    end
    WDT_PG_SAVE_ON :  WDT_PG_next_state = WDT_PG_SAVE;
    WDT_PG_SAVE :     WDT_PG_next_state = WDT_PG_SAVE_OFF;
    WDT_PG_SAVE_OFF : WDT_PG_next_state = WDT_PG_OFF;
    WDT_PG_OFF : if(WDEN)begin
      WDT_PG_next_state = WDT_PG_RESTORE_ON;
    end
    else begin
      WDT_PG_next_state = WDT_PG_OFF;
    end
    WDT_PG_RESTORE_ON :     WDT_PG_next_state = WDT_PG_RESTORE;
    WDT_PG_RESTORE :        WDT_PG_next_state = WDT_PG_RESTORE_OFF;
    WDT_PG_RESTORE_OFF :    WDT_PG_next_state = WDT_PG_ON;
    default :           WDT_PG_next_state = WDT_PG_ON;
    endcase
  end
`endif 




endmodule