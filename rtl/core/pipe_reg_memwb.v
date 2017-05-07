
module pipe_reg_memwb(

    input wire                      clk,
    input wire                      rst,
    input wire[5:0]                 stall_ctrl,
    input wire                      flush,
    // from memory access stage
    input wire                      mem_gpr_we,
    input wire[`GPR_AddrWidth-1:0]  mem_target_gpr,
    input wire[`GPR_DataWidth-1:0]  mem_exe_result,

    input wire[`RegWidth-1:0]       mem_hi,
    input wire[`RegWidth-1:0]       mem_lo,
    input wire                      mem_hilo_we,
   
    input wire                      mem_llbit_we,
    input wire                      mem_llbit_value,

    input wire                      mem_cp0_we,
    input wire[4:0]                 mem_cp0_waddr,
    input wire[`RegWidth-1:0]       mem_cp0_wdata,

    // to write back stage
    output reg                      wb_gpr_we,
    output reg[`GPR_AddrWidth-1:0]  wb_target_gpr,
    output reg[`GPR_DataWidth-1:0]  wb_exe_result,

    output reg[`RegWidth-1:0]       wb_hi,
    output reg[`RegWidth-1:0]       wb_lo,
    output reg                      wb_hilo_we,

    output reg                      wb_llbit_we,
    output reg                      wb_llbit_value,

    output reg                      wb_cp0_we,
    output reg[4:0]                 wb_cp0_waddr,
    output reg[`RegWidth-1:0]       wb_cp0_wdata

);


    always @ (posedge clk)
    begin
        if(rst == `RstEnable)
        begin
            wb_gpr_we       <= 1'b0;
            wb_target_gpr   <= `NOPRegAddr;
            wb_exe_result   <= 1'b0;
            wb_hi           <= {`RegWidth{1'b0}};
            wb_lo           <= {`RegWidth{1'b0}};
            wb_hilo_we      <= 1'b0;
            wb_llbit_we     <= 1'b0;
            wb_llbit_value  <= 1'b0;
            wb_cp0_we       <= 1'b0;
            wb_cp0_waddr    <= 5'b00000;
            wb_cp0_wdata    <= {`RegWidth{1'b0}};
        end
        else if(flush == 1'b1)
        begin
            wb_gpr_we       <= 1'b0;
            wb_target_gpr   <= `NOPRegAddr;
            wb_exe_result   <= 1'b0;
            wb_hi           <= {`RegWidth{1'b0}};
            wb_lo           <= {`RegWidth{1'b0}};
            wb_hilo_we      <= 1'b0;
            wb_llbit_we     <= 1'b0;
            wb_llbit_value  <= 1'b0;
            wb_cp0_we       <= 1'b0;
            wb_cp0_waddr    <= 5'b00000;
            wb_cp0_wdata    <= {`RegWidth{1'b0}};
        end
        else if(stall_ctrl[4] == 1'b1 && stall_ctrl[5] == 1'b0)
        begin
            wb_gpr_we       <= 1'b0;
            wb_target_gpr   <= `NOPRegAddr;
            wb_exe_result   <= 1'b0;
            wb_hi           <= {`RegWidth{1'b0}};
            wb_lo           <= {`RegWidth{1'b0}};
            wb_hilo_we      <= 1'b0;
            wb_llbit_we     <= 1'b0;
            wb_llbit_value  <= 1'b0;
            wb_cp0_we       <= 1'b0;
            wb_cp0_waddr    <= 5'b00000;
            wb_cp0_wdata    <= {`RegWidth{1'b0}};
        end
        else if(stall_ctrl[4] == 1'b0) 
        begin
            wb_gpr_we       <= mem_gpr_we;
            wb_target_gpr   <= mem_target_gpr;
            wb_exe_result   <= mem_exe_result;
            wb_hi           <= mem_hi;
            wb_lo           <= mem_lo;
            wb_hilo_we      <= mem_hilo_we;
            wb_llbit_we     <= mem_llbit_we;
            wb_llbit_value  <= mem_llbit_value;

            wb_cp0_we       <= mem_cp0_we;
            wb_cp0_waddr    <= mem_cp0_waddr;
            wb_cp0_wdata    <= mem_cp0_wdata;
        end
        else 
        begin
            wb_gpr_we       <= wb_gpr_we;
            wb_target_gpr   <= wb_target_gpr;
            wb_exe_result   <= wb_exe_result;
            wb_hi           <= wb_hi;
            wb_lo           <= wb_lo;
            wb_hilo_we      <= wb_hilo_we;
            wb_llbit_we     <= wb_llbit_we   ;
            wb_llbit_value  <= wb_llbit_value;

            wb_cp0_we       <= wb_cp0_we;
            wb_cp0_waddr    <= wb_cp0_waddr;
            wb_cp0_wdata    <= wb_cp0_wdata;
        end    //if
    end      //always
            

endmodule
