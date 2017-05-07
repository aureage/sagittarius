
module pc_reg(

    input wire                         clk,
    input wire                         rst,
    input wire[5:0]                    stall_ctrl,

    input wire                         branch_flag, // branch flag (high active)
    input wire[`RegWidth-1:0]          branch_target_addr,  
    
    input wire                         flush,
    input wire[`RegWidth-1:0]          pc_new,

    output reg[`InstBusAddrWidth-1:0]  pc,          // program counter
    output reg                         inst_mem_en  // high active
    
);

    always @ (posedge clk)
    begin
      if (rst == `RstEnable)
      begin
          inst_mem_en <= 1'b0;
      end
      else
      begin
          inst_mem_en <= 1'b1;
      end
    end

    always @ (posedge clk) begin
      if (inst_mem_en == 1'b0)  begin
          pc <= 32'h00000000;
      end else begin
          if(flush == 1'b1) begin
              pc <= pc_new;
          end else if(stall_ctrl[0] == 1'b0) begin
              if(branch_flag == 1'b1) begin
                  pc <= branch_target_addr;
              end else begin
                  pc <= pc + 4'h4;
              end
          end else begin
              pc <= pc;
          end
      end
    end

endmodule
