

module pipe_reg_idex(

    input wire                             clk,
    input wire                             rst,
    input wire[5:0]                        stall_ctrl,
    input wire                             flush,

    
    // data from instruction decoder
    input wire[`InstTypeWidth-1:0]         id_inst_type,
    input wire[`InstClassWidth-1:0]        id_inst_class,
    input wire[`GPR_DataWidth-1:0]         id_gpr1_data,
    input wire[`GPR_DataWidth-1:0]         id_gpr2_data,
    input wire[`GPR_AddrWidth-1:0]         id_target_gpr,
    input wire                             id_gpr_we,    

    input wire[`RegWidth-1:0]              id_link_addr,  
    input wire                             id_inst_delayslot,  
    input wire                          nxtid_inst_delayslot,
    
    input wire[`RegWidth-1:0]              id_inst,
    // for exception handle
    input wire[`RegWidth-1:0]              id_except_type,
    input wire[`RegWidth-1:0]              id_cur_inst_addr,
    // data to instruction exe
    output reg[`InstTypeWidth-1:0]         ex_inst_type,
    output reg[`InstClassWidth-1:0]        ex_inst_class,
    output reg[`GPR_DataWidth-1:0]         ex_gpr1_data,
    output reg[`GPR_DataWidth-1:0]         ex_gpr2_data,
    output reg[`GPR_AddrWidth-1:0]         ex_target_gpr,
    output reg                             ex_gpr_we,
    
    output reg[`RegWidth-1:0]              ex_link_addr,  
    output reg                             ex_inst_delayslot,  
    output reg                            nxt_inst_delayslot,

    output reg[`RegWidth-1:0]              ex_inst,
    // for exception handle
    output reg[`RegWidth-1:0]              ex_except_type,
    output reg[`RegWidth-1:0]              ex_cur_inst_addr
);

    always @ (posedge clk)
    begin
      if (rst == `RstEnable) 
      begin
        ex_inst_type  <= `INST_T_NOP;
        ex_inst_class <= `INST_C_NOP;
        ex_gpr1_data  <= {`RegWidth{1'b0}};
        ex_gpr2_data  <= {`RegWidth{1'b0}};
        ex_target_gpr <= `NOPRegAddr;
        ex_gpr_we     <= 1'b0; // write disable

        ex_link_addr  <= {`RegWidth{1'b0}};
        ex_inst_delayslot  <= 1'b0;
        nxt_inst_delayslot <= 1'b0;

        ex_inst             <= {`RegWidth{1'b0}};

        ex_except_type      <= {`RegWidth{1'b0}};
        ex_cur_inst_addr    <= {`RegWidth{1'b0}};

      end
      else if (flush == 1'b1)
      begin
        ex_inst_type          <= `INST_T_NOP;
        ex_inst_class         <= `INST_C_NOP;
        ex_gpr1_data          <= {`RegWidth{1'b0}};
        ex_gpr2_data          <= {`RegWidth{1'b0}};
        ex_target_gpr         <= `NOPRegAddr;
        ex_gpr_we             <= 1'b0; // write disable
        ex_link_addr          <= {`RegWidth{1'b0}};
        ex_inst_delayslot     <= 1'b0;
        nxt_inst_delayslot    <= 1'b0;
        ex_inst               <= {`RegWidth{1'b0}};
        ex_except_type        <= {`RegWidth{1'b0}};
        ex_cur_inst_addr      <= {`RegWidth{1'b0}};
      end
      else if (stall_ctrl[2] == 1'b1 && stall_ctrl[3] == 1'b0) 
      begin
        ex_inst_type  <= `INST_T_NOP;
        ex_inst_class <= `INST_C_NOP;
        ex_gpr1_data  <= {`RegWidth{1'b0}};
        ex_gpr2_data  <= {`RegWidth{1'b0}};
        ex_target_gpr <= `NOPRegAddr;
        ex_gpr_we     <= 1'b0; // write disable

        ex_link_addr  <= {`RegWidth{1'b0}};
        ex_inst_delayslot <= 1'b0;
        nxt_inst_delayslot <= 1'b0;

        ex_inst       <= {`RegWidth{1'b0}};
        ex_except_type      <= {`RegWidth{1'b0}};
        ex_cur_inst_addr    <= {`RegWidth{1'b0}};
      end
      else if(stall_ctrl[2] == 1'b0)
      begin        
        ex_inst_type  <= id_inst_type;
        ex_inst_class <= id_inst_class;
        ex_gpr1_data  <= id_gpr1_data;
        ex_gpr2_data  <= id_gpr2_data;
        ex_target_gpr <= id_target_gpr;
        ex_gpr_we     <= id_gpr_we;        

        ex_link_addr  <= id_link_addr;

        ex_inst_delayslot  <=    id_inst_delayslot;
        nxt_inst_delayslot <= nxtid_inst_delayslot;

        ex_inst       <= id_inst;

        ex_except_type      <= id_except_type;
        ex_cur_inst_addr    <= id_cur_inst_addr;
      end
      else
      begin        
        ex_inst_type  <= ex_inst_type;
        ex_inst_class <= ex_inst_class;
        ex_gpr1_data  <= ex_gpr1_data;
        ex_gpr2_data  <= ex_gpr2_data;
        ex_target_gpr <= ex_target_gpr;
        ex_gpr_we     <= ex_gpr_we;        

        ex_link_addr  <= ex_link_addr;
        ex_inst_delayslot <= ex_inst_delayslot;
        nxt_inst_delayslot <= nxt_inst_delayslot;

        ex_inst       <= ex_inst;

        ex_except_type      <= ex_except_type;
        ex_cur_inst_addr    <= ex_cur_inst_addr;
      end
    end
    
endmodule
