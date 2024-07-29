/**
 * File              : axi_register_slice_tb.sv
 * License           : MIT license <Check LICENSE>
 * Author            : Anderson I. da Silva (aignacio) <anderson@aignacio.com>
 * Date              : 28.07.2024
 * Last Modified Date: 29.07.2024
 */
module axi_register_slice_tb
  import amba_axi_pkg::*;
#(
  parameter NUM_PIP_AW = 5, // [AW] Number of pipeline registers
  parameter NUM_PIP_AR = 5, // [AR] Number of pipeline registers
  parameter NUM_PIP_W  = 5, // [W]  Number of pipeline registers
  parameter NUM_PIP_R  = 5, // [R]  Number of pipeline registers
  parameter NUM_PIP_B  = 5  // [B]  Number of pipeline registers

)(
  input                                          clk,
  input                                          arst,
  // AXI in I/F
  // AXI Interface - MOSI
  // Write Address channel
  input  axi_tid_t                               slave_awid,
  input  axi_addr_t                              slave_awaddr,
  input  axi_alen_t                              slave_awlen,
  input  axi_size_t                              slave_awsize,
  input  axi_burst_t                             slave_awburst,
  input  logic                                   slave_awlock,
  input  logic        [3:0]                      slave_awcache,
  input  axi_prot_t                              slave_awprot,
  input  logic        [3:0]                      slave_awqos,
  input  logic        [3:0]                      slave_awregion,
  input  axi_user_req_t                          slave_awuser,
  input  logic                                   slave_awvalid,
  // Write Data channel
  input  axi_data_t                              slave_wdata,
  input  axi_wr_strb_t                           slave_wstrb,
  input  logic                                   slave_wlast,
  input  axi_user_data_t                         slave_wuser,
  input  logic                                   slave_wvalid,
  // Write Response channel
  input  logic                                   slave_bready,
  // Read Address channel
  input  axi_tid_t                               slave_arid,
  input  axi_addr_t                              slave_araddr,
  input  axi_alen_t                              slave_arlen,
  input  axi_size_t                              slave_arsize,
  input  axi_burst_t                             slave_arburst,
  input  logic                                   slave_arlock,
  input  logic        [3:0]                      slave_arcache,
  input  axi_prot_t                              slave_arprot,
  input  logic        [3:0]                      slave_arqos,
  input  logic        [3:0]                      slave_arregion,
  input  axi_user_req_t                          slave_aruser,
  input  logic                                   slave_arvalid,
  // Read Data channel
  input  logic                                   slave_rready,
  // AXI Interface - MISO
  // Write Addr channel
  output logic                                   slave_awready,
  // Write Data channel
  output logic                                   slave_wready,
  // Write Response channel
  output axi_tid_t                               slave_bid,
  output axi_resp_t                              slave_bresp,
  output axi_user_rsp_t                          slave_buser,
  output logic                                   slave_bvalid,
  // Read addr channel
  output logic                                   slave_arready,
  // Read data channel
  output axi_tid_t                               slave_rid,
  output axi_data_t                              slave_rdata,
  output axi_resp_t                              slave_rresp,
  output logic                                   slave_rlast,
  output axi_user_rsp_t                          slave_ruser,
  output logic                                   slave_rvalid,

  // AXI out I/F
  // AXI Interface - MOSI
  // Write Address channel
  output axi_tid_t                               master_awid,
  output axi_addr_t                              master_awaddr,
  output axi_alen_t                              master_awlen,
  output axi_size_t                              master_awsize,
  output axi_burst_t                             master_awburst,
  output logic                                   master_awlock,
  output logic        [3:0]                      master_awcache,
  output axi_prot_t                              master_awprot,
  output logic        [3:0]                      master_awqos,
  output logic        [3:0]                      master_awregion,
  output axi_user_req_t                          master_awuser,
  output logic                                   master_awvalid,
  // Write Data channel
  output axi_data_t                              master_wdata,
  output axi_wr_strb_t                           master_wstrb,
  output logic                                   master_wlast,
  output axi_user_data_t                         master_wuser,
  output logic                                   master_wvalid,
  // Write Response channel
  output logic                                   master_bready,
  // Read Address channel
  output axi_tid_t                               master_arid,
  output axi_addr_t                              master_araddr,
  output axi_alen_t                              master_arlen,
  output axi_size_t                              master_arsize,
  output axi_burst_t                             master_arburst,
  output logic                                   master_arlock,
  output logic        [3:0]                      master_arcache,
  output axi_prot_t                              master_arprot,
  output logic        [3:0]                      master_arqos,
  output logic        [3:0]                      master_arregion,
  output axi_user_req_t                          master_aruser,
  output logic                                   master_arvalid,
  // Read Data channel
  output logic                                   master_rready,
  // AXI Interface - MISO
  // Write Addr channel
  input  logic                                   master_awready,
  // Write Data channel
  input  logic                                   master_wready,
  // Write Response channel
  input  axi_tid_t                               master_bid,
  input  axi_resp_t                              master_bresp,
  input  axi_user_req_t                          master_buser,
  input  logic                                   master_bvalid,
  // Read addr channel
  input  logic                                   master_arready,
  // Read data channel
  input  axi_tid_t                               master_rid,
  input  axi_data_t                              master_rdata,
  input  axi_resp_t                              master_rresp,
  input  logic                                   master_rlast,
  input  axi_user_req_t                          master_ruser,
  input  logic                                   master_rvalid
);

  s_axi_mosi_t slave_mosi, master_mosi;
  s_axi_miso_t slave_miso, master_miso;

  // Slave connection
  assign slave_mosi.awid     = slave_awid;
  assign slave_mosi.awaddr   = slave_awaddr;
  assign slave_mosi.awlen    = slave_awlen;
  assign slave_mosi.awsize   = slave_awsize;
  assign slave_mosi.awburst  = slave_awburst;
  assign slave_mosi.awlock   = slave_awlock;
  assign slave_mosi.awcache  = slave_awcache;
  assign slave_mosi.awprot   = slave_awprot;
  assign slave_mosi.awqos    = slave_awqos;
  assign slave_mosi.awregion = slave_awregion;
  assign slave_mosi.awuser   = slave_awuser;
  assign slave_mosi.awvalid  = slave_awvalid;
  assign slave_mosi.wdata    = slave_wdata;
  assign slave_mosi.wstrb    = slave_wstrb;
  assign slave_mosi.wlast    = slave_wlast;
  assign slave_mosi.wuser    = slave_wuser;
  assign slave_mosi.wvalid   = slave_wvalid;
  assign slave_mosi.bready   = slave_bready;
  assign slave_mosi.arid     = slave_arid;
  assign slave_mosi.araddr   = slave_araddr;
  assign slave_mosi.arlen    = slave_arlen;
  assign slave_mosi.arsize   = slave_arsize;
  assign slave_mosi.arburst  = slave_arburst;
  assign slave_mosi.arlock   = slave_arlock;
  assign slave_mosi.arcache  = slave_arcache;
  assign slave_mosi.arprot   = slave_arprot;
  assign slave_mosi.arqos    = slave_arqos;
  assign slave_mosi.arregion = slave_arregion;
  assign slave_mosi.aruser   = slave_aruser;
  assign slave_mosi.arvalid  = slave_arvalid;
  assign slave_mosi.rready   = slave_rready;

  assign slave_awready       = slave_miso.awready;
  assign slave_wready        = slave_miso.wready;
  assign slave_bid           = slave_miso.bid;
  assign slave_bresp         = slave_miso.bresp;
  assign slave_buser         = slave_miso.buser;
  assign slave_bvalid        = slave_miso.bvalid;
  assign slave_arready       = slave_miso.arready;
  assign slave_rid           = slave_miso.rid;
  assign slave_rdata         = slave_miso.rdata;
  assign slave_rresp         = slave_miso.rresp;
  assign slave_rlast         = slave_miso.rlast;
  assign slave_ruser         = slave_miso.ruser;
  assign slave_rvalid        = slave_miso.rvalid;

  // Master connection
  assign master_awid     = master_mosi.awid;
  assign master_awaddr   = master_mosi.awaddr;
  assign master_awlen    = master_mosi.awlen;
  assign master_awsize   = master_mosi.awsize;
  assign master_awburst  = master_mosi.awburst;
  assign master_awlock   = master_mosi.awlock;
  assign master_awcache  = master_mosi.awcache;
  assign master_awprot   = master_mosi.awprot;
  assign master_awqos    = master_mosi.awqos;
  assign master_awregion = master_mosi.awregion;
  assign master_awuser   = master_mosi.awuser;
  assign master_awvalid  = master_mosi.awvalid;
  assign master_wdata    = master_mosi.wdata;
  assign master_wstrb    = master_mosi.wstrb;
  assign master_wlast    = master_mosi.wlast;
  assign master_wuser    = master_mosi.wuser;
  assign master_wvalid   = master_mosi.wvalid;
  assign master_bready   = master_mosi.bready;
  assign master_arid     = master_mosi.arid;
  assign master_araddr   = master_mosi.araddr;
  assign master_arlen    = master_mosi.arlen;
  assign master_arsize   = master_mosi.arsize;
  assign master_arburst  = master_mosi.arburst;
  assign master_arlock   = master_mosi.arlock;
  assign master_arcache  = master_mosi.arcache;
  assign master_arprot   = master_mosi.arprot;
  assign master_arqos    = master_mosi.arqos;
  assign master_arregion = master_mosi.arregion;
  assign master_aruser   = master_mosi.aruser;
  assign master_arvalid  = master_mosi.arvalid;
  assign master_rready   = master_mosi.rready;

  assign master_miso.awready = master_awready;
  assign master_miso.wready  = master_wready;
  assign master_miso.bid     = master_bid;
  assign master_miso.bresp   = master_bresp;
  assign master_miso.buser   = master_buser;
  assign master_miso.bvalid  = master_bvalid;
  assign master_miso.arready = master_arready;
  assign master_miso.rid     = master_rid;
  assign master_miso.rdata   = master_rdata;
  assign master_miso.rresp   = master_rresp;
  assign master_miso.rlast   = master_rlast;
  assign master_miso.ruser   = master_ruser;
  assign master_miso.rvalid  = master_rvalid;

  axi_register_slice #(
    .NUM_PIP_AW     (NUM_PIP_AW),
    .NUM_PIP_AR     (NUM_PIP_AR),
    .NUM_PIP_W      (NUM_PIP_W),
    .NUM_PIP_R      (NUM_PIP_R),
    .NUM_PIP_B      (NUM_PIP_B)
  ) u_axi_register_slice (
    .clk            (clk),
    .arst           (arst),
    // (Slave port) Master In
    .slave_mosi_i   (slave_mosi),
    .slave_miso_o   (slave_miso),
    // (Master port) Master Out
    .master_mosi_o  (master_mosi),
    .master_miso_i  (master_miso)
  );
endmodule
