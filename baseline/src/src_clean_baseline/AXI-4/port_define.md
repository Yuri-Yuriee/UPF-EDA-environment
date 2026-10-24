//******************************
//      slave port
//******************************
input [`AXI_ID_BITS-1:0] ARID,
input [`AXI_ADDR_BITS-1:0] ARADDR,
input [`AXI_LEN_BITS-1:0] ARLEN,
input [`AXI_SIZE_BITS-1:0] ARSIZE,
input [1:0] ARBURST,
input ARVALID,
output logic ARREADY,

output logic [`AXI_ID_BITS-1:0] RID,
output logic [`AXI_DATA_BITS-1:0] RDATA,
output logic [1:0] RRESP,
output logic RLAST,
output logic RVALID,
input RREADY,

input [`AXI_ID_BITS-1:0] AWID,
input [`AXI_ADDR_BITS-1:0] AWADDR,
input [`AXI_LEN_BITS-1:0] AWLEN,
input [`AXI_SIZE_BITS-1:0] AWSIZE,
input [1:0] AWBURST,
input AWVALID,
output logic AWREADY,


input [`AXI_DATA_BITS-1:0] WDATA,
input [`AXI_STRB_BITS-1:0] WSTRB,
input WLAST,
input WVALID,
output logic WREADY,

output logic [`AXI_ID_BITS-1:0] BID,
output logic [1:0] BRESP,
output logic BVALID,
input BREADY,

//******************************
//      Master port
//******************************

output logic [`AXI_IDS_BITS-1:0] ARID,
output logic [`AXI_ADDR_BITS-1:0] ARADDR,
output logic [`AXI_LEN_BITS-1:0] ARLEN,
output logic [`AXI_SIZE_BITS-1:0] ARSIZE,
output logic [1:0] ARBURST,
output logic ARVALID,
input ARREADY,

input [`AXI_IDS_BITS-1:0] RID,
input [`AXI_DATA_BITS-1:0] RDATA,
input [1:0] RRESP,
input RLAST,
input RVALID,
output logic RREADY,

output logic [`AXI_IDS_BITS-1:0] AWID,
output logic [`AXI_ADDR_BITS-1:0] AWADDR,
output logic [`AXI_LEN_BITS-1:0] AWLEN,
output logic [`AXI_SIZE_BITS-1:0] AWSIZE,
output logic [1:0] AWBURST,
output logic AWVALID,
input AWREADY,

output logic [`AXI_DATA_BITS-1:0] WDATA,
output logic [`AXI_STRB_BITS-1:0] WSTRB,
output logic WLAST,
output logic WVALID,
input WREADY,

input [`AXI_IDS_BITS-1:0] BID,
input [1:0] BRESP,
input BVALID,
output logic BREADY,