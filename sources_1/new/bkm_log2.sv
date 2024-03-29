`timescale 1ns / 1ps

//latency: width + 7 = 39 clock cycles
module bkm_log2(
input logic in_valid, 
input logic clk, 
input fixedpoint::number num1, 
output fixedpoint::number log2, 
output logic out_valid
);

  // BKM pipeline stages
  localparam width = 32;
  
  // log2(1+2^(-n))
  fixedpoint::number log2_table [0:width-1] = '{
    65'b00000000000000000000000000000000100000000000000000000000000000000,
    65'b00000000000000000000000000000000010010101110000000001101000111001,
    65'b00000000000000000000000000000000001010010011010011110000100101111,
    65'b00000000000000000000000000000000000101011100000000011010001110011,
    65'b00000000000000000000000000000000000010110011000111111011011111010,
    65'b00000000000000000000000000000000000001011010111010110100110111010,
    65'b00000000000000000000000000000000000000101101110011110010110100001,
    65'b00000000000000000000000000000000000000010110111111100101000010110,
    65'b00000000000000000000000000000000000000001011100001001110001000110,
    65'b00000000000000000000000000000000000000000101110000111110000011111,
    65'b00000000000000000000000000000000000000000010111000100100110010100,
    65'b00000000000000000000000000000000000000000001011100010011110101100,
    65'b00000000000000000000000000000000000000000000101110001010010001110,
    65'b00000000000000000000000000000000000000000000010111000101001110101,
    65'b00000000000000000000000000000000000000000000001011100010101000110,
    65'b00000000000000000000000000000000000000000000000101110001010100110,
    65'b00000000000000000000000000000000000000000000000010111000101010011,
    65'b00000000000000000000000000000000000000000000000001011100010101010,
    65'b00000000000000000000000000000000000000000000000000101110001010101,
    65'b00000000000000000000000000000000000000000000000000010111000101010,
    65'b00000000000000000000000000000000000000000000000000001011100010101,
    65'b00000000000000000000000000000000000000000000000000000101110001010,
    65'b00000000000000000000000000000000000000000000000000000010111000101,
    65'b00000000000000000000000000000000000000000000000000000001011100010,
    65'b00000000000000000000000000000000000000000000000000000000101110001,
    65'b00000000000000000000000000000000000000000000000000000000010111000,
    65'b00000000000000000000000000000000000000000000000000000000001011100,
    65'b00000000000000000000000000000000000000000000000000000000000101110,
    65'b00000000000000000000000000000000000000000000000000000000000010111,
    65'b00000000000000000000000000000000000000000000000000000000000001011,
    65'b00000000000000000000000000000000000000000000000000000000000000101,
    65'b00000000000000000000000000000000000000000000000000000000000000010
  };
  
  fixedpoint::number x [0:width-1];
  fixedpoint::number y [0:width-1];
  fixedpoint::number val [0:width-1];
  fixedpoint::number num1_reg [0:6];
  
  // need leading one to normalize number
  logic [5:0] leadingone_index;
  logic signed [6:0] back_shift [0:width-1];
  logic signed [6:0] shift;
  logic valid_leadingone;
  logic [width+6:0] out_valid_reg = 0;
  
  fixedpoint_MSB_index2 leadingone(in_valid, clk, num1, leadingone_index, valid_leadingone);
  
  // Get leading one index relative to the binary point
  assign shift = fixedpoint::fractional_bits - leadingone_index;
  
  always_ff @(posedge clk) begin
    out_valid_reg <= (out_valid_reg << 1'b1) + 1'b1;
  end
  
  always_ff @(posedge clk) begin
    num1_reg[0] <= num1 < 0 ? -num1 : num1;
    for(int i = 0; i < 6; i++) begin
      num1_reg[i+1] <= num1_reg[i];
    end
  end
  
  // perform BKM algorithm to find log2(x)
  always_ff @(posedge clk) begin
    if(valid_leadingone) begin
      back_shift[0] <= fixedpoint::fractional_bits - leadingone_index;
      x[0] <= fixedpoint::fromInt(1);  
      y[0] <= 0;                       
      val[0] <= (shift >= 0) ? (num1_reg[6]<< shift) : (num1_reg[6]>> (-shift));
      for(int i = 0; i < width-1; i++) begin
        x[i+1] <= ((x[i]  + (x[i]>>i)) <= val[i]) ? (x[i]  + (x[i]>>i)) : x[i];
        y[i+1] <= ((x[i]  + (x[i]>>i)) <= val[i]) ? y[i] + log2_table[i] : y[i];
        val[i+1] <= val[i];
        back_shift[i+1] <= back_shift[i];
      end 
    end
  end
  
  // When results are ready
  always_comb begin
    log2 = 1'b0;
    out_valid = 1'b0;
    if(out_valid_reg[width+6]) begin
      // back shift to get the denormalized result (here not a shift, but an addition)
      log2 = (back_shift[width-1] >= 0) ? y[width-1] - fixedpoint::fromInt(back_shift[width-1]) : 
              y[width-1] + fixedpoint::fromInt(-back_shift[width-1]);
       out_valid = 1'b1;
    end
  end
endmodule

















