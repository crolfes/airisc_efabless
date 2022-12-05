// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_airisc #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] rdata; 
    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wbs_dat_o = rdata;
    assign wdata = wbs_dat_i;

    // IO
    assign io_out = count;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign la_data_out = {{(127-BITS){1'b0}}, count};
    // Assuming LA probes [63:32] are for controlling the count register  
    assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

    airi5c_top_asic DUT
    (
        .clk(clktree_root),
        .nreset(~reset_sync),
        .testmode(1'b0),    
        .ext_interrupt(interrupt_sync),    
    
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),

        .imem_haddr(imem_haddr),
        .imem_hwrite(imem_hwrite),
        .imem_hsize(imem_hsize),
        .imem_hburst(imem_hburst),
        .imem_hmastlock(imem_hmastlock),
        .imem_hprot(imem_hprot),
        .imem_htrans(imem_htrans),
        .imem_hwdata(imem_hwdata),
        .imem_hrdata(imem_hrdata),
        .imem_hready(1'b1),
        .imem_hresp(`HASTI_RESP_OKAY),
    
        .dmem_haddr(dmem_haddr),
        .dmem_hwrite(dmem_hwrite),
        .dmem_hsize(dmem_hsize),
        .dmem_hburst(dmem_hburst),
        .dmem_hmastlock(dmem_hmastlock),
        .dmem_hprot(dmem_hprot),
        .dmem_htrans(dmem_htrans),
        .dmem_hwdata(dmem_hwdata),
        .dmem_hrdata(dmem_hrdata_shifted),  
        .dmem_hready(dmem_hready),
        .dmem_hresp(`HASTI_RESP_OKAY),
       
    
        .oGPIO_D(gpio_d),
        .oGPIO_EN(),
        .iGPIO_I(gpio_i),

        .oUART_TX(uart_tx),
        .iUART_RX(uart_rx),

        .oSPI1_MOSI(spi_mosi),
        .oSPI1_SCLK(spi_sclk),
        .oSPI1_NSS(spi_nss),
        .iSPI1_MISO(spi_miso),
     
        .debug_out(debug_out)
    );

endmodule

`default_nettype wire
