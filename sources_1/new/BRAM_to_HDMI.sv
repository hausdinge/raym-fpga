`timescale 1ns / 1ps

module BRAM_to_HDMI #(
H_RES = 640, 
V_RES = 480
)(
input logic clk, 
input logic pix_clk, 
input logic signed [15:0] i_x, 
input logic signed [15:0] i_y, 
input logic en_write_framebuffer,
input logic [5:0] framebuffer_data,
input logic [19:0] framebuffer_addr,
output logic [7:0] o_red, 
output logic [7:0] o_green, 
output logic [7:0] o_blue
);

  localparam resolution = H_RES*V_RES;
 
  logic clka, clkb;
  logic [0:0] wea, web;
  logic [19:0] addra, addrb;
  logic [5:0] dina, dinb;
  logic [5:0] douta, doutb;
  logic [19:0] addr_read_count = 1;
  
  assign clka = clk;
  assign wea = en_write_framebuffer;
  assign addra = framebuffer_addr;
  assign dina = framebuffer_data;
     
  assign clkb = pix_clk;
  assign web = 0;
  assign dinb = 0;
  assign addrb =  (i_x >= 0) && (i_x < H_RES) && (i_y >= 0) && (i_y < V_RES) ?  H_RES*i_y+i_x: 999999;
  
  
  /*always_ff @(posedge clkb) begin
    
     addrb <=  (i_x >= 0) && (i_x < H_RES) && (i_y >= 0) && (i_y < V_RES) ?  H_RES*i_y+i_x: 999999;
    //addr_read_count <= (i_x >= 0) && (i_x < H_RES) && (i_y >= 0) && (i_y < V_RES) ?  H_RES*i_y+i_x: addr_read_count;
    //addrb <= (addr_read_count >= resolution + 1) ? (addr_read_count == resolution ? 0 : (addr_read_count == resolution + 1 ? 1 : 2)) : addr_read_count;
  end*/
 
  blk_mem_gen_0 framebuffer (
   .clka(clka),    // input wire clka
   .wea(wea),      // input wire [0 : 0] wea
   .addra(addra),  // input wire [19 : 0] addra
   .dina(dina),    // input wire [5 : 0] dina
   .douta(douta),  // output wire [5 : 0] douta
   .clkb(clkb),    // input wire clkb
   .web(web),      // input wire [0 : 0] web
   .addrb(addrb),  // input wire [19 : 0] addrb
   .dinb(dinb),    // input wire [5 : 0] dinb
   .doutb(doutb)   // output wire [5 : 0] doutb
  );
  
  logic [23:0] rgb_table[0:23] = {
    24'h000000,
    24'h0b0b0b,
    24'h161616,
    24'h212121,
    24'h2c2c2c,
    24'h373737,
    24'h434343,
    24'h4e4e4e,
    24'h595959,
    24'h646464,
    24'h6f6f6f,
    24'h7a7a7a,
    24'h858585,
    24'h909090,
    24'h9b9b9b,
    24'ha6a6a6,
    24'hb1b1b1,
    24'hbcbcbc,
    24'hc8c8c8,
    24'hd3d3d3,
    24'hdedede,
    24'he9e9e9,
    24'hf4f4f4,
    24'hffffff
  };
  
  assign {o_red, o_green, o_blue} = rgb_table[doutb];
endmodule