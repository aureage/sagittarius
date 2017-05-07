
module inst_execute(

    input wire                             rst,
    
    // come from decode stage
    input wire[`InstTypeWidth-1:0]         inst_type,
    input wire[`InstClassWidth-1:0]        inst_class,
    input wire[`RegWidth-1:0]              gpr1_data,
    input wire[`RegWidth-1:0]              gpr2_data,
    input wire[`GPR_AddrWidth-1:0]         target_gpr,
    input wire                             gpr_we,
    // data from module "hilo_reg"
    input wire[`RegWidth-1:0]              hi_i,
    input wire[`RegWidth-1:0]              lo_i,

    input wire[`RegWidth-1:0]              df_wbex_hi,
    input wire[`RegWidth-1:0]              df_wbex_lo,
    input wire                             df_wbex_hilo_we,

    input wire[`RegWidth-1:0]              df_memex_hi,
    input wire[`RegWidth-1:0]              df_memex_lo,
    input wire                             df_memex_hilo_we,
    // for pipeline stall
    input wire[`DoubleRegWidth-1:0]        hilo_tmp_i,
    input wire[1:0]                        cycl_cnt_i,

    // for jump or branch inst
    input wire                             cur_inst_delayslot_i,
    input wire[`RegWidth-1:0]              link_addr,
    // for division inst
    input wire[`DoubleRegWidth-1:0]        div_res,
    input wire                             div_done,
    // instruction current in exe stage (for load store inst)
    input wire[`RegWidth-1:0]              inst_i,
    // for exception handle
    input wire[`RegWidth-1:0]              except_type_i,
    input wire[`RegWidth-1:0]              cur_inst_addr_i,

    output reg[`RegWidth-1:0]              hi_o,
    output reg[`RegWidth-1:0]              lo_o,
    output reg                             hilo_we,

    output reg                             gpr_we_o,
    output reg[`GPR_AddrWidth-1:0]         target_gpr_o,
    output reg[`RegWidth-1:0]              exe_result_o,

    // for pipeline stall
    output reg[`DoubleRegWidth-1:0]        hilo_tmp_o,
    output reg[1:0]                        cycl_cnt_o,
    
    output reg                             stall_req,
    // for div module
    output reg                             signed_div,
    output reg[`RegWidth-1:0]              div_opdata1,
    output reg[`RegWidth-1:0]              div_opdata2,
    output reg                             div_start,

    // for load store inst
    output wire [`InstTypeWidth-1:0]         inst_type_o, 
    output wire [`RegWidth-1:0]              dmem_addr,
    output wire [`RegWidth-1:0]              ls_data_tmp,

    // for data reference consideration 
    input wire                            mem_cp0_we,
    input wire [4:0]                      mem_cp0_waddr,
    input wire [`RegWidth-1:0]            mem_cp0_wdata,
    input wire                            wb_cp0_we,
    input wire [4:0]                      wb_cp0_waddr,
    input wire [`RegWidth-1:0]            wb_cp0_wdata,
    // read registers from coprocessor0
    input wire [`RegWidth-1:0]            cp0_ex_rdata,
    output reg [4:0]                      ex_cp0_raddr,
    // for next stage "exmem"
    output reg                            cp0_we,
    output reg [4:0]                      cp0_waddr,
    output reg [`RegWidth-1:0]            cp0_wdata,
    // for exception handle
    output wire [`RegWidth-1:0]            except_type_o,
    output wire [`RegWidth-1:0]            cur_inst_addr_o,
    output wire                            cur_inst_delayslot_o

);
    // used to keep execute result.
    reg [`RegWidth-1:0]       move_res;
    reg [`RegWidth-1:0]       logic_res;
    reg [`RegWidth-1:0]       shift_res;
    reg [`RegWidth-1:0]       arith_res;


    reg [`RegWidth-1:0]       hi;
    reg [`RegWidth-1:0]       lo;

    // for arithmetic operation. 
    wire                      overflow;      // overflow flag
    wire                      reg1_eq_reg2;  // reg1 equal with reg2 flag
    wire                      reg1_lt_reg2;  // reg1 less than reg2 flag
    wire[`RegWidth-1:0]       com_gpr2_data; // complement of gpr2' data
    wire[`RegWidth-1:0]       inv_gpr1_data; // invert of gpr1's data
    wire[`RegWidth-1:0]       sum_res;       // result of summator 
    wire[`RegWidth-1:0]       mul_opdata1;   // multiplicand 
    wire[`RegWidth-1:0]       mul_opdata2;   // multiplicator 

    wire[`DoubleRegWidth-1:0] mul_res_tmp;   // temperate result of multiply
    reg [`DoubleRegWidth-1:0] mul_res_tmp1;  // temperate result of multiply for madd,msub

    reg [`DoubleRegWidth-1:0] mul_res;       // result of multiply

    reg                       maddmsub_stall_req;
    reg                       div_stall_req;

    reg                       trap_except;
    reg                       over_except;
    /////////////////////////
    // load and store data pass 
    /////////////////////////
    assign inst_type_o = inst_type;
    assign dmem_addr = gpr1_data + {{16{inst_i[15]}},inst_i[15:0]}; 
    assign ls_data_tmp = gpr2_data;
    /////////////////////////
    // Arithmetic Operation 
    /////////////////////////
    // negation of gpr1_data
    assign inv_gpr1_data = ~gpr1_data;
    // complement code for substraction or compare operation
    // source code for other operations
    assign com_gpr2_data = ((inst_type == `INST_T_SUB)  ||
                            (inst_type == `INST_T_SUBU) ||
                            (inst_type == `INST_T_SLT)  ||
                            (inst_type == `INST_T_TLT)  ||  // signed trap instruction
                            (inst_type == `INST_T_TLTI) ||
                            (inst_type == `INST_T_TGE)  ||
                            (inst_type == `INST_T_TGEI)) ?
                            (~gpr2_data)+1 : gpr2_data;
                         
    // a. sum_res = result of add operation
    // b. sum_res = result of sub operation(com_gpr2_data is complement code)
    // c. sum_res = result of sub operation for compare operation
    assign sum_res = gpr1_data + com_gpr2_data;

    //
    assign overflow =  ((!gpr1_data[31] && !com_gpr2_data[31]) &&   sum_res[31]) ||
                       (( gpr1_data[31] &&  com_gpr2_data[31]) && (!sum_res[31]));

    assign reg1_lt_reg2 = (( inst_type == `INST_T_SLT       ) || 
                           ( inst_type == `INST_T_TLT       ) ||  // signed trap instruction
                           ( inst_type == `INST_T_TLTI      ) ||
                           ( inst_type == `INST_T_TGE       ) ||
                           ( inst_type == `INST_T_TGEI      )) ?
                          (( gpr1_data[31] && !gpr2_data[31]) ||   
                           (!gpr1_data[31] && !gpr2_data[31] && sum_res[31]) ||  
                           ( gpr1_data[31] &&  gpr2_data[31] && sum_res[31])):
                           ( gpr1_data < gpr2_data); 

      
    // for exception
    assign except_type_o = {except_type_i[31:12],over_except,trap_except,except_type_i[9:8],8'h00};
    assign cur_inst_delayslot_o = cur_inst_delayslot_i;
    assign cur_inst_addr_o = cur_inst_addr_i;

    always @ (*)
    begin  
      if(rst == 1'b1)
      begin  
       arith_res <= {`RegWidth{1'b0}};  
      end
      else
      begin  
        case (inst_type)
          `INST_T_SLT, `INST_T_SLTU:
          begin  
            arith_res <= reg1_lt_reg2 ;
          end  
          `INST_T_ADD, `INST_T_ADDU, `INST_T_ADDI, `INST_T_ADDIU:  
          begin      
            arith_res <= sum_res;
          end  
          `INST_T_SUB, `INST_T_SUBU:
          begin  
            arith_res <= sum_res;
          end        
          `INST_T_CLZ:
          begin
            arith_res <= gpr1_data[31] ? 0  : gpr1_data[30] ? 1  :  
                         gpr1_data[29] ? 2  : gpr1_data[28] ? 3  :  
                         gpr1_data[27] ? 4  : gpr1_data[26] ? 5  :  
                         gpr1_data[25] ? 6  : gpr1_data[24] ? 7  :  
                         gpr1_data[23] ? 8  : gpr1_data[22] ? 9  :  
                         gpr1_data[21] ? 10 : gpr1_data[20] ? 11 :  
                         gpr1_data[19] ? 12 : gpr1_data[18] ? 13 :  
                         gpr1_data[17] ? 14 : gpr1_data[16] ? 15 :  
                         gpr1_data[15] ? 16 : gpr1_data[14] ? 17 :  
                         gpr1_data[13] ? 18 : gpr1_data[12] ? 19 :  
                         gpr1_data[11] ? 20 : gpr1_data[10] ? 21 :  
                         gpr1_data[9]  ? 22 : gpr1_data[8]  ? 23 :  
                         gpr1_data[7]  ? 24 : gpr1_data[6]  ? 25 :  
                         gpr1_data[5]  ? 26 : gpr1_data[4]  ? 27 :  
                         gpr1_data[3]  ? 28 : gpr1_data[2]  ? 29 :  
                         gpr1_data[1]  ? 30 : gpr1_data[0]  ? 31 : 32 ;  
          end  
          `INST_T_CLO:
          begin
            arith_res <= inv_gpr1_data[31] ? 0  : inv_gpr1_data[30] ? 1  :  
                         inv_gpr1_data[29] ? 2  : inv_gpr1_data[28] ? 3  :   
                         inv_gpr1_data[27] ? 4  : inv_gpr1_data[26] ? 5  :  
                         inv_gpr1_data[25] ? 6  : inv_gpr1_data[24] ? 7  :   
                         inv_gpr1_data[23] ? 8  : inv_gpr1_data[22] ? 9  :   
                         inv_gpr1_data[21] ? 10 : inv_gpr1_data[20] ? 11 :  
                         inv_gpr1_data[19] ? 12 : inv_gpr1_data[18] ? 13 :   
                         inv_gpr1_data[17] ? 14 : inv_gpr1_data[16] ? 15 :   
                         inv_gpr1_data[15] ? 16 : inv_gpr1_data[14] ? 17 :   
                         inv_gpr1_data[13] ? 18 : inv_gpr1_data[12] ? 19 :   
                         inv_gpr1_data[11] ? 20 : inv_gpr1_data[10] ? 21 :   
                         inv_gpr1_data[9]  ? 22 : inv_gpr1_data[8]  ? 23 :   
                         inv_gpr1_data[7]  ? 24 : inv_gpr1_data[6]  ? 25 :   
                         inv_gpr1_data[5]  ? 26 : inv_gpr1_data[4]  ? 27 :   
                         inv_gpr1_data[3]  ? 28 : inv_gpr1_data[2]  ? 29 :   
                         inv_gpr1_data[1]  ? 30 : inv_gpr1_data[0]  ? 31 : 32 ;  
          end  
          default:
          begin  
            arith_res <= {`RegWidth{1'b0}};  
          end  
        endcase  
      end  
    end  

    // multiplication
    // get multiplicant
    assign mul_opdata1=(((inst_type == `INST_T_MUL ) ||
                         (inst_type == `INST_T_MULT) ||
                         (inst_type == `INST_T_MADD) ||
                         (inst_type == `INST_T_MSUB))&&
                         (gpr1_data[31] == 1'b1)) ? (~gpr1_data + 1) : gpr1_data;  

    // get multiplicator
    assign mul_opdata2=(((inst_type == `INST_T_MUL ) ||
                         (inst_type == `INST_T_MULT) ||
                         (inst_type == `INST_T_MADD) ||
                         (inst_type == `INST_T_MSUB))&&
                         (gpr2_data[31] == 1'b1)) ? (~gpr2_data + 1) : gpr2_data;  

    assign mul_res_tmp = mul_opdata1 * mul_opdata2;

    // modify the multiplication result
    always @ (*)
    begin  
      if(rst == `RstEnable)
      begin  
         mul_res <= {`DoubleRegWidth{1'b0}};
      end
      else if ((inst_type == `INST_T_MULT) ||
               (inst_type == `INST_T_MUL ) ||
               (inst_type == `INST_T_MADD) ||
               (inst_type == `INST_T_MSUB)) 
      begin

        if(gpr1_data[31] ^ gpr2_data[31] == 1'b1)
        begin  
          mul_res <= ~mul_res_tmp + 1;  
        end
        else
        begin  
          mul_res <= mul_res_tmp;  
        end

      end 
      else // multu operation
      begin
         mul_res <= mul_res_tmp;  
      end
    end

    always @ (*)
    begin  
    if(rst == `RstEnable) begin  
      hilo_tmp_o         <= {`DoubleRegWidth{1'b0}};  
      cycl_cnt_o         <= 2'b00;  
      maddmsub_stall_req <= 1'b0;  
    end else begin  
        case (inst_type)   
           `INST_T_MADD, `INST_T_MADDU:
           begin
             if(cycl_cnt_i == 2'b00) // first execute cycle   
             begin
               hilo_tmp_o         <= mul_res;  
               cycl_cnt_o         <= 2'b01;  
               mul_res_tmp1       <= {`DoubleRegWidth{1'b0}};  
               maddmsub_stall_req <= 1'b1;  
             end
             else if(cycl_cnt_i == 2'b01) // second execute cycle
             begin
               hilo_tmp_o         <= {`DoubleRegWidth{1'b0}};                        
               mul_res_tmp1       <= hilo_tmp_i + {hi,lo};  
               cycl_cnt_o         <= 2'b10;  
               maddmsub_stall_req <= 1'b0;  
             end  
           end  
           `INST_T_MSUB, `INST_T_MSUBU:
           begin
             if(cycl_cnt_i == 2'b00) // first execute cycle
             begin
               hilo_tmp_o         <= ~mul_res + 1 ;  
               cycl_cnt_o         <= 2'b01;  
               maddmsub_stall_req <= 1'b1;  
             end else if(cycl_cnt_i == 2'b01) // second execute cycle
             begin
               hilo_tmp_o         <= {`DoubleRegWidth{1'b0}};                        
               mul_res_tmp1       <= hilo_tmp_i + {hi,lo};  
               cycl_cnt_o         <= 2'b10;  
               maddmsub_stall_req <= 1'b0;  // no stall
             end               
         end  
         default:
         begin  
           hilo_tmp_o             <= {`DoubleRegWidth{1'b0}};  
           cycl_cnt_o             <= 2'b00;  
           maddmsub_stall_req     <= 1'b0;  // no stall 
         end  
       endcase  
     end  
    end    

    // div module interface
    always @ (*)
    begin  
      if(rst == `RstEnable)
      begin  
        div_opdata1    <= {`RegWidth{1'b0}};  
        div_opdata2    <= {`RegWidth{1'b0}};  
        div_start      <= 1'b0;   // division stop 
        signed_div     <= 1'b0;  
        div_stall_req  <= 1'b0;  
      end
      else
      begin  
        div_opdata1    <= {`RegWidth{1'b0}};  
        div_opdata2    <= {`RegWidth{1'b0}};  
        div_start      <= 1'b0;  
        signed_div     <= 1'b0;   
        div_stall_req  <= 1'b0;  
        case (inst_type)   
          `INST_T_DIV:
          begin
              if(div_done == 1'b0) begin  
                div_opdata1    <= gpr1_data;      // dividend
                div_opdata2    <= gpr2_data;      // divisor
                div_start      <= 1'b1;           // start division
                signed_div     <= 1'b1;           // signed division
                div_stall_req  <= 1'b1;           // request stall pipeline
              end else if(div_done == 1'b1) begin  
                div_opdata1    <= gpr1_data;  
                div_opdata2    <= gpr2_data;  
                div_start      <= 1'b0;           // division stop 
                signed_div     <= 1'b1;  
                div_stall_req  <= 1'b0;           // call back stall request
              end else begin  
                div_opdata1    <= {`RegWidth{1'b0}};  
                div_opdata2    <= {`RegWidth{1'b0}};  
                div_start      <= 1'b0;  
                signed_div     <= 1'b0;  
                div_stall_req  <= 1'b0;  
              end                     
          end  
          `INST_T_DIVU:
          begin
              if(div_done == 1'b0) begin  
                div_opdata1    <= gpr1_data;  
                div_opdata2    <= gpr2_data;  
                div_start      <= 1'b1;  
                signed_div     <= 1'b0;           // unsigned division
                div_stall_req  <= 1'b1;  
              end else if(div_done == 1'b1) begin  
                div_opdata1    <= gpr1_data;  
                div_opdata2    <= gpr2_data;  
                div_start      <= 1'b0;  
                signed_div     <= 1'b0;  
                div_stall_req  <= 1'b0;  
              end else begin  
                div_opdata1    <= {`RegWidth{1'b0}};  
                div_opdata2    <= {`RegWidth{1'b0}};  
                div_start      <= 1'b0;  
                signed_div     <= 1'b0;  
                div_stall_req  <= 1'b0;  
              end  
          end  
          default: begin end  
        endcase  
      end  
    end 

    // stall request generate
    always @ (*)
    begin
      stall_req <= maddmsub_stall_req || div_stall_req;
    end
    /////////////////////////
    // exception chargement 
    /////////////////////////
    always @ (*)
    begin
        if(rst == `RstEnable)
        begin
            trap_except <= 1'b0;  // trap not assert
        end else begin
            trap_except <= 1'b0;
            case (inst_type)
                `INST_T_TEQ, `INST_T_TEQI:
                begin
                    if( gpr1_data == gpr2_data ) begin
                        trap_except <= 1'b1;
                    end
                end
                `INST_T_TGE, `INST_T_TGEI, `INST_T_TGEIU, `INST_T_TGEU:
                begin
                    if( ~reg1_lt_reg2 ) begin
                        trap_except <= 1'b1;
                    end
                end
                `INST_T_TLT, `INST_T_TLTI, `INST_T_TLTIU, `INST_T_TLTU:
                begin
                    if( reg1_lt_reg2 ) begin
                        trap_except <= 1'b1;
                    end
                end
                `INST_T_TNE, `INST_T_TNEI:
                begin
                    if( gpr1_data != gpr2_data ) begin
                        trap_except <= 1'b1;
                    end
                end 
                default:                begin
                    trap_except <= 1'b0;
                end
            endcase 
        end
    end



    /////////////////////////
    // LOGIC Operation 
    /////////////////////////
    always @ (*) begin
      if(rst == `RstEnable) begin
        logic_res <= 1'b0;
      end else begin
        case (inst_type)
          `INST_T_OR: // including OR, ORI 
          begin
            logic_res <=   gpr1_data |  gpr2_data;
          end
          `INST_T_XOR: // including XOR, XORI
          begin
            logic_res <=   gpr1_data ^  gpr2_data;
          end
          `INST_T_NOR:
          begin
            logic_res <= ~(gpr1_data | gpr2_data);
          end
          `INST_T_AND: // including AND, ANDI
          begin
            logic_res <=   gpr1_data & gpr2_data;
          end
          default:
          begin
            logic_res <= 1'b0;
          end
        endcase
      end    //if
    end      //always
    /////////////////////////
    // SHIFT Operation 
    /////////////////////////
    always @ (*) begin
      if(rst == `RstEnable) begin
        shift_res <= 1'b0;
      end else begin
        case (inst_type)
          `INST_T_SLL: // rd <= rt(gpr2) << sa(gpr1);
          begin
            shift_res <=   gpr2_data << gpr1_data[4:0];
          end
          `INST_T_SRL:
          begin
            shift_res <=   gpr2_data >> gpr1_data[4:0];
          end
          `INST_T_SRA:
          begin
            shift_res <=   ({32{gpr2_data[31]}} << (6'd32-{1'b0, gpr1_data[4:0]}))
                          |(gpr2_data >> gpr1_data[4:0]);
          end
          default:
          begin
            shift_res <= 1'b0;
          end
        endcase
      end    //if
    end      //always
    /////////////////////////
    // MOVE Operation 
    /////////////////////////
    always @ (*) begin
      if(rst == `RstEnable) begin
        {hi,lo} <= {{`RegWidth{1'b0}},{`RegWidth{1'b0}}};
      end else if(df_memex_hilo_we == 1'b1) begin
        {hi,lo} <= {df_memex_hi,df_memex_lo};
      end else if(df_wbex_hilo_we == 1'b1) begin
        {hi,lo} <= {df_wbex_hi,df_wbex_lo};
      end else begin
        {hi,lo} <= {hi_i,lo_i};
      end
    end

    always @ (*) begin
      if(rst == `RstEnable)
      begin
        move_res <= 1'b0; 
      end
      else
      begin
        move_res <= 1'b0;
        case (inst_type)
         `INST_T_MFHI: move_res <= hi;
         `INST_T_MFLO: move_res <= lo;
         `INST_T_MOVZ: move_res <= gpr1_data;
         `INST_T_MOVN: move_res <= gpr1_data;

         `INST_T_MFC0:
         begin
             ex_cp0_raddr <= inst_i[15:11]; 

             if((mem_cp0_we == 1'b1) && (mem_cp0_waddr == inst_i[15:11]))
                 move_res <= mem_cp0_wdata;
             else if((wb_cp0_we == 1'b1) && (wb_cp0_waddr == inst_i[15:11]))
                 move_res <= wb_cp0_wdata;
             else
                 move_res <= cp0_ex_rdata;
             
         end 

         default : begin   end
        endcase
      end
    end

    always @ (*)
    begin
        if(rst == `RstEnable)
        begin
            cp0_we    <= 1'b0;
            cp0_waddr <= 5'b00000;
            cp0_wdata <= {`RegWidth{1'b0}};
        end
        else if(inst_type == `INST_T_MTC0)
        begin
            cp0_we    <= 1'b1;
            cp0_waddr <= inst_i[15:11];
            cp0_wdata <= gpr1_data;
        end else
        begin
            cp0_we    <= 1'b0;
            cp0_waddr <= 5'b00000;
            cp0_wdata <= {`RegWidth{1'b0}};
        end
    end

    always @ (*) begin
      if(rst == `RstEnable) begin
        hilo_we <= 1'b0; // write disable
        hi_o    <= {`RegWidth{1'b0}};
        lo_o    <= {`RegWidth{1'b0}};
      end
      else
      begin
        case(inst_type)
          `INST_T_MTHI:
          begin
            hilo_we <= 1'b1;
            hi_o    <= gpr1_data;
            lo_o    <= lo;
          end
          `INST_T_MTLO:
          begin
            hilo_we <= 1'b1;
            hi_o    <= hi;
            lo_o    <= gpr1_data;
          end
          `INST_T_MULT, `INST_T_MULTU:
          begin
            hilo_we <= 1'b1;
            hi_o    <= mul_res[63:32];
            lo_o    <= mul_res[31:0];
          end
          `INST_T_MSUB, `INST_T_MSUBU:
          begin
            hilo_we <= 1'b1;
            hi_o    <= mul_res_tmp1[63:32];
            lo_o    <= mul_res_tmp1[31:0];
          end
          `INST_T_MADD, `INST_T_MADDU:
          begin
            hilo_we <= 1'b1;
            hi_o    <= mul_res_tmp1[63:32];
            lo_o    <= mul_res_tmp1[31:0];
          end
          `INST_T_DIV, `INST_T_DIVU:
          begin
            hilo_we <= 1'b1;
            hi_o    <= div_res[63:32];
            lo_o    <= div_res[31:0];
          end
          default:
          begin
            hilo_we <= 1'b0;
            hi_o    <= {`RegWidth{1'b0}};
            lo_o    <= {`RegWidth{1'b0}};
          end
        endcase
      end
    end

    /////////////////////////
    // Execute result select
    /////////////////////////
    always @ (*) begin
      target_gpr_o <= target_gpr;              
      if(((inst_type == `INST_T_ADD)  || (inst_type == `INST_T_ADDI) ||   
          (inst_type == `INST_T_SUB)) && (overflow == 1'b1))
      begin  
         gpr_we_o <= 1'b0;  
         over_except <= 1'b1; // overflow exception assert
      end else begin  
         gpr_we_o <= gpr_we;  
         over_except <= 1'b0;
      end  
      case ( inst_class ) 
        `INST_C_LOGIC:
        begin
          exe_result_o <= logic_res;
        end
        `INST_C_SHIFT:
        begin
          exe_result_o <= shift_res;
        end
        `INST_C_MOVE:
        begin
          exe_result_o <= move_res;
        end
        `INST_C_ARITH:
        begin
          exe_result_o <= arith_res;
        end
        `INST_C_MUL:
        begin
          exe_result_o <= mul_res;
        end
        `INST_C_JUMPBRANCH:
        begin
          exe_result_o <= link_addr;
        end
        default:
        begin
          exe_result_o <= 1'b0;
        end
      endcase
    end    

endmodule
