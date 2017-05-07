

module pipe_reg_exmem(

    input wire                       clk,
    input wire                       rst,
    input wire[5:0]                  stall_ctrl,
    input wire                       flush,
    //  from execute stage
    input wire                       ex_gpr_we,
    input wire[`GPR_AddrWidth-1:0]   ex_target_gpr,
    input wire[`GPR_DataWidth-1:0]   ex_exe_result,     
    input wire[`RegWidth-1:0]        ex_hi,
    input wire[`RegWidth-1:0]        ex_lo,
    input wire                       ex_hilo_we,

    input wire[`DoubleRegWidth-1:0]  ex_hilo_tmp_i,
    input wire[1:0]                  ex_cycl_cnt_i,

    input wire[`InstTypeWidth-1:0]   ex_inst_type,
    input wire[`RegWidth-1:0]        ex_dmem_addr,
    input wire[`RegWidth-1:0]        ex_ls_data_tmp,
   
    input wire                       ex_cp0_we,
    input wire[4:0]                  ex_cp0_waddr,
    input wire[`RegWidth-1:0]        ex_cp0_wdata,
    // for exception
    input wire[`RegWidth-1:0]        ex_except_type,
    input wire[`RegWidth-1:0]        ex_cur_inst_addr,
    input wire                       ex_inst_delayslot,
    

    output reg[`DoubleRegWidth-1:0]  ex_hilo_tmp_o,
    output reg[1:0]                  ex_cycl_cnt_o,
    //  to memory stage
    output reg                       mem_gpr_we,
    output reg[`GPR_AddrWidth-1:0]   mem_target_gpr,
    output reg[`GPR_DataWidth-1:0]   mem_exe_result,
    output reg[`RegWidth-1:0]        mem_hi,
    output reg[`RegWidth-1:0]        mem_lo,
    output reg                       mem_hilo_we,
    
    output reg[`InstTypeWidth-1:0]   mem_inst_type,
    output reg[`RegWidth-1:0]        mem_dmem_addr,
    output reg[`RegWidth-1:0]        mem_ls_data_tmp,

    output reg                       mem_cp0_we,
    output reg[4:0]                  mem_cp0_waddr,
    output reg[`RegWidth-1:0]        mem_cp0_wdata,
    // for exception
    output reg[`RegWidth-1:0]        mem_except_type,
    output reg[`RegWidth-1:0]        mem_cur_inst_addr,
    output reg                       mem_inst_delayslot
);


    always @ (posedge clk) 
    begin
      if(rst == `RstEnable) 
      begin
        mem_gpr_we     <= 1'b0;
        mem_target_gpr <= `NOPRegAddr;
        mem_exe_result <= 1'b0;    
        mem_hi         <= {`RegWidth{1'b0}};
        mem_lo         <= {`RegWidth{1'b0}};
        mem_hilo_we    <= 1'b0;

        ex_hilo_tmp_o  <= {`DoubleRegWidth{1'b0}};
        ex_cycl_cnt_o  <= 2'b00;

        mem_inst_type  <= `INST_T_NOP;
        mem_dmem_addr  <= {`RegWidth{1'b0}};
        mem_ls_data_tmp<= {`RegWidth{1'b0}};

        mem_cp0_we     <= 1'b0; 
        mem_cp0_waddr  <= 5'b00000; 
        mem_cp0_wdata  <= {`RegWidth{1'b0}};

        mem_except_type    <= {`RegWidth{1'b0}};
        mem_cur_inst_addr  <= {`RegWidth{1'b0}};
        mem_inst_delayslot <= 1'b0;
      end
      else if(flush == 1'b1) 
      begin
        mem_gpr_we     <= 1'b0;
        mem_target_gpr <= `NOPRegAddr;
        mem_exe_result <= 1'b0;    
        mem_hi         <= {`RegWidth{1'b0}};
        mem_lo         <= {`RegWidth{1'b0}};
        mem_hilo_we    <= 1'b0;

        ex_hilo_tmp_o  <= {`DoubleRegWidth{1'b0}};
        ex_cycl_cnt_o  <= 2'b00;

        mem_inst_type  <= `INST_T_NOP;
        mem_dmem_addr  <= {`RegWidth{1'b0}};
        mem_ls_data_tmp<= {`RegWidth{1'b0}};

        mem_cp0_we     <= 1'b0; 
        mem_cp0_waddr  <= 5'b00000; 
        mem_cp0_wdata  <= {`RegWidth{1'b0}};

        mem_except_type    <= {`RegWidth{1'b0}};
        mem_cur_inst_addr  <= {`RegWidth{1'b0}};
        mem_inst_delayslot <= 1'b0;
      end
      else if(stall_ctrl[3] == 1'b1 && stall_ctrl[4] == 1'b0) 
      begin
        mem_gpr_we     <= 1'b0;
        mem_target_gpr <= `NOPRegAddr;
        mem_exe_result <= 1'b0;    
        mem_hi         <= {`RegWidth{1'b0}};
        mem_lo         <= {`RegWidth{1'b0}};
        mem_hilo_we    <= 1'b0;

        ex_hilo_tmp_o  <= ex_hilo_tmp_i; 
        ex_cycl_cnt_o  <= ex_cycl_cnt_i; 

        mem_inst_type  <= `INST_T_NOP;
        mem_dmem_addr  <= {`RegWidth{1'b0}};
        mem_ls_data_tmp<= {`RegWidth{1'b0}};

        mem_cp0_we     <= 1'b0; 
        mem_cp0_waddr  <= 5'b00000; 
        mem_cp0_wdata  <= {`RegWidth{1'b0}};

        mem_except_type    <= {`RegWidth{1'b0}};
        mem_cur_inst_addr  <= {`RegWidth{1'b0}};
        mem_inst_delayslot <= 1'b0;
      end
      else if(stall_ctrl[3] == 1'b0)
      begin
        mem_gpr_we      <= ex_gpr_we;
        mem_target_gpr  <= ex_target_gpr;
        mem_exe_result  <= ex_exe_result;            
        mem_hi          <= ex_hi; 
        mem_lo          <= ex_lo;
        mem_hilo_we     <= ex_hilo_we;

        ex_hilo_tmp_o   <= {`DoubleRegWidth{1'b0}};
        ex_cycl_cnt_o   <= 2'b00;

        mem_inst_type   <= ex_inst_type;
        mem_dmem_addr   <= ex_dmem_addr;
        mem_ls_data_tmp <= ex_ls_data_tmp;

        mem_cp0_we      <= ex_cp0_we;
        mem_cp0_waddr   <= ex_cp0_waddr;
        mem_cp0_wdata   <= ex_cp0_wdata;

        mem_except_type    <= ex_except_type;
        mem_cur_inst_addr  <= ex_cur_inst_addr;
        mem_inst_delayslot <= ex_inst_delayslot;
      end
      else
      begin
        mem_gpr_we      <= mem_gpr_we;
        mem_target_gpr  <= mem_target_gpr;
        mem_exe_result  <= mem_exe_result;            
        mem_hi          <= mem_hi; 
        mem_lo          <= mem_lo;
        mem_hilo_we     <= mem_hilo_we;

        ex_hilo_tmp_o   <= ex_hilo_tmp_i; 
        ex_cycl_cnt_o   <= ex_cycl_cnt_i; 
       
        mem_inst_type   <= mem_inst_type;
        mem_dmem_addr   <= mem_dmem_addr;
        mem_ls_data_tmp <= mem_ls_data_tmp;

        mem_cp0_we      <= mem_cp0_we;
        mem_cp0_waddr   <= mem_cp0_waddr;
        mem_cp0_wdata   <= mem_cp0_wdata;

        mem_except_type    <= mem_except_type;
        mem_cur_inst_addr  <= mem_cur_inst_addr;
        mem_inst_delayslot <= mem_inst_delayslot;
      end    //if
    end      //always
            

endmodule
