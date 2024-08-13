
module axi_register_slice
  import amba_axi_pkg::*;
#(
  parameter NUM_PIP_AW = 0, // [AW] Number of pipeline registers
  parameter NUM_PIP_AR = 0, // [AR] Number of pipeline registers
  parameter NUM_PIP_W  = 0, // [W]  Number of pipeline registers
  parameter NUM_PIP_R  = 0, // [R]  Number of pipeline registers
  parameter NUM_PIP_B  = 0  // [B]  Number of pipeline registers
)(
  input                 clk,
  input                 arst,
  // (Slave port) Master In
  input   s_axi_mosi_t  slave_mosi_i,
  output  s_axi_miso_t  slave_miso_o,

  // (Master port) Master Out
  output  s_axi_mosi_t  master_mosi_o,
  input   s_axi_miso_t  master_miso_i
);
  localparam AR_CHN_WIDTH = $bits({ slave_mosi_i.arid,
                                    slave_mosi_i.araddr,
                                    slave_mosi_i.arlen,
                                    slave_mosi_i.arsize,
                                    slave_mosi_i.arburst,
                                    slave_mosi_i.arlock,
                                    slave_mosi_i.arcache,
                                    slave_mosi_i.arprot,
                                    slave_mosi_i.arqos,
                                    slave_mosi_i.arregion,
                                    slave_mosi_i.aruser});

  localparam AW_CHN_WIDTH = $bits({ slave_mosi_i.awid,
                                    slave_mosi_i.awaddr,
                                    slave_mosi_i.awlen,
                                    slave_mosi_i.awsize,
                                    slave_mosi_i.awburst,
                                    slave_mosi_i.awlock,
                                    slave_mosi_i.awcache,
                                    slave_mosi_i.awprot,
                                    slave_mosi_i.awqos,
                                    slave_mosi_i.awregion,
                                    slave_mosi_i.awuser});

  localparam W_CHN_WIDTH = $bits({  slave_mosi_i.wdata,
                                    slave_mosi_i.wstrb,
                                    slave_mosi_i.wlast,
                                    slave_mosi_i.wuser
  });

  localparam R_CHN_WIDTH = $bits({  slave_miso_o.rid,
                                    slave_miso_o.rdata,
                                    slave_miso_o.rresp,
                                    slave_miso_o.rlast
  });

  localparam B_CHN_WIDTH = $bits({  slave_miso_o.bid,
                                    slave_miso_o.bresp
  });

  // ----------------------------------
  //  AR - Address Read Channel
  // ----------------------------------
  logic [AR_CHN_WIDTH-1:0] in_ar_ch, out_ar_ch;

  typedef struct packed {
    logic [AR_CHN_WIDTH-1:0] data;
    logic                    valid;
    logic                    ready;
  } s_ar_stage_t;

  assign in_ar_ch = {
    slave_mosi_i.arid,
    slave_mosi_i.araddr,
    slave_mosi_i.arlen,
    slave_mosi_i.arsize,
    slave_mosi_i.arburst,
    slave_mosi_i.arlock,
    slave_mosi_i.arcache,
    slave_mosi_i.arprot,
    slave_mosi_i.arqos,
    slave_mosi_i.arregion,
    slave_mosi_i.aruser
  };

  generate
    if (NUM_PIP_AR <= 1) begin
      skid_buffer #(
        .type_t       (logic [AR_CHN_WIDTH-1:0]),
        .REG_OUTPUT(NUM_PIP_AR)
      ) u_ar_pip (
        .clk          (clk),
        .rst          (arst),
        .in_valid_i   (slave_mosi_i.arvalid),
        .in_ready_o   (slave_miso_o.arready),
        .in_data_i    (in_ar_ch),
        .out_valid_o  (master_mosi_o.arvalid),
        .out_ready_i  (master_miso_i.arready),
        .out_data_o   (out_ar_ch)
      );

      assign {master_mosi_o.arid,
              master_mosi_o.araddr,
              master_mosi_o.arlen,
              master_mosi_o.arsize,
              master_mosi_o.arburst,
              master_mosi_o.arlock,
              master_mosi_o.arcache,
              master_mosi_o.arprot,
              master_mosi_o.arqos,
              master_mosi_o.arregion,
              master_mosi_o.aruser} = out_ar_ch;
    end
    else begin
      s_ar_stage_t [NUM_PIP_AR-1:0] ar_stages;

      for (genvar ar_idx = 0; ar_idx < NUM_PIP_AR; ar_idx++) begin
        if (ar_idx == 0) begin : ar_first_stage
          skid_buffer #(
            .type_t       (logic [AR_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_ar_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (slave_mosi_i.arvalid),
            .in_ready_o   (slave_miso_o.arready),
            .in_data_i    (in_ar_ch),
            .out_valid_o  (ar_stages[0].valid),
            .out_ready_i  (ar_stages[0].ready),
            .out_data_o   (ar_stages[0].data)
          );
        end : ar_first_stage
        else if (ar_idx == (NUM_PIP_AR-1)) begin : ar_last_stage
          skid_buffer #(
            .type_t       (logic [AR_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_ar_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (ar_stages[ar_idx-1].valid),
            .in_ready_o   (ar_stages[ar_idx-1].ready),
            .in_data_i    (ar_stages[ar_idx-1].data),
            .out_valid_o  (ar_stages[ar_idx].valid),
            .out_ready_i  (ar_stages[ar_idx].ready),
            .out_data_o   (ar_stages[ar_idx].data)
          );

          assign {master_mosi_o.arid,
                  master_mosi_o.araddr,
                  master_mosi_o.arlen,
                  master_mosi_o.arsize,
                  master_mosi_o.arburst,
                  master_mosi_o.arlock,
                  master_mosi_o.arcache,
                  master_mosi_o.arprot,
                  master_mosi_o.arqos,
                  master_mosi_o.arregion,
                  master_mosi_o.aruser} = ar_stages[ar_idx].data;
          assign master_mosi_o.arvalid = ar_stages[ar_idx].valid;
          assign ar_stages[ar_idx].ready = master_miso_i.arready;
        end : ar_last_stage
        else begin : ar_mid_stage
          skid_buffer #(
            .type_t       (logic [AR_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_ar_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (ar_stages[ar_idx-1].valid),
            .in_ready_o   (ar_stages[ar_idx-1].ready),
            .in_data_i    (ar_stages[ar_idx-1].data),
            .out_valid_o  (ar_stages[ar_idx].valid),
            .out_ready_i  (ar_stages[ar_idx].ready),
            .out_data_o   (ar_stages[ar_idx].data)
          );
        end : ar_mid_stage
      end
    end
  endgenerate

  // ----------------------------------
  //  AW - Address Write Channel
  // ----------------------------------
  logic [AW_CHN_WIDTH-1:0] in_aw_ch, out_aw_ch;

  typedef struct packed {
    logic [AW_CHN_WIDTH-1:0] data;
    logic                    valid;
    logic                    ready;
  } s_aw_stage_t;

  assign in_aw_ch = {
    slave_mosi_i.awid,
    slave_mosi_i.awaddr,
    slave_mosi_i.awlen,
    slave_mosi_i.awsize,
    slave_mosi_i.awburst,
    slave_mosi_i.awlock,
    slave_mosi_i.awcache,
    slave_mosi_i.awprot,
    slave_mosi_i.awqos,
    slave_mosi_i.awregion,
    slave_mosi_i.awuser
  };

  generate
    if (NUM_PIP_AW <= 1) begin
      skid_buffer #(
        .type_t       (logic [AW_CHN_WIDTH-1:0]),
        .REG_OUTPUT(NUM_PIP_AW)
      ) u_aw_pip (
        .clk          (clk),
        .rst          (arst),
        .in_valid_i   (slave_mosi_i.awvalid),
        .in_ready_o   (slave_miso_o.awready),
        .in_data_i    (in_aw_ch),
        .out_valid_o  (master_mosi_o.awvalid),
        .out_ready_i  (master_miso_i.awready),
        .out_data_o   (out_aw_ch)
      );

      assign {master_mosi_o.awid,
              master_mosi_o.awaddr,
              master_mosi_o.awlen,
              master_mosi_o.awsize,
              master_mosi_o.awburst,
              master_mosi_o.awlock,
              master_mosi_o.awcache,
              master_mosi_o.awprot,
              master_mosi_o.awqos,
              master_mosi_o.awregion,
              master_mosi_o.awuser} = out_aw_ch;
    end
    else begin
      s_aw_stage_t [NUM_PIP_AW-1:0] aw_stages;

      for (genvar aw_idx = 0; aw_idx < NUM_PIP_AW; aw_idx++) begin
        if (aw_idx == 0) begin : aw_first_stage
          skid_buffer #(
            .type_t       (logic [AW_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_aw_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (slave_mosi_i.awvalid),
            .in_ready_o   (slave_miso_o.awready),
            .in_data_i    (in_aw_ch),
            .out_valid_o  (aw_stages[0].valid),
            .out_ready_i  (aw_stages[0].ready),
            .out_data_o   (aw_stages[0].data)
          );
        end : aw_first_stage
        else if (aw_idx == (NUM_PIP_AW-1)) begin : aw_last_stage
          skid_buffer #(
            .type_t       (logic [AW_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_aw_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (aw_stages[aw_idx-1].valid),
            .in_ready_o   (aw_stages[aw_idx-1].ready),
            .in_data_i    (aw_stages[aw_idx-1].data),
            .out_valid_o  (aw_stages[aw_idx].valid),
            .out_ready_i  (aw_stages[aw_idx].ready),
            .out_data_o   (aw_stages[aw_idx].data)
          );

          assign {master_mosi_o.awid,
                  master_mosi_o.awaddr,
                  master_mosi_o.awlen,
                  master_mosi_o.awsize,
                  master_mosi_o.awburst,
                  master_mosi_o.awlock,
                  master_mosi_o.awcache,
                  master_mosi_o.awprot,
                  master_mosi_o.awqos,
                  master_mosi_o.awregion,
                  master_mosi_o.awuser} = aw_stages[aw_idx].data;
          assign master_mosi_o.awvalid = aw_stages[aw_idx].valid;
          assign aw_stages[aw_idx].ready = master_miso_i.awready;
        end : aw_last_stage
        else begin : aw_mid_stage
          skid_buffer #(
            .type_t       (logic [AW_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_aw_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (aw_stages[aw_idx-1].valid),
            .in_ready_o   (aw_stages[aw_idx-1].ready),
            .in_data_i    (aw_stages[aw_idx-1].data),
            .out_valid_o  (aw_stages[aw_idx].valid),
            .out_ready_i  (aw_stages[aw_idx].ready),
            .out_data_o   (aw_stages[aw_idx].data)
          );
        end : aw_mid_stage
      end
    end
  endgenerate

  // ----------------------------------
  // W - Write Data Channel
  // ----------------------------------
  logic [W_CHN_WIDTH-1:0] in_w_ch, out_w_ch;

  typedef struct packed {
    logic [W_CHN_WIDTH-1:0] data;
    logic                   valid;
    logic                   ready;
  } s_w_stage_t;

  assign in_w_ch = {
    slave_mosi_i.wdata,
    slave_mosi_i.wstrb,
    slave_mosi_i.wlast,
    slave_mosi_i.wuser
  };

  generate
    if (NUM_PIP_W <= 1) begin
      skid_buffer #(
        .type_t       (logic [W_CHN_WIDTH-1:0]),
        .REG_OUTPUT(NUM_PIP_W)
      ) u_aw_pip (
        .clk          (clk),
        .rst          (arst),
        .in_valid_i   (slave_mosi_i.wvalid),
        .in_ready_o   (slave_miso_o.wready),
        .in_data_i    (in_w_ch),
        .out_valid_o  (master_mosi_o.wvalid),
        .out_ready_i  (master_miso_i.wready),
        .out_data_o   (out_w_ch)
      );

      assign {master_mosi_o.wdata,
              master_mosi_o.wstrb,
              master_mosi_o.wlast,
              master_mosi_o.wuser} = out_w_ch;
    end
    else begin
      s_w_stage_t [NUM_PIP_W-1:0] w_stages;

      for (genvar w_idx = 0; w_idx < NUM_PIP_W; w_idx++) begin
        if (w_idx == 0) begin : w_first_stage
          skid_buffer #(
            .type_t       (logic [W_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_w_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (slave_mosi_i.wvalid),
            .in_ready_o   (slave_miso_o.wready),
            .in_data_i    (in_w_ch),
            .out_valid_o  (w_stages[0].valid),
            .out_ready_i  (w_stages[0].ready),
            .out_data_o   (w_stages[0].data)
          );
        end : w_first_stage
        else if (w_idx == (NUM_PIP_W-1)) begin : w_last_stage
          skid_buffer #(
            .type_t       (logic [W_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_w_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (w_stages[w_idx-1].valid),
            .in_ready_o   (w_stages[w_idx-1].ready),
            .in_data_i    (w_stages[w_idx-1].data),
            .out_valid_o  (w_stages[w_idx].valid),
            .out_ready_i  (w_stages[w_idx].ready),
            .out_data_o   (w_stages[w_idx].data)
          );

          assign {master_mosi_o.wdata,
                  master_mosi_o.wstrb,
                  master_mosi_o.wlast,
                  master_mosi_o.wuser} = w_stages[w_idx].data;
          assign master_mosi_o.wvalid = w_stages[w_idx].valid;
          assign w_stages[w_idx].ready = master_miso_i.wready;
        end : w_last_stage
        else begin : w_mid_stage
          skid_buffer #(
            .type_t       (logic [W_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_w_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (w_stages[w_idx-1].valid),
            .in_ready_o   (w_stages[w_idx-1].ready),
            .in_data_i    (w_stages[w_idx-1].data),
            .out_valid_o  (w_stages[w_idx].valid),
            .out_ready_i  (w_stages[w_idx].ready),
            .out_data_o   (w_stages[w_idx].data)
          );
        end : w_mid_stage
      end
    end
  endgenerate

  // ----------------------------------
  // R - Read Data Channel
  // ----------------------------------
  logic [R_CHN_WIDTH-1:0] in_r_ch, out_r_ch;

  typedef struct packed {
    logic [R_CHN_WIDTH-1:0] data;
    logic                   valid;
    logic                   ready;
  } s_r_stage_t;

  assign in_r_ch = {
    master_miso_i.rid,
    master_miso_i.rdata,
    master_miso_i.rresp,
    master_miso_i.rlast
  };

  generate
    if (NUM_PIP_R <= 1) begin
      skid_buffer #(
        .type_t       (logic [R_CHN_WIDTH-1:0]),
        .REG_OUTPUT(NUM_PIP_R)
      ) u_r_pip (
        .clk          (clk),
        .rst          (arst),
        .in_valid_i   (master_miso_i.rvalid),
        .in_ready_o   (master_mosi_o.rready),
        .in_data_i    (in_r_ch),
        .out_valid_o  (slave_miso_o.rvalid),
        .out_ready_i  (slave_mosi_i.rready),
        .out_data_o   (out_r_ch)
      );

      assign {slave_miso_o.rid,
              slave_miso_o.rdata,
              slave_miso_o.rresp,
              slave_miso_o.rlast} = out_r_ch;
    end
    else begin
      s_r_stage_t [NUM_PIP_R-1:0] r_stages;

      for (genvar r_idx = 0; r_idx < NUM_PIP_R; r_idx++) begin
        if (r_idx == 0) begin : r_first_stage
          skid_buffer #(
            .type_t       (logic [R_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_r_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (master_miso_i.rvalid),
            .in_ready_o   (master_mosi_o.rready),
            .in_data_i    (in_r_ch),
            .out_valid_o  (r_stages[0].valid),
            .out_ready_i  (r_stages[0].ready),
            .out_data_o   (r_stages[0].data)
          );
        end : r_first_stage
        else if (r_idx == (NUM_PIP_R-1)) begin : r_last_stage
          skid_buffer #(
            .type_t       (logic [R_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_r_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (r_stages[r_idx-1].valid),
            .in_ready_o   (r_stages[r_idx-1].ready),
            .in_data_i    (r_stages[r_idx-1].data),
            .out_valid_o  (r_stages[r_idx].valid),
            .out_ready_i  (r_stages[r_idx].ready),
            .out_data_o   (r_stages[r_idx].data)
          );

          assign {slave_miso_o.rid,
                  slave_miso_o.rdata,
                  slave_miso_o.rresp,
                  slave_miso_o.rlast} = r_stages[r_idx].data;
          assign slave_miso_o.rvalid = r_stages[r_idx].valid;
          assign r_stages[r_idx].ready = slave_mosi_i.rready;
        end : r_last_stage
        else begin : r_mid_stage
          skid_buffer #(
            .type_t       (logic [R_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_r_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (r_stages[r_idx-1].valid),
            .in_ready_o   (r_stages[r_idx-1].ready),
            .in_data_i    (r_stages[r_idx-1].data),
            .out_valid_o  (r_stages[r_idx].valid),
            .out_ready_i  (r_stages[r_idx].ready),
            .out_data_o   (r_stages[r_idx].data)
          );
        end : r_mid_stage
      end
    end
  endgenerate

  // ----------------------------------
  // B - Write Response Channel
  // ----------------------------------
  logic [B_CHN_WIDTH-1:0] in_b_ch, out_b_ch;

  typedef struct packed {
    logic [B_CHN_WIDTH-1:0] data;
    logic                   valid;
    logic                   ready;
  } s_b_stage_t;

  assign in_b_ch = {
    master_miso_i.bid,
    master_miso_i.bresp
  };

  generate
    if (NUM_PIP_B <= 1) begin
      skid_buffer #(
        .type_t       (logic [B_CHN_WIDTH-1:0]),
        .REG_OUTPUT(NUM_PIP_B)
      ) u_b_pip (
        .clk          (clk),
        .rst          (arst),
        .in_valid_i   (master_miso_i.bvalid),
        .in_ready_o   (master_mosi_o.bready),
        .in_data_i    (in_b_ch),
        .out_valid_o  (slave_miso_o.bvalid),
        .out_ready_i  (slave_mosi_i.bready),
        .out_data_o   (out_b_ch)
      );

      assign {slave_miso_o.bid,
              slave_miso_o.bresp} = out_b_ch;
    end
    else begin
      s_b_stage_t [NUM_PIP_B-1:0] b_stages;

      for (genvar b_idx = 0; b_idx < NUM_PIP_B; b_idx++) begin
        if (b_idx == 0) begin : b_first_stage
          skid_buffer #(
            .type_t       (logic [B_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_b_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (master_miso_i.bvalid),
            .in_ready_o   (master_mosi_o.bready),
            .in_data_i    (in_b_ch),
            .out_valid_o  (b_stages[0].valid),
            .out_ready_i  (b_stages[0].ready),
            .out_data_o   (b_stages[0].data)
          );
        end : b_first_stage
        else if (b_idx == (NUM_PIP_B-1)) begin : b_last_stage
          skid_buffer #(
            .type_t       (logic [B_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_b_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (b_stages[b_idx-1].valid),
            .in_ready_o   (b_stages[b_idx-1].ready),
            .in_data_i    (b_stages[b_idx-1].data),
            .out_valid_o  (b_stages[b_idx].valid),
            .out_ready_i  (b_stages[b_idx].ready),
            .out_data_o   (b_stages[b_idx].data)
          );

          assign {slave_miso_o.bid,
                  slave_miso_o.bresp} = b_stages[b_idx].data;
          assign slave_miso_o.bvalid = b_stages[b_idx].valid;
          assign b_stages[b_idx].ready = slave_mosi_i.bready;
        end : b_last_stage
        else begin : b_mid_stage
          skid_buffer #(
            .type_t       (logic [B_CHN_WIDTH-1:0]),
            .REG_OUTPUT(1)
          ) u_b_pip (
            .clk          (clk),
            .rst          (arst),
            .in_valid_i   (b_stages[b_idx-1].valid),
            .in_ready_o   (b_stages[b_idx-1].ready),
            .in_data_i    (b_stages[b_idx-1].data),
            .out_valid_o  (b_stages[b_idx].valid),
            .out_ready_i  (b_stages[b_idx].ready),
            .out_data_o   (b_stages[b_idx].data)
          );
        end : b_mid_stage
      end
    end
  endgenerate
endmodule
