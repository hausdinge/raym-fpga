`timescale 1ns / 1ps

module mult_alt (input logic in_valid, input logic clk, input fixedpoint::number num1, input fixedpoint::number num2, output fixedpoint::number prod, output logic out_valid);
  fixedpoint::number ou [0:1];
  logic [0:1] val;
  fixedpoint_mult fm (in_valid, clk, num1, num2, ou[0], val[0]);
  
  always @(posedge clk) begin
    ou[1] <= ou[0];
    val[1] <= val[0];
  end
  
  always_comb begin
    prod = 1'b0;
    out_valid = 1'b0;
    if(val[1]) begin
      prod = ou[1];
      out_valid = 1'b1;
    end
  end
  
endmodule
