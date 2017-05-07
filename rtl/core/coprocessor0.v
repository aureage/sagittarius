module coprocessor0(

    input wire                    clk,
    input wire                    rst,

    input wire                    cp0_reg_we,
    input wire[4:0]               cp0_reg_waddr,
    input wire[4:0]               cp0_reg_raddr,
    input wire[`RegWidth-1:0]     cp0_reg_wdata,
    
    input wire[5:0]               int_i,
    input wire[`RegWidth-1:0]     except_type_i,
    input wire[`RegWidth-1:0]     cur_inst_addr_i,
    input wire                    in_delayslot_i,
    
    output reg[`RegWidth-1:0]     cp0_reg_rdata,

    output reg[`RegWidth-1:0]     count_reg,
    output reg[`RegWidth-1:0]     compare_reg,
    output reg[`RegWidth-1:0]     status_reg,
    output reg[`RegWidth-1:0]     cause_reg,
    output reg[`RegWidth-1:0]     epc_reg,
    output reg[`RegWidth-1:0]     config_reg,
    output reg[`RegWidth-1:0]     prid_reg,
    
    output reg                    timer_int_o    
    
);


// coprocessor0 reg write
    always @ (posedge clk)
    begin
        if(rst == `RstEnable)
        begin
            count_reg   <= {`RegWidth{1'b0}};
            compare_reg <= {`RegWidth{1'b0}};
            cause_reg   <= {`RegWidth{1'b0}};
            epc_reg     <= {`RegWidth{1'b0}};
            status_reg  <= 32'h10000000; // CP0 enable
            config_reg  <= 32'h00008000; // big endian set
            prid_reg    <= 32'h01440101; // AIM 01 01

            timer_int_o <= `InterruptNotAssert;
        end
        else
        begin
          count_reg        <= count_reg + 1 ;
          cause_reg[15:10] <= int_i;
        
          if(compare_reg != {`RegWidth{1'b0}} && count_reg == compare_reg)
          begin
              timer_int_o <= `InterruptAssert;
          end
                    
          if(cp0_reg_we == 1'b1) // write enable
          begin
              case (cp0_reg_waddr) 
                  `CP0_REG_COUNT:
                  begin
                      count_reg <= cp0_reg_wdata;
                  end
                  `CP0_REG_COMPARE:
                  begin
                      compare_reg <= cp0_reg_wdata;
                      //count_reg <= {`RegWidth{1'b0}};
                      timer_int_o <= `InterruptNotAssert;
                  end
                  `CP0_REG_STATUS:
                  begin
                      status_reg <= cp0_reg_wdata;
                  end
                  `CP0_REG_EPC:
                  begin
                      epc_reg <= cp0_reg_wdata;
                  end
                  `CP0_REG_CAUSE:
                  begin
                      cause_reg[9:8] <= cp0_reg_wdata[9:8];
                      cause_reg[23]  <= cp0_reg_wdata[23];
                      cause_reg[22]  <= cp0_reg_wdata[22];
                  end                    
              endcase  //case cp0_reg_waddr 
           end
           //
           // change the reg values when exception occurred
           //
            case (except_type_i)
                32'h00000001: // interrupt
                begin
                    if(in_delayslot_i == 1'b1 )
                    begin
                        epc_reg       <= cur_inst_addr_i - 4 ;
                        cause_reg[31] <= 1'b1;
                    end else begin
                        epc_reg       <= cur_inst_addr_i;
                        cause_reg[31] <= 1'b0;
                    end
                    status_reg[1] <= 1'b1;
                    cause_reg[6:2] <= 5'b00000;

                end
                32'h00000008: // system call
                begin
                    if(status_reg[1] == 1'b0)
                    begin
                        if(in_delayslot_i == 1'b1 )
                        begin
                            epc_reg       <= cur_inst_addr_i - 4 ;
                            cause_reg[31] <= 1'b1;
                        end else begin
                            epc_reg       <= cur_inst_addr_i;
                            cause_reg[31] <= 1'b0;
                        end
                    end
                    status_reg[1]  <= 1'b1;
                    cause_reg[6:2] <= 5'b01000;
                end
                32'h0000000a: // invalid instruction
                begin
                    if(status_reg[1] == 1'b0)
                    begin
                        if(in_delayslot_i == 1'b1 )
                        begin
                            epc_reg       <= cur_inst_addr_i - 4 ;
                            cause_reg[31] <= 1'b1;
                        end else begin
                            epc_reg       <= cur_inst_addr_i;
                            cause_reg[31] <= 1'b0;
                        end
                    end
                    status_reg[1]  <= 1'b1;
                    cause_reg[6:2] <= 5'b01010;
                end
                32'h0000000d: // trap
                begin
                    if(status_reg[1] == 1'b0)
                    begin
                        if(in_delayslot_i == 1'b1 )
                        begin
                            epc_reg       <= cur_inst_addr_i - 4 ;
                            cause_reg[31] <= 1'b1;
                        end else begin
                            epc_reg       <= cur_inst_addr_i;
                            cause_reg[31] <= 1'b0;
                        end
                    end
                    status_reg[1]  <= 1'b1;
                    cause_reg[6:2] <= 5'b01101;
                end
                32'h0000000c: //overflow
                begin
                    if(status_reg[1] == 1'b0)
                    begin
                        if(in_delayslot_i == 1'b1 )
                        begin
                            epc_reg       <= cur_inst_addr_i - 4 ;
                            cause_reg[31] <= 1'b1;
                        end else begin
                            epc_reg       <= cur_inst_addr_i;
                            cause_reg[31] <= 1'b0;
                        end
                    end
                    status_reg[1]  <= 1'b1;
                    cause_reg[6:2] <= 5'b01100;
                end
                32'h0000000e: // eret
                begin
                    status_reg[1] <= 1'b0;
                end
                default:                begin
                end
            endcase

        end    //if
    end      //always


    // coprocessor0 register read 
    always @ (*)
    begin
        if(rst == `RstEnable)
        begin
            cp0_reg_rdata <= {`RegWidth{1'b0}};
        end
        else
        begin
            case (cp0_reg_raddr) 
                `CP0_REG_COUNT:
                begin
                    cp0_reg_rdata <= count_reg ;
                end
                `CP0_REG_COMPARE:
                begin
                    cp0_reg_rdata <= compare_reg ;
                end
                `CP0_REG_STATUS:
                begin
                    cp0_reg_rdata <= status_reg ;
                end
                `CP0_REG_CAUSE:
                begin
                    cp0_reg_rdata <= cause_reg ;
                end
                `CP0_REG_EPC:
                begin
                    cp0_reg_rdata <= epc_reg ;
                end
                `CP0_REG_PrId:
                begin
                    cp0_reg_rdata <= prid_reg ;
                end
                `CP0_REG_CONFIG:
                begin
                    cp0_reg_rdata <= config_reg ;
                end    
                default:     begin
                end            
            endcase  //case cp0_reg_raddr 
        end    //if
    end   //always

endmodule
