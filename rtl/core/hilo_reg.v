
module hilo_reg(

    input wire                   clk,
    input wire                   rst,
    
    input wire                   we,
    input wire[`RegWidth-1:0]    hi_i,
    input wire[`RegWidth-1:0]    lo_i,
    
    output reg[`RegWidth-1:0]    hi_o,
    output reg[`RegWidth-1:0]    lo_o
    
);

    always @ (posedge clk)
    begin
      if (rst == `RstEnable) begin
        hi_o <= 32'h0;
        lo_o <= 32'h0;
      end else if((we == 1'b1)) begin
        hi_o <= hi_i;
        lo_o <= lo_i;
      end
    end

endmodule
