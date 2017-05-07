
`define WB_IDLE     2'b00
`define WB_BUSY     2'b01
`define WB_WAIT     2'b11

module wb_interface(

    input wire                    clk,
    input wire                    rst,
    
    //from ctrl
    input wire[5:0]               stall_ctrl,
    input                         flush_i,
    
    // cpu side interface 
    input wire                    cpu_ce_i,
    input wire[`RegWidth-1:0]     cpu_data_i,
    input wire[`RegWidth-1:0]     cpu_addr_i,
    input wire                    cpu_we_i,
    input wire[3:0]               cpu_sel_i,
    output reg[`RegWidth-1:0]     cpu_data_o,
    
    // wishbone side interface
    input wire[`RegWidth-1:0]     wb_data_i,
    input wire                    wb_ack_i,
    output reg[`RegWidth-1:0]     wb_addr_o,
    output reg[`RegWidth-1:0]     wb_data_o,
    output reg                    wb_we_o,
    output reg[3:0]               wb_sel_o,
    output reg                    wb_stb_o,
    output reg                    wb_cyc_o,

    output reg                    stall_req           
    
);

  reg[1:0]           wb_state;
  reg[`RegWidth-1:0] data_buf;

    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            wb_state  <= `WB_IDLE;
            wb_addr_o <= {`RegWidth{1'b0}};
            wb_data_o <= {`RegWidth{1'b0}};
            wb_we_o   <= 1'b0;
            wb_sel_o  <= 4'b0000;
            wb_stb_o  <= 1'b0;
            wb_cyc_o  <= 1'b0;
            data_buf  <= {`RegWidth{1'b0}};
//          cpu_data_o <= {`RegWidth{1'b0}};
        end else begin
            case (wb_state)
                `WB_IDLE: begin
                // idle state
                // cpu request bus and the pipeline without flush
                    if((cpu_ce_i == 1'b1) && (flush_i == 1'b0)) begin
                        wb_state  <= `WB_BUSY;
                        wb_stb_o  <= 1'b1;
                        wb_cyc_o  <= 1'b1;
                        wb_addr_o <= cpu_addr_i;
                        wb_data_o <= cpu_data_i;
                        wb_we_o   <= cpu_we_i;
                        wb_sel_o  <= cpu_sel_i;
                        data_buf  <= {`RegWidth{1'b0}};
//                    end else begin
//                        wb_state <= WB_IDLE;
//                        wb_addr_o <= {`RegWidth{1'b0}};
//                        wb_data_o <= {`RegWidth{1'b0}};
//                        wb_we_o <= 1'b0;
//                        wb_sel_o <= 4'b0000;
//                        wb_stb_o <= 1'b0;
//                        wb_cyc_o <= 1'b0;
//                        cpu_data_o <= {`RegWidth{1'b0}};            
                    end                            
                end

                `WB_BUSY: begin
                    if(wb_ack_i == 1'b1) begin
                        wb_state  <= `WB_IDLE;
                        wb_stb_o  <= 1'b0;
                        wb_cyc_o  <= 1'b0;
                        wb_addr_o <= {`RegWidth{1'b0}};
                        wb_data_o <= {`RegWidth{1'b0}};
                        wb_we_o   <= 1'b0;
                        wb_sel_o  <= 4'b0000;
                        if(cpu_we_i == 1'b0) begin // read operation
                            data_buf <= wb_data_i;
                        end
                        // pipeline is stalled 
                        if(stall_ctrl != 6'b000000) begin
                            wb_state <= `WB_WAIT;
                        end                    
                    // exception occured, wishbone interface get the flush signal
                    end else if(flush_i == 1'b1) begin
                        wb_stb_o  <= 1'b0;
                        wb_cyc_o  <= 1'b0;
                        wb_addr_o <= {`RegWidth{1'b0}};
                        wb_data_o <= {`RegWidth{1'b0}};
                        wb_we_o   <= 1'b0;
                        wb_sel_o  <= 4'b0000;
                        wb_state  <= `WB_IDLE;
                        data_buf  <= {`RegWidth{1'b0}};
                    end
                end

                `WB_WAIT: begin
                    // cpu stall cancled
                    if(stall_ctrl == 6'b000000) begin
                        wb_state <= `WB_IDLE;
                    end
                end

                default: begin
                end 
            endcase
        end    //if
    end      //always
            

    always @ (*) begin
        if(rst == `RstEnable) begin
            stall_req  <= 1'b0;
            cpu_data_o <= {`RegWidth{1'b0}};
        end else begin
            stall_req  <= 1'b0;
            case (wb_state)
                `WB_IDLE: begin
                    if((cpu_ce_i == 1'b1) && (flush_i == 1'b0)) begin
                        stall_req  <= 1'b1;
                        cpu_data_o <= {`RegWidth{1'b0}};                
                    end
                end
                `WB_BUSY: begin
                    if(wb_ack_i == 1'b1) begin
                        stall_req <= 1'b0;
                        if(wb_we_o == 1'b0) begin
                            cpu_data_o <= wb_data_i;
                        end else begin
                            cpu_data_o <= {`RegWidth{1'b0}};
                        end                            
                    end else begin
                        stall_req  <= 1'b1;    
                        cpu_data_o <= {`RegWidth{1'b0}};                
                    end
                end
                `WB_WAIT: begin
                    stall_req  <= 1'b0;
                    cpu_data_o <= data_buf;
                end
                default: begin
                end 
            endcase
        end    //if
    end      //always

endmodule
