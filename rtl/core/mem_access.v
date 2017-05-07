
module mem_access(

    input wire                      rst,
    // come from execute stage
    input wire                      gpr_we,
    input wire[`GPR_AddrWidth-1:0]  target_gpr,
    input wire[`GPR_DataWidth-1:0]  exe_result,
    input wire[`RegWidth-1:0]       hi,
    input wire[`RegWidth-1:0]       lo,
    input wire                      hilo_we,

    // interface for data mem
    input wire[`InstTypeWidth-1:0]  inst_type,
    input wire[`RegWidth-1:0]       ls_data_tmp,
    input wire[`RegWidth-1:0]       dmem_addr_i,
    input wire[`RegWidth-1:0]       dmem_data_i,

    input wire                      llbit_i,
    input wire                      wb_llbit_we,
    input wire                      wb_llbit_value,
    
    input wire                      cp0_we_i,
    input wire[4:0]                 cp0_waddr_i,
    input wire[`RegWidth-1:0]       cp0_wdata_i,

    // for exception
    input wire[`RegWidth-1:0]       except_type_i,
    input wire                      in_delayslot_i,
    input wire[`RegWidth-1:0]       cur_inst_addr_i,
    input wire[`RegWidth-1:0]       cp0_status_i,
    input wire[`RegWidth-1:0]       cp0_cause_i,
    input wire[`RegWidth-1:0]       cp0_epc_i,
    input wire                      wb_cp0_we,
    input wire[4:0]                 wb_cp0_waddr,
    input wire[`RegWidth-1:0]       wb_cp0_wdata,


    output reg[`RegWidth-1:0]       dmem_addr_o,
    output reg[`RegWidth-1:0]       dmem_data_o,
    output reg[3:0]                 dmem_byte_sel,
    output reg                      dmem_ce,
    output wire                     dmem_we,
    
    
    // to write back stage
    output reg                      gpr_we_o,
    output reg[`GPR_AddrWidth-1:0]  target_gpr_o,
    output reg[`GPR_DataWidth-1:0]  exe_result_o,
    output reg[`RegWidth-1:0]       hi_o,
    output reg[`RegWidth-1:0]       lo_o,
    output reg                      hilo_we_o,
    
    output reg                      mem_llbit_we,
    output reg                      mem_llbit_value,

    output reg                      cp0_we_o,
    output reg[4:0]                 cp0_waddr_o,
    output reg[`RegWidth-1:0]       cp0_wdata_o,

    // for exception
    output reg [`RegWidth-1:0]      except_type_o,
    output wire[`RegWidth-1:0]      cp0_epc_o,
    output wire[`RegWidth-1:0]      cur_inst_addr_o,
    output wire                     in_delayslot_o


);
    reg                            llbit;
    reg                            dmem_we_tmp;
    reg    [`RegWidth-1:0]         cp0_status;
    reg    [`RegWidth-1:0]         cp0_cause;
    reg    [`RegWidth-1:0]         cp0_epc;
    wire   [`RegWidth-1:0]         zero32;

    assign in_delayslot_o  = in_delayslot_i;
    assign cur_inst_addr_o = cur_inst_addr_i;
    assign cp0_epc_o       = cp0_epc;

    assign dmem_we = dmem_we_tmp & (~(|except_type_o));
    assign zero32   = {`RegWidth{1'b0}};

    // get the newest data of status/cause/epc register
    always @ (*)
    begin
        if(rst == `RstEnable) begin
            cp0_status <= {`RegWidth{1'b0}};
        end else if((wb_cp0_we    == 1'b1) &&
                    (wb_cp0_waddr == `CP0_REG_STATUS ))begin
            cp0_status <= wb_cp0_wdata;
        end else begin
            cp0_status <= cp0_status_i;
        end
    end

    always @ (*)
    begin
        if(rst == `RstEnable) begin
            cp0_epc <= {`RegWidth{1'b0}};
        end else if((wb_cp0_we == 1'b1) &&
                    (wb_cp0_waddr == `CP0_REG_EPC ))begin
            cp0_epc <= wb_cp0_wdata;
        end else begin
            cp0_epc <= cp0_epc_i;
        end
    end

    always @ (*)
    begin
        if(rst == `RstEnable) begin
            cp0_cause <= {`RegWidth{1'b0}};
        end else if((wb_cp0_we == 1'b1) &&
                    (wb_cp0_waddr == `CP0_REG_CAUSE ))begin
            cp0_cause[9:8] <= wb_cp0_wdata[9:8]; // IP1-0(software interrupt bits)
            cp0_cause[22]  <= wb_cp0_wdata[22];  // WP
            cp0_cause[23]  <= wb_cp0_wdata[23];  // IV
        end else begin
            cp0_cause <= cp0_cause_i;
        end
    end

    always @ (*)
    begin
        if(rst == `RstEnable) begin
            except_type_o <= {`RegWidth{1'b0}};
        end else begin
            except_type_o <= {`RegWidth{1'b0}};
            if(cur_inst_addr_i != {`RegWidth{1'b0}}) begin
                if(((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00)
                 && (cp0_status[1] == 1'b0)
                 && (cp0_status[0] == 1'b1)) begin
                    except_type_o <= 32'h00000001;        //interrupt
                end else if(except_type_i[8] == 1'b1) begin
                    except_type_o <= 32'h00000008;        //syscall
                end else if(except_type_i[9] == 1'b1) begin
                    except_type_o <= 32'h0000000a;        //inst_invalid
                end else if(except_type_i[10] ==1'b1) begin
                    except_type_o <= 32'h0000000d;        //trap
                end else if(except_type_i[11] == 1'b1) begin
                    except_type_o <= 32'h0000000c;        //overflow
                end else if(except_type_i[12] == 1'b1) begin
                    except_type_o <= 32'h0000000e;        //eret
                end
            end
        end
    end


    always @ (*)
    begin  
      if(rst == 1'b1)
      begin  
        llbit <= 1'b0;  
      end
      else
      begin  
        if(wb_llbit_we == 1'b1)
        begin  
           llbit <= wb_llbit_value;
        end
        else
        begin  
           llbit <= llbit_i;  
        end  
      end  
    end  



    always @ (*) begin
        if(rst == `RstEnable) begin
            gpr_we_o     <= 1'b0;
            target_gpr_o <= `NOPRegAddr;
            exe_result_o <= 1'b0;
            hi_o         <= {`RegWidth{1'b0}};
            lo_o         <= {`RegWidth{1'b0}};
            hilo_we_o    <= 1'b0;

            dmem_addr_o    <= {`RegWidth{1'b0}};  
            dmem_data_o    <= {`RegWidth{1'b0}};  
            dmem_byte_sel  <= 4'b0000;  
            dmem_we_tmp    <= 1'b0;  
            dmem_ce        <= 1'b0;  

            mem_llbit_we   <= 1'b0;
            mem_llbit_value<= 1'b0;

            cp0_we_o       <= 1'b0;
            cp0_waddr_o    <= 5'b00000;
            cp0_wdata_o    <= {`RegWidth{1'b0}};  

        end else begin
            gpr_we_o     <= gpr_we;
            target_gpr_o <= target_gpr;
            exe_result_o <= exe_result;
            hi_o         <= hi; 
            lo_o         <= lo;
            hilo_we_o    <= hilo_we;

            dmem_addr_o    <= {`RegWidth{1'b0}};  
            dmem_byte_sel  <= 4'b1111;  
            dmem_we_tmp    <= 1'b0;  
            dmem_ce        <= 1'b0;  

            mem_llbit_we   <= 1'b0;
            mem_llbit_value<= 1'b0;

            cp0_we_o       <= cp0_we_i;
            cp0_waddr_o    <= cp0_waddr_i;
            cp0_wdata_o    <= cp0_wdata_i;

            case (inst_type)
                `INST_T_LB:
                begin
                    dmem_addr_o <= dmem_addr_i;  
                    dmem_we_tmp <= 1'b0; // write disable 
                    dmem_ce     <= 1'b1; // chip enable 
                    case (dmem_addr_i[1:0])  
                      2'b00: begin  
                        exe_result_o   <= {{24{dmem_data_i[31]}},dmem_data_i[31:24]};  
                        dmem_byte_sel  <= 4'b1000;  
                      end  
                      2'b01: begin  
                        exe_result_o   <= {{24{dmem_data_i[23]}},dmem_data_i[23:16]};  
                        dmem_byte_sel  <= 4'b0100;  
                      end  
                      2'b10: begin  
                        exe_result_o   <= {{24{dmem_data_i[15]}},dmem_data_i[15:8]};  
                        dmem_byte_sel  <= 4'b0010;  
                      end  
                      2'b11: begin  
                        exe_result_o   <= {{24{dmem_data_i[7]}},dmem_data_i[7:0]};  
                        dmem_byte_sel  <= 4'b0001;  
                      end  
                      default:   begin  
                        exe_result_o   <= {`RegWidth{1'b0}};  
                      end  
                    endcase 
                end

                `INST_T_LBU:
                begin
                   dmem_addr_o <= dmem_addr_i;  
                   dmem_we_tmp <= 1'b0;  
                   dmem_ce     <= 1'b1;  
                   case (dmem_addr_i[1:0])  
                     2'b00: begin  
                        exe_result_o   <= {{24{1'b0}},dmem_data_i[31:24]};  
                        dmem_byte_sel  <= 4'b1000;  
                     end  
                     2'b01: begin  
                        exe_result_o   <= {{24{1'b0}},dmem_data_i[23:16]};  
                        dmem_byte_sel  <= 4'b0100;  
                     end  
                     2'b10: begin  
                        exe_result_o   <= {{24{1'b0}},dmem_data_i[15:8]};  
                        dmem_byte_sel  <= 4'b0010;  
                     end  
                     2'b11: begin  
                        exe_result_o   <= {{24{1'b0}},dmem_data_i[7:0]};  
                        dmem_byte_sel  <= 4'b0001;  
                     end  
                     default:   begin  
                        exe_result_o   <= {`RegWidth{1'b0}};  
                     end  
                  endcase  
                end  

                `INST_T_LH:
                begin
                    dmem_addr_o <= dmem_addr_i;  
                    dmem_we_tmp <= 1'b0;  
                    dmem_ce     <= 1'b1;  
                    case (dmem_addr_i[1:0])  
                       2'b00: begin  
                         exe_result_o   <= {{16{dmem_data_i[31]}},dmem_data_i[31:16]};  
                         dmem_byte_sel  <= 4'b1100;  
                       end  
                       2'b10: begin  
                         exe_result_o   <= {{16{dmem_data_i[15]}},dmem_data_i[15:0]};  
                         dmem_byte_sel  <= 4'b0011;  
                       end  
                       default:   begin  
                         exe_result_o   <= {`RegWidth{1'b0}};  
                       end  
                    endcase  
                end  
                `INST_T_LHU:
                begin
                    dmem_addr_o <= dmem_addr_i;  
                    dmem_we_tmp <= 1'b0;  
                    dmem_ce     <= 1'b1;  
                    case (dmem_addr_i[1:0])  
                      2'b00:  begin  
                         exe_result_o   <= {{16{1'b0}},dmem_data_i[31:16]};  
                         dmem_byte_sel  <= 4'b1100;  
                      end  
                      2'b10:  begin  
                         exe_result_o   <= {{16{1'b0}},dmem_data_i[15:0]};  
                         dmem_byte_sel  <= 4'b0011;  
                      end  
                      default:    begin  
                         exe_result_o   <= {`RegWidth{1'b0}};  
                      end  
                    endcase  
                end  
                `INST_T_LW:
                begin
                    dmem_addr_o     <= dmem_addr_i;  
                    exe_result_o    <= dmem_data_i;  
                    dmem_byte_sel   <= 4'b1111;  
                    dmem_we_tmp     <= 1'b0;  
                    dmem_ce         <= 1'b1;  
                end  

                `INST_T_LL:
                begin
                    dmem_addr_o    <= dmem_addr_i;  
                    exe_result_o   <= dmem_data_i;  
                    dmem_byte_sel  <= 4'b1111;  
                    dmem_we_tmp    <= 1'b0;  
                    dmem_ce        <= 1'b1;  
                    mem_llbit_we   <= 1'b1;  
                    mem_llbit_value<= 1'b1;  
                end 

                `INST_T_LWL:
                begin
                    dmem_addr_o     <= {dmem_addr_i[31:2], 2'b00};  
                    dmem_byte_sel   <= 4'b1111;  
                    dmem_we_tmp     <= 1'b0;  
                    dmem_ce         <= 1'b1;  
                    case (dmem_addr_i[1:0])  
                      2'b00:  begin  
                          exe_result_o <= dmem_data_i[31:0];  
                      end  
                      2'b01:  begin  
                          exe_result_o <= {dmem_data_i[23:0],ls_data_tmp[7:0]};  
                      end  
                      2'b10:  begin  
                          exe_result_o <= {dmem_data_i[15:0],ls_data_tmp[15:0]};  
                      end  
                      2'b11:  begin  
                          exe_result_o <= {dmem_data_i[7:0],ls_data_tmp[23:0]};  
                      end  
                      default:    begin  
                          exe_result_o <= {`RegWidth{1'b0}};  
                      end  
                    endcase  
                end  
                `INST_T_LWR:
                begin
                    dmem_addr_o    <= {dmem_addr_i[31:2], 2'b00};  
                    dmem_byte_sel  <= 4'b1111;  
                    dmem_we_tmp    <= 1'b0;  
                    dmem_ce        <= 1'b1;  
                    case (dmem_addr_i[1:0])  
                      2'b00: begin  
                          exe_result_o <= {ls_data_tmp[31:8],dmem_data_i[31:24]};  
                      end  
                      2'b01: begin  
                          exe_result_o <= {ls_data_tmp[31:16],dmem_data_i[31:16]};  
                      end  
                      2'b10: begin  
                          exe_result_o <= {ls_data_tmp[31:24],dmem_data_i[31:8]};  
                      end  
                      2'b11: begin  
                          exe_result_o <= dmem_data_i;  
                      end  
                      default: begin  
                          exe_result_o <= {`RegWidth{1'b0}};  
                      end  
                    endcase  
                 end  



                `INST_T_SB:
                begin
                    dmem_addr_o <= dmem_addr_i;  
                    dmem_data_o <= {ls_data_tmp[7:0],ls_data_tmp[7:0],  
                                    ls_data_tmp[7:0],ls_data_tmp[7:0]};  
                    dmem_we_tmp <= 1'b1;  
                    dmem_ce     <= 1'b1;  
                    case (dmem_addr_i[1:0])  
                      2'b00: begin  
                         dmem_byte_sel <= 4'b1000;  
                      end  
                      2'b01: begin  
                         dmem_byte_sel <= 4'b0100;  
                      end  
                      2'b10: begin  
                         dmem_byte_sel <= 4'b0010;  
                      end  
                      2'b11: begin  
                         dmem_byte_sel <= 4'b0001;   
                      end  
                      default: begin  
                         dmem_byte_sel <= 4'b0000;  
                      end  
                    endcase  
                end  
                `INST_T_SH:
                begin
                    dmem_addr_o <= dmem_addr_i;  
                    dmem_data_o <= {ls_data_tmp[15:0],ls_data_tmp[15:0]};  
                    dmem_we_tmp <= 1'b1;  
                    dmem_ce     <= 1'b1;  
                    case (dmem_addr_i[1:0])  
                      2'b00: begin  
                         dmem_byte_sel <= 4'b1100;  
                      end  
                      2'b10: begin  
                         dmem_byte_sel <= 4'b0011;  
                      end  
                      default: begin  
                         dmem_byte_sel <= 4'b0000;  
                      end  
                    endcase  
                end  

                `INST_T_SW:
                begin
                    dmem_addr_o    <= dmem_addr_i;  
                    dmem_data_o    <= ls_data_tmp;  
                    dmem_byte_sel  <= 4'b1111;  
                    dmem_we_tmp    <= 1'b1;  
                    dmem_ce        <= 1'b1;  
                end  

                `INST_T_SC:
                begin
                    if(llbit == 1'b1)
                    begin
                        dmem_addr_o    <= dmem_addr_i;  
                        dmem_data_o    <= ls_data_tmp;
                        exe_result_o   <= 32'b1;  
                        dmem_byte_sel  <= 4'b1111;  
                        dmem_we_tmp    <= 1'b1;  
                        dmem_ce        <= 1'b1;  
                        mem_llbit_we   <= 1'b1;  
                        mem_llbit_value<= 1'b0;  
                    end
                    else
                    begin
                        exe_result_o <= 32'b0;
                    end
                end 

                `INST_T_SWL:
                begin
                    dmem_addr_o <= {dmem_addr_i[31:2], 2'b00};  
                    dmem_we_tmp <= 1'b1;  
                    dmem_ce     <= 1'b1;  
                    case (dmem_addr_i[1:0])  
                      2'b00: begin   
                        dmem_byte_sel <= 4'b1111;  
                        dmem_data_o <= ls_data_tmp;  
                      end  
                      2'b01: begin  
                        dmem_byte_sel <= 4'b0111;  
                        dmem_data_o <= {zero32[7:0],ls_data_tmp[31:8]};  
                      end  
                      2'b10: begin  
                        dmem_byte_sel <= 4'b0011;  
                        dmem_data_o <= {zero32[15:0],ls_data_tmp[31:16]};  
                      end  
                      2'b11: begin  
                        dmem_byte_sel <= 4'b0001;  
                        dmem_data_o <= {zero32[23:0],ls_data_tmp[31:24]};  
                      end  
                      default: begin  
                        dmem_byte_sel <= 4'b0000;  
                      end  
                   endcase  
                end  
                `INST_T_SWR:
                begin
                   dmem_addr_o <= {dmem_addr_i[31:2], 2'b00};  
                   dmem_we_tmp <= 1'b1;  
                   dmem_ce     <= 1'b1;  
                      case (dmem_addr_i[1:0])  
                        2'b00: begin   
                           dmem_byte_sel  <= 4'b1000;  
                           dmem_data_o <= {ls_data_tmp[7:0],zero32[23:0]};  
                        end  
                        2'b01: begin  
                           dmem_byte_sel  <= 4'b1100;  
                           dmem_data_o <= {ls_data_tmp[15:0],zero32[15:0]};  
                        end  
                        2'b10: begin  
                           dmem_byte_sel  <= 4'b1110;  
                           dmem_data_o <= {ls_data_tmp[23:0],zero32[7:0]};  
                        end  
                        2'b11: begin  
                           dmem_byte_sel  <= 4'b1111;  
                           dmem_data_o <= ls_data_tmp[31:0];  
                        end  
                        default:  begin  
                           dmem_byte_sel  <= 4'b0000;  
                        end  
                      endcase  
                end   
                default:      begin  
                end  
            endcase 
        end    //if
    end      //always

            

endmodule
