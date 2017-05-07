
module pipe_reg_ifid(

    input  wire                            clk,
    input  wire                            rst,
    input  wire  [5:0]                     stall_ctrl,
    input  wire                            flush,

    input  wire  [`InstBusAddrWidth-1:0]   if_pc,
    input  wire  [`InstBusDataWidth-1:0]   if_inst,
    output reg   [`InstBusAddrWidth-1:0]   id_pc,
    output reg   [`InstBusDataWidth-1:0]   id_inst  
    
);

    always @ (posedge clk)
    begin
      if (rst == `RstEnable)
      begin
        id_pc   <= {`RegWidth{1'b0}};
        id_inst <= {`RegWidth{1'b0}};
      end
      else if (flush == 1'b1)
      begin 
        id_pc   <= {`RegWidth{1'b0}};
        id_inst <= {`RegWidth{1'b0}};
      end
      else if (stall_ctrl[1] == 1'b1 && stall_ctrl[2] == 1'b0)
      begin
        id_pc   <= {`RegWidth{1'b0}};
        id_inst <= {`RegWidth{1'b0}};
      end
      else if(stall_ctrl[1] == 1'b0)
      begin
        id_pc   <= if_pc;
        id_inst <= if_inst;
      end
      else
      begin
        id_pc   <= id_pc;
        id_inst <= id_inst;
      end
    end

endmodule
