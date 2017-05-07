
module inst_decode(

    input wire                           rst,
    input wire[`InstBusAddrWidth-1:0]    pc_i,
    input wire[`InstBusDataWidth-1:0]    inst_i,
    // from gpr
    input wire[`GPR_DataWidth-1:0]       gpr1_data_i,
    input wire[`GPR_DataWidth-1:0]       gpr2_data_i,
    /* data forward logic for RAW hazard */
    // data from instruction execute stage
    input wire                           df_exid_gpr_we,
    input wire[`GPR_AddrWidth-1:0]       df_exid_target_gpr,
    input wire[`GPR_DataWidth-1:0]       df_exid_exe_result,
    // data from memory access stage
    input wire                           df_memid_gpr_we,
    input wire[`GPR_AddrWidth-1:0]       df_memid_target_gpr,
    input wire[`GPR_DataWidth-1:0]       df_memid_exe_result,

    // ports for JUMPs and BRANCHes
    input wire                           curid_inst_delayslot_i, // current inst in id stage in delayslot flag.

    input wire[`InstTypeWidth-1:0]       ex_inst_type,

    // to gpr
    output reg                           gpr1_re,      //gpr port1 read enable, high active
    output reg                           gpr2_re,     
    output reg[`GPR_AddrWidth-1:0]       gpr1_addr,
    output reg[`GPR_AddrWidth-1:0]       gpr2_addr,           
    // data for execute stage 
    output reg[`InstTypeWidth-1:0]       inst_type,
    output reg[`InstClassWidth-1:0]      inst_class,
    output reg[`GPR_DataWidth-1:0]       gpr1_data_o,
    output reg[`GPR_DataWidth-1:0]       gpr2_data_o,
    output reg[`GPR_AddrWidth-1:0]       target_gpr,   //
    output reg                           gpr_we,       // high active

    output wire                          stall_req, 

    // ports for JUMPs and BRANCHes
    output reg                           branch_flag,
    output reg[`RegWidth-1:0]            branch_target_addr,
    output reg[`RegWidth-1:0]            link_addr,
    output reg                           nxtid_inst_delayslot_o,   // next inst in id stage in delayslot flag.
    output reg                           curid_inst_delayslot_o,   // current inst in id stage in delayslot flag.
    output wire[`RegWidth-1:0]           inst_o,
    // for exception consideration
    output wire[`RegWidth-1:0]           except_type,
    output wire[`RegWidth-1:0]           cur_inst_addr
 
);

  // get the instruction code, operation code etc.
  wire[5:0] opcode  = inst_i[31:26]; // 6-bit primary operation code 
  wire[4:0] rs      = inst_i[25:21]; // 5-bit specifier for the source register
  wire[4:0] rt      = inst_i[20:16]; // 5-bit specifier for the target(source/destination) register; 
  // R-Type instruction              //       used to specify functions within the primary opcode REGIMM
  wire[4:0] rd      = inst_i[15:11]; // 5-bit specifier for the destination register
  wire[4:0] sa      = inst_i[10:6];  // 5-bit shift amount
  wire[5:0] func    = inst_i[5:0];   // 6-bit function field used to specify functions within the primary opcode SPECIAL 
  // I-Type instruction
  wire[15:0]immediate   = inst_i[15:0]; // 16-bit signed immediate used for logical operands,arithmetic signed operands, 
  // J-Type instruction                 // load/store address byte offsets,PC relative branch signed instruction displacement
  wire[25:0]instr_index = inst_i[25:0]; // 26-bit index shifted left two bits to supply the low-order 28bits of jump target address
  
  reg [`GPR_DataWidth-1:0]       imm;      // used to keep immediate operand
  reg                            inst_valid;  // instruction valid, high active 
  reg                             excepttype_is_syscall; 
  reg                             excepttype_is_eret; 
  // for load relative
  reg                            gpr1_loadrelate_stallreq;
  reg                            gpr2_loadrelate_stallreq;
  wire                           pre_inst_load;

  wire[`InstBusAddrWidth-1:0]    pc_plus8 = pc_i + 8;
  wire[`InstBusAddrWidth-1:0]    pc_plus4 = pc_i + 4;

  wire[`InstBusAddrWidth-1:0]    imm_sll2_signext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };



    always @ (*) begin    
        if (rst == `RstEnable) begin
            inst_type     <= `INST_T_NOP;
            inst_class    <= `INST_C_NOP;
            gpr_we        <= 1'b0;  // write disable
            inst_valid    <= 1'b1;  // inst valid
            gpr1_re       <= 1'b0;
            gpr2_re       <= 1'b0;
            imm           <= 32'h0;            
            gpr1_addr     <= `NOPRegAddr;
            gpr2_addr     <= `NOPRegAddr;
            target_gpr    <= `NOPRegAddr;

            link_addr          <= 32'h0;
            branch_target_addr <= 32'h0;
            branch_flag        <= 1'b0;
            nxtid_inst_delayslot_o <= 1'b0;

            excepttype_is_syscall <= 1'b0;
            excepttype_is_eret    <= 1'b0;
        end else begin
            inst_type     <= `INST_T_NOP;
            inst_class    <= `INST_C_NOP;
            target_gpr    <= rd;
            gpr_we        <= 1'b0;
            inst_valid    <= 1'b0;  // inst invalid     
            gpr1_re       <= 1'b0;
            gpr2_re       <= 1'b0;
            gpr1_addr     <= rs;
            gpr2_addr     <= rt;        
            imm           <= 32'h0;            

            link_addr          <= 32'h0;
            branch_target_addr <= 32'h0;
            branch_flag        <= 1'b0;  // not branch
            nxtid_inst_delayslot_o <= 1'b0;  // not in delayslot

            excepttype_is_syscall <= 1'b0;
            excepttype_is_eret    <= 1'b0;

            case (opcode)
              `SPECIAL_INST:
              begin
//                case (sa)
//                  5'b00000:
//                  begin
                    if(rs == 5'b0)
                    begin

                      if(rt == 5'b0 && rd == 5'b0 && sa == 5'b0 && func == 6'b0)// consider about NOP 
                      begin
                        inst_valid    <= 1'b1;  // inst valid  
                        inst_type     <= `INST_T_NOP;
                        inst_class    <= `INST_C_NOP;
                      end else begin
                      case(func)
                        `INST_SLL:
                        begin
                          gpr_we      <= 1'b1;  // gpr write enable
                          gpr1_re     <= 1'b0;
                          gpr2_re     <= 1'b1;          
                          imm[4:0]    <= sa;
                          target_gpr  <= rd;
                          inst_valid  <= 1'b1;  // inst valid  
                          inst_type   <= `INST_T_SLL;
                          inst_class  <= `INST_C_SHIFT;
                        end
                        `INST_SRL:
                        begin
                          gpr_we      <= 1'b1;  // gpr write enable
                          gpr1_re     <= 1'b0;
                          gpr2_re     <= 1'b1;          
                          imm[4:0]    <= sa;
                          target_gpr  <= rd;
                          inst_valid  <= 1'b1;  // inst valid  
                          inst_type   <= `INST_T_SRL;
                          inst_class  <= `INST_C_SHIFT;
                        end
                        `INST_SRA:
                        begin
                          gpr_we      <= 1'b1;  // gpr write enable
                          gpr1_re     <= 1'b0;
                          gpr2_re     <= 1'b1;          
                          imm[4:0]    <= sa;
                          target_gpr  <= rd;
                          inst_valid  <= 1'b1;  // inst valid  
                          inst_type   <= `INST_T_SRA;
                          inst_class  <= `INST_C_SHIFT;
                        end
                        // rs rt rd sa configurable
                        `INST_SYSCALL: begin
                            gpr_we     <= 1'b0;
                            gpr1_re    <= 1'b0;
                            gpr2_re    <= 1'b0;
                            inst_valid <= 1'b1;
                            inst_type  <= `INST_T_SYSCALL;
                            inst_class <= `INST_C_NOP;
                            excepttype_is_syscall<= 1'b1; // high active
                        end  
                        // rs rt sa = 0
                        `INST_MFHI:
                        begin
                          gpr_we     <= 1'b1;
                          gpr1_re    <= 1'b0;
                          gpr2_re    <= 1'b0;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_MFHI;
                          inst_class <= `INST_C_MOVE;
                        end
                        // rs rt sa = 0
                        `INST_MFLO:
                        begin
                          gpr_we     <= 1'b1;
                          gpr1_re    <= 1'b0;
                          gpr2_re    <= 1'b0;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_MFLO;
                          inst_class <= `INST_C_MOVE;
                        end

                        default: begin  end
                      endcase // case func
                      end
                    end else begin
                      case (func)
                        `INST_AND:
                        begin
                          gpr_we      <= 1'b1; // GPR write enable
                          gpr1_re     <= 1'b1;
                          gpr2_re     <= 1'b1;          
                          inst_valid  <= 1'b1; // inst valid  
                          inst_type   <= `INST_T_AND;
                          inst_class  <= `INST_C_LOGIC;
                        end
                        `INST_OR:
                        begin
                          gpr_we      <= 1'b1; // GPR write enable
                          gpr1_re     <= 1'b1;
                          gpr2_re     <= 1'b1;          
                          inst_valid  <= 1'b1; // inst valid  
                          inst_type   <= `INST_T_OR;
                          inst_class  <= `INST_C_LOGIC;
                        end
                        `INST_XOR:
                        begin
                          gpr_we      <= 1'b1; // GPR write enable
                          gpr1_re     <= 1'b1;
                          gpr2_re     <= 1'b1;          
                          inst_valid  <= 1'b1; // inst valid  
                          inst_type   <= `INST_T_XOR;
                          inst_class  <= `INST_C_LOGIC;
                        end
                        `INST_NOR:
                        begin
                          gpr_we      <= 1'b1; // GPR write enable
                          gpr1_re     <= 1'b1;
                          gpr2_re     <= 1'b1;          
                          inst_valid  <= 1'b1; // inst valid  
                          inst_type   <= `INST_T_NOR;
                          inst_class  <= `INST_C_LOGIC;
                        end
                        `INST_SLLV:
                        begin
                          gpr_we      <= 1'b1; // GPR write enable
                          gpr1_re     <= 1'b1;
                          gpr2_re     <= 1'b1;          
                          inst_valid  <= 1'b1; // inst valid  
                          inst_type   <= `INST_T_SLL;
                          inst_class  <= `INST_C_SHIFT;
                        end
                        `INST_SRLV:
                        begin
                          gpr_we      <= 1'b1; // GPR write enable
                          gpr1_re     <= 1'b1;
                          gpr2_re     <= 1'b1;          
                          inst_valid  <= 1'b1; // inst valid  
                          inst_type   <= `INST_T_SRL;
                          inst_class  <= `INST_C_SHIFT;
                        end
                        `INST_SRAV:
                        begin
                          gpr_we      <= 1'b1; // GPR write enable
                          gpr1_re     <= 1'b1;
                          gpr2_re     <= 1'b1;          
                          inst_valid  <= 1'b1; // inst valid  
                          inst_type   <= `INST_T_SRA;
                          inst_class  <= `INST_C_SHIFT;
                        end
                        `INST_MTHI:
                        begin
                          gpr_we     <= 1'b0; // GPR write enable invalid
                          gpr1_re    <= 1'b1; // read rs from GPR
                          gpr2_re    <= 1'b0;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_MTHI;
                          inst_class <= `INST_C_MOVE;
                        end
                        `INST_MTLO:
                        begin
                          gpr_we     <= 1'b0; // GPR write enable invalid
                          gpr1_re    <= 1'b1; // read rs from GPR
                          gpr2_re    <= 1'b0;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_MTLO;
                          inst_class <= `INST_C_MOVE;
                        end
                        `INST_MOVN:
                        begin
                          if(gpr2_data_o != 1'b0) // rt
                          begin
                            gpr_we <= 1'b1;
                          end
                          else
                          begin
                            gpr_we <= 1'b0;
                          end
                          gpr1_re     <= 1'b1; // read rs
                          gpr2_re     <= 1'b1; // read rt
                          inst_valid  <= 1'b1;
                          inst_type   <= `INST_T_MOVN;
                          inst_class  <= `INST_C_MOVE;
                        end
                        `INST_MOVZ:
                        begin
                          if(gpr2_data_o == 1'b0)
                          begin
                            gpr_we <= 1'b1;
                          end
                          else
                          begin
                            gpr_we <= 1'b0;
                          end
                          gpr1_re     <= 1'b1;
                          gpr2_re     <= 1'b1;
                          inst_valid  <= 1'b1;
                          inst_type   <= `INST_T_MOVZ;
                          inst_class  <= `INST_C_MOVE;
                        end

                        `INST_SLT:
                        begin
                          gpr_we     <= 1'b1;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_SLT;
                          inst_class <= `INST_C_ARITH;
                        end
                        `INST_SLTU:
                        begin
                          gpr_we     <= 1'b1;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_SLTU;
                          inst_class <= `INST_C_ARITH;
                        end
                        `INST_ADD:
                         begin
                          gpr_we     <= 1'b1;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_ADD;
                          inst_class <= `INST_C_ARITH;
                        end
                        `INST_ADDU:
                        begin
                          gpr_we     <= 1'b1;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_ADDU;
                          inst_class <= `INST_C_ARITH;
                        end
                        `INST_SUB:
                        begin
                          gpr_we     <= 1'b1;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_SUB;
                          inst_class <= `INST_C_ARITH;
                        end
                        `INST_SUBU:
                        begin
                          gpr_we     <= 1'b1;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_SUBU;
                          inst_class <= `INST_C_ARITH;
                        end
                        `INST_MULT:
                        begin
                          gpr_we     <= 1'b0; // the multiply result will be recorded in hilo reg
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_MULT;
                          // the result wasn't written in GPR, so inst_class was default for convinient
                        end
                        `INST_MULTU:
                        begin
                          gpr_we     <= 1'b0; // the multiply result will be recorded in hilo reg
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_MULTU;
                          // the result wasn't written in GPR, so inst_class was default for convinient
                        end

                        `INST_DIV:
                        begin
                          gpr_we     <= 1'b0;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_DIV;
                        end
                        `INST_DIVU:
                        begin
                          gpr_we     <= 1'b0;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b1;
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_DIVU;
                        end   

                        `INST_JR:
                        begin
                          gpr_we             <= 1'b0;
                          gpr1_re            <= 1'b1;
                          gpr2_re            <= 1'b0;
                          link_addr          <= {`RegWidth{1'b0}};
                          branch_target_addr <= gpr1_data_o;
                          branch_flag        <= 1'b1;          // branch
                          nxtid_inst_delayslot_o <= 1'b1;          // in delayslot
                          inst_valid         <= 1'b1;          // inst valid
                          inst_type          <= `INST_T_JR;
                          inst_class         <= `INST_C_JUMPBRANCH;
                        end
                        `INST_JALR:
                        begin
                          gpr_we             <= 1'b1;
                          gpr1_re            <= 1'b1; // target address is in GPR rs
                          gpr2_re            <= 1'b0;
                          target_gpr         <= rd; 
                          link_addr          <= pc_plus8;
                          branch_target_addr <= gpr1_data_o;
                          branch_flag        <= 1'b1;
                          nxtid_inst_delayslot_o <= 1'b1;
                          inst_valid         <= 1'b1;
                          inst_type          <= `INST_T_JALR;
                          inst_class         <= `INST_C_JUMPBRANCH;
                        end    

                        `INST_SYNC:
                        begin
                          gpr_we             <= 1'b1; // GPR write enable
                          gpr1_re            <= 1'b0;
                          gpr2_re            <= 1'b1;          
                          inst_valid         <= 1'b1; // inst valid  
                          inst_type          <= `INST_T_NOP;
                          inst_class         <= `INST_C_NOP;
                        end

                        `INST_TEQ: begin
                            gpr_we     <= 1'b0;
                            gpr1_re    <= 1'b1; //read enable , book bug
                            gpr2_re    <= 1'b1;
                            inst_valid <= 1'b1;
                            inst_type  <= `INST_T_TEQ;
                            inst_class <= `INST_C_NOP;
                        end
                        `INST_TGE: begin
                            gpr_we     <= 1'b0;
                            gpr1_re    <= 1'b1;
                            gpr2_re    <= 1'b1;
                            inst_valid <= 1'b1;
                            inst_type  <= `INST_T_TGE;
                            inst_class <= `INST_C_NOP;
                        end
                        `INST_TGEU: begin
                            gpr_we     <= 1'b0;
                            gpr1_re    <= 1'b1;
                            gpr2_re    <= 1'b1;
                            inst_valid <= 1'b1;
                            inst_type  <= `INST_T_TGEU;
                            inst_class <= `INST_C_NOP;
                        end
                        `INST_TLT: begin
                            gpr_we     <= 1'b0;
                            gpr1_re    <= 1'b1;
                            gpr2_re    <= 1'b1;
                            inst_valid <= 1'b1;
                            inst_type  <= `INST_T_TLT;
                            inst_class <= `INST_C_NOP;
                        end
                        `INST_TLTU: begin
                            gpr_we     <= 1'b0;
                            gpr1_re    <= 1'b1;
                            gpr2_re    <= 1'b1;
                            inst_valid <= 1'b1;
                            inst_type  <= `INST_T_TLTU;
                            inst_class <= `INST_C_NOP;
                        end
                        `INST_TNE: begin
                            gpr_we     <= 1'b0;
                            gpr1_re    <= 1'b1;
                            gpr2_re    <= 1'b1;
                            inst_valid <= 1'b1;
                            inst_type  <= `INST_T_TNE;
                            inst_class <= `INST_C_NOP;
                        end


                        default: begin end
                      endcase   // case func 
                    end // if (rs ==0)

//                  end
//                default: begin end
//              endcase  // case sa
              end // SPECIAL INST


              `SPECIAL2_INST:
              begin
                case (func)
                  `INST_CLZ:
                  begin
                    gpr_we     <= 1'b1;
                    gpr1_re    <= 1'b1;
                    gpr2_re    <= 1'b0;
                    inst_valid <= 1'b1;
                    inst_type  <= `INST_T_CLZ;
                    inst_class <= `INST_C_ARITH;
                  end
                  `INST_CLO:
                  begin
                    gpr_we     <= 1'b1;
                    gpr1_re    <= 1'b1;
                    gpr2_re    <= 1'b0;
                    inst_valid <= 1'b1;
                    inst_type  <= `INST_T_CLO;
                    inst_class <= `INST_C_ARITH;
                  end
                  `INST_MUL:
                  begin
                    gpr_we     <= 1'b1;
                    gpr1_re    <= 1'b1;
                    gpr2_re    <= 1'b1;
                    inst_valid <= 1'b1;
                    inst_type  <= `INST_T_MUL;
                    inst_class <= `INST_C_MUL;
                  end

                  `INST_MADD:
                  begin
                    gpr_we        <= 1'b0;   // write disable  
                    gpr1_re       <= 1'b1;  
                    gpr2_re       <= 1'b1;  
                    inst_valid    <= 1'b1;  
                    inst_type     <= `INST_T_MADD;  
                    inst_class    <= `INST_C_MUL;   
                  end  
                  `INST_MADDU:
                  begin
                    gpr_we        <= 1'b0;   // write disable  
                    gpr1_re       <= 1'b1;      
                    gpr2_re       <= 1'b1;  
                    inst_valid    <= 1'b1;  
                    inst_type     <= `INST_T_MADDU;  
                    inst_class    <= `INST_C_MUL;   
                  end
                  `INST_MSUB:
                  begin
                    gpr_we        <= 1'b0;   // write disable  
                    gpr1_re       <= 1'b1;      
                    gpr2_re       <= 1'b1;  
                    inst_valid    <= 1'b1;  
                    inst_type     <= `INST_T_MSUB;  
                    inst_class    <= `INST_C_MUL;   
                  end  
                  `INST_MSUBU:
                  begin
                    gpr_we        <= 1'b0;   // write disable  
                    gpr1_re       <= 1'b1;      
                    gpr2_re       <= 1'b1;  
                    inst_valid    <= 1'b1;    
                    inst_type     <= `INST_T_MSUBU;  
                    inst_class    <= `INST_C_MUL;   
                  end  
                  default: begin end
                endcase      // SPECIAL2_INST case
              end

              `INST_ORI:
              begin
                gpr_we      <= 1'b1;  // gpr write enable
                gpr1_re     <= 1'b1;
                gpr2_re     <= 1'b0;          
                imm         <= {16'h0, immediate};
                target_gpr  <= rt;
                inst_valid  <= 1'b1;  // inst valid  
                inst_type   <= `INST_T_OR;
                inst_class  <= `INST_C_LOGIC;
              end                              
              `INST_ANDI:
              begin
                gpr_we      <= 1'b1;  // gpr write enable
                gpr1_re     <= 1'b1;
                gpr2_re     <= 1'b0;          
                imm         <= {16'h0, immediate};
                target_gpr  <= rt;
                inst_valid  <= 1'b1;  // inst valid  
                inst_type   <= `INST_T_AND;
                inst_class  <= `INST_C_LOGIC;
              end                              
              `INST_XORI:
              begin
                gpr_we      <= 1'b1;  // gpr write enable
                gpr1_re     <= 1'b1;
                gpr2_re     <= 1'b0;          
                imm         <= {16'h0, immediate};
                target_gpr  <= rt;
                inst_valid  <= 1'b1;  // inst valid  
                inst_type   <= `INST_T_XOR;
                inst_class  <= `INST_C_LOGIC;
              end                              
              `INST_LUI:
              begin
                gpr_we      <= 1'b1;  // gpr write enable
                gpr1_re     <= 1'b1;
                gpr2_re     <= 1'b0;          
                imm         <= {immediate,16'h0}; // left shift 16bits
                target_gpr  <= rt;
                inst_valid  <= 1'b1;  // inst valid  
                inst_type   <= `INST_T_OR;
                inst_class  <= `INST_C_LOGIC;
              end                              

              `INST_SLTI:
              begin
                gpr_we      <= 1'b1;
                gpr1_re     <= 1'b1;
                gpr2_re     <= 1'b0;
                imm         <= {{16{inst_i[15]}}, immediate};  // sign externed
                target_gpr  <= rt;
                inst_valid  <= 1'b1;
                inst_type   <= `INST_T_SLT;
                inst_class  <= `INST_C_ARITH;
              end
              `INST_SLTIU:
              begin
                gpr_we      <= 1'b1;
                gpr1_re     <= 1'b1;
                gpr2_re     <= 1'b0;
                imm         <= {{16{inst_i[15]}}, immediate}; // sign externed
                target_gpr  <= rt;
                inst_valid  <= 1'b1;
                inst_type   <= `INST_T_SLTU;
                inst_class  <= `INST_C_ARITH;
              end
              `INST_ADDI:
              begin
                gpr_we      <= 1'b1;
                gpr1_re     <= 1'b1;
                gpr2_re     <= 1'b0;
                imm         <= {{16{inst_i[15]}}, immediate}; // sign externed
                target_gpr  <= rt;
                inst_valid  <= 1'b1;
                inst_type   <= `INST_T_ADDI;
                inst_class  <= `INST_C_ARITH;
              end
              `INST_ADDIU:
              begin
                gpr_we     <= 1'b1;
                gpr1_re    <= 1'b1;
                gpr2_re    <= 1'b0;
                imm        <= {{16{inst_i[15]}}, immediate}; // sign externed
                target_gpr <= rt;
                inst_valid <= 1'b1;
                inst_type  <= `INST_T_ADDIU;
                inst_class <= `INST_C_ARITH;
              end

              `INST_J:
              begin
                gpr_we             <= 1'b0;
                inst_type          <= `INST_T_J;
                inst_class         <= `INST_C_JUMPBRANCH;
                gpr1_re            <= 1'b0;
                gpr2_re            <= 1'b0;
                link_addr          <= {`RegWidth{1'b0}};
                branch_target_addr <= {pc_plus4[31:28], instr_index, 2'b00};
                branch_flag        <= 1'b1;
                nxtid_inst_delayslot_o <= 1'b1;           
                inst_valid         <= 1'b1;    
              end
              `INST_JAL:
              begin
                gpr_we             <= 1'b1;
                inst_type          <= `INST_T_JAL;
                inst_class         <= `INST_C_JUMPBRANCH;
                gpr1_re            <= 1'b0;
                gpr2_re            <= 1'b0;
                target_gpr         <= 5'b11111;  // $31 
                link_addr          <= pc_plus8 ;
                branch_target_addr <= {pc_plus4[31:28], instr_index, 2'b00};
                branch_flag        <= 1'b1;
                nxtid_inst_delayslot_o <= 1'b1;           
                inst_valid         <= 1'b1;    
              end
              `INST_BEQ:
              begin
                gpr_we             <= 1'b0;
                inst_type          <= `INST_T_BEQ;
                inst_class         <= `INST_C_JUMPBRANCH;
                gpr1_re            <= 1'b1;
                gpr2_re            <= 1'b1;
                inst_valid         <= 1'b1;    
                if(gpr1_data_o == gpr2_data_o)
                begin
                  branch_target_addr <= pc_plus4 + imm_sll2_signext;
                  branch_flag        <= 1'b1;
                  nxtid_inst_delayslot_o <= 1'b1;
                end
              end
              `INST_BGTZ:
              begin
                gpr_we               <= 1'b0;
                inst_type            <= `INST_T_BGTZ;
                inst_class           <= `INST_C_JUMPBRANCH;
                gpr1_re              <= 1'b1;
                gpr2_re              <= 1'b0;
                inst_valid           <= 1'b1;
                if((gpr1_data_o[31] == 1'b0) && (gpr1_data_o != {`RegWidth{1'b0}}))
                begin
                  branch_target_addr <= pc_plus4 + imm_sll2_signext;
                  branch_flag        <= 1'b1;
                  nxtid_inst_delayslot_o <= 1'b1;
                end
              end

              `INST_BLEZ:
              begin
                gpr_we               <= 1'b0;
                inst_type            <= `INST_T_BLEZ;
                inst_class           <= `INST_C_JUMPBRANCH;
                gpr1_re              <= 1'b1;
                gpr2_re              <= 1'b0;
                inst_valid           <= 1'b1;
                if((gpr1_data_o[31] == 1'b1) || (gpr1_data_o == {`RegWidth{1'b0}}))
                begin
                  branch_target_addr <= pc_plus4 + imm_sll2_signext;
                  branch_flag        <= 1'b1;
                  nxtid_inst_delayslot_o <= 1'b1;
                end
              end
              `INST_BNE:
              begin
                gpr_we               <= 1'b0;
                inst_type            <= `INST_T_BLEZ;
                inst_class           <= `INST_C_JUMPBRANCH;
                gpr1_re              <= 1'b1;
                gpr2_re              <= 1'b1;
                inst_valid           <= 1'b1;
                if(gpr1_data_o != gpr2_data_o)
                begin
                  branch_target_addr <= pc_plus4 + imm_sll2_signext;
                  branch_flag        <= 1'b1;
                  nxtid_inst_delayslot_o <= 1'b1;
                end
              end
              // load store instructions decode
            `INST_LB:
            begin
                gpr_we        <= 1'b1;  
                gpr1_re       <= 1'b1;    
                gpr2_re       <= 1'b0;  
                target_gpr    <= rt;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_LB;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  
            `INST_LBU:
            begin
                gpr_we        <= 1'b1;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b0;  
                target_gpr    <= rt;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_LBU;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  
            `INST_LH:
            begin
                gpr_we        <= 1'b1;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b0;  
                target_gpr    <= rt;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_LH;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  
            `INST_LHU:
            begin
                gpr_we        <= 1'b1;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b0;  
                target_gpr    <= rt;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_LHU;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  
            `INST_LW:
            begin
                gpr_we        <= 1'b1;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b0;  
                target_gpr    <= rt;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_LW;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  

            `INST_LL:
            begin
                gpr_we        <= 1'b1;  
                gpr1_re       <= 1'b1;   
                gpr2_re       <= 1'b0;  
                target_gpr    <= rt;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_LL;  
                inst_class    <= `INST_C_LOADSTORE;   
            end

            `INST_LWL:
            begin
                gpr_we        <= 1'b1;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b1;  
                target_gpr    <= rt;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_LWL;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  
            `INST_LWR:
            begin
                gpr_we        <= 1'b1;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b1;  
                target_gpr    <= rt;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_LWR;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  
            `INST_SB:
            begin
                gpr_we        <= 1'b0;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b1;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_SB;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  
            `INST_SH:
            begin
                gpr_we        <= 1'b0;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b1;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_SH;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  
            `INST_SW:
            begin
                gpr_we        <= 1'b0;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b1;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_SW;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  

            `INST_SC:
            begin
                gpr_we        <= 1'b1;  
                gpr1_re       <= 1'b1;   
                gpr2_re       <= 1'b1;  
                target_gpr    <= rt;   
                inst_valid    <= 1'b1;   
                inst_type     <= `INST_T_SC;  
                inst_class    <= `INST_C_LOADSTORE;   
            end   

            `INST_SWL:
            begin
                gpr_we        <= 1'b0;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b1;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_SWL;  
                inst_class    <= `INST_C_LOADSTORE;   
            end  
            `INST_SWR:
            begin
                gpr_we        <= 1'b0;  
                gpr1_re       <= 1'b1;  
                gpr2_re       <= 1'b1;   
                inst_valid    <= 1'b1;  
                inst_type     <= `INST_T_SWR;  
                inst_class    <= `INST_C_LOADSTORE;  
            end  

              `REGIMM_INST:
              begin
                  case (rt)
                      `INST_BGEZ:
                      begin
                        gpr_we               <= 1'b0;
                        inst_type            <= `INST_T_BGEZ;
                        inst_class           <= `INST_C_JUMPBRANCH;
                        gpr1_re              <= 1'b1;
                        gpr2_re              <= 1'b0;
                        inst_valid           <= 1'b1;
                        if(gpr1_data_o[31] == 1'b0)
                        begin
                          branch_target_addr <= pc_plus4 + imm_sll2_signext;
                          branch_flag        <= 1'b1;
                          nxtid_inst_delayslot_o <= 1'b1;
                        end
                      end

                      `INST_BGEZAL:
                      begin
                        gpr_we               <= 1'b1;
                        inst_type            <= `INST_T_BGEZAL;
                        inst_class           <= `INST_C_JUMPBRANCH;
                        gpr1_re              <= 1'b1;
                        gpr2_re              <= 1'b0;
                        link_addr            <= pc_plus8;
                        target_gpr           <= 5'b11111;
                        inst_valid           <= 1'b1;
                        if(gpr1_data_o[31] == 1'b0)
                        begin
                          branch_target_addr <= pc_plus4 + imm_sll2_signext;
                          branch_flag        <= 1'b1;
                          nxtid_inst_delayslot_o <= 1'b1;
                        end
                      end

                      `INST_BLTZ:
                      begin
                        gpr_we                <= 1'b0;
                        inst_type             <= `INST_T_BGEZAL;
                        inst_class            <= `INST_C_JUMPBRANCH;
                        gpr1_re               <= 1'b1;
                        gpr2_re               <= 1'b0;
                        inst_valid            <= 1'b1;
                        if(gpr1_data_o[31] == 1'b1)
                        begin
                            branch_target_addr <= pc_plus4 + imm_sll2_signext;
                            branch_flag        <= 1'b1;
                            nxtid_inst_delayslot_o <= 1'b1;
                        end
                      end

                      `INST_BLTZAL:
                      begin
                        gpr_we                 <= 1'b1;
                        inst_type              <= `INST_T_BGEZAL;
                        inst_class             <= `INST_C_JUMPBRANCH;
                        gpr1_re                <= 1'b1;
                        gpr2_re                <= 1'b0;
                        link_addr              <= pc_plus8;
                        target_gpr             <= 5'b11111;
                        inst_valid             <= 1'b1;
                        if(gpr1_data_o[31] == 1'b1)
                        begin
                          branch_target_addr   <= pc_plus4 + imm_sll2_signext;
                          branch_flag          <= 1'b1;
                          nxtid_inst_delayslot_o   <= 1'b1;
                        end
                      end

                      `INST_TEQI:
                      begin
                          gpr_we     <= 1'b0;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b0;
                          imm        <= {{16{inst_i[15]}}, inst_i[15:0]};
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_TEQI;
                          inst_class <= `INST_C_NOP;
                      end
                      `INST_TGEI:
                      begin
                          gpr_we     <= 1'b0;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b0;
                          imm        <= {{16{inst_i[15]}}, inst_i[15:0]};
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_TGEI;
                          inst_class <= `INST_C_NOP;
                      end
                      `INST_TGEIU:
                      begin
                          gpr_we     <= 1'b0;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b0;
                          imm        <= {{16{inst_i[15]}}, inst_i[15:0]};
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_TGEIU;
                          inst_class <= `INST_C_NOP;
                      end
                      `INST_TLTI:
                      begin
                          gpr_we     <= 1'b0;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b0;
                          imm        <= {{16{inst_i[15]}}, inst_i[15:0]};
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_TLTI;
                          inst_class <= `INST_C_NOP;
                      end
                      `INST_TLTIU:
                      begin
                          gpr_we     <= 1'b0;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b0;
                          imm        <= {{16{inst_i[15]}}, inst_i[15:0]};
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_TLTIU;
                          inst_class <= `INST_C_NOP;
                      end
                      `INST_TNEI:
                      begin
                          gpr_we     <= 1'b0;
                          gpr1_re    <= 1'b1;
                          gpr2_re    <= 1'b0;
                          imm        <= {{16{inst_i[15]}}, inst_i[15:0]};
                          inst_valid <= 1'b1;
                          inst_type  <= `INST_T_TNEI;
                          inst_class <= `INST_C_NOP;
                      end


                      default:    begin end
                  endcase
              end

              `COP0_INST:
              begin
                  if(inst_i[10:0] == 11'b0)
                  begin                  
                      case(rs) // inst[25:21]
                          `INST_MFC0:
                          begin
                              inst_type   <= `INST_T_MFC0;
                              inst_class  <= `INST_C_MOVE;
                              gpr_we      <= 1'b1;
                              inst_valid  <= 1'b1;
                              gpr1_re     <= 1'b0;
                              gpr2_re     <= 1'b0;
                              target_gpr  <= rt;
                          end
                          `INST_MTC0:
                          begin
                              inst_type   <= `INST_T_MTC0;
                              inst_class  <= `INST_C_MOVE;
                              gpr_we      <= 1'b0;  // gpr write disable
                              inst_valid  <= 1'b1;
                              gpr1_re     <= 1'b1;
                              gpr2_re     <= 1'b0;
                              gpr1_addr   <= rt;
                          end
    
                      endcase
                  end
                  else
                  begin
                      if(func == `INST_ERET && inst_i[25] == 1'b1) begin
                         gpr_we            <= 1'b0;
                         gpr1_re           <= 1'b0;
                         gpr2_re           <= 1'b0;
                         inst_valid        <= 1'b1;
                         excepttype_is_eret<= 1'b1;  
                         inst_type         <= `INST_T_ERET;
                         inst_class        <= `INST_C_NOP;
                      end        
                  end
              end

              `INST_PREF:
              begin
                gpr_we      <= 1'b1;  // gpr write enable
                gpr1_re     <= 1'b0;
                gpr2_re     <= 1'b0;          
                imm         <= {16'h0, immediate};
                target_gpr  <= rt;
                inst_valid  <= 1'b1;  // inst valid  
                inst_type   <= `INST_T_NOP;
                inst_class  <= `INST_C_NOP;
              end                              

              default : begin end
            endcase //case opcode            
      end // end if reset enable
    end //always
    

    always @ (*) begin
        gpr1_loadrelate_stallreq <= 1'b0;
        if(rst == `RstEnable) begin
            gpr1_data_o <= 1'b0;
        end else if((pre_inst_load ==1'b1)
                 && (df_exid_gpr_we == 1'b1)
                 && (df_exid_target_gpr == gpr1_addr)) begin
            gpr1_loadrelate_stallreq <= 1'b1;
        end else if((gpr1_re == 1'b1)
                 && (df_exid_gpr_we == 1'b1)
                 && (df_exid_target_gpr == gpr1_addr)) begin
            gpr1_data_o <= df_exid_exe_result;
        end else if((gpr1_re == 1'b1)
                 && (df_memid_gpr_we == 1'b1)
                 && (df_memid_target_gpr == gpr1_addr)) begin
            gpr1_data_o <= df_memid_exe_result;
        end else if(gpr1_re == 1'b1) begin
            gpr1_data_o <= gpr1_data_i;
        end else if(gpr1_re == 1'b0) begin
            gpr1_data_o <= imm;
        end else begin
            gpr1_data_o <= 1'b0;
        end
    end
    
    always @ (*) begin
        gpr2_loadrelate_stallreq <= 1'b0;
        if(rst == `RstEnable) begin
            gpr2_data_o <= 1'b0;
        end else if((pre_inst_load ==1'b1)
                 && (df_exid_gpr_we == 1'b1)
                 && (df_exid_target_gpr == gpr2_addr)) begin
            gpr2_loadrelate_stallreq <= 1'b1;
        end else if((gpr2_re == 1'b1)
                 && (df_exid_gpr_we == 1'b1)
                 && (df_exid_target_gpr == gpr2_addr)) begin
            gpr2_data_o <= df_exid_exe_result;
        end else if((gpr2_re == 1'b1)
                 && (df_memid_gpr_we == 1'b1)
                 && (df_memid_target_gpr == gpr2_addr)) begin
            gpr2_data_o <= df_memid_exe_result;
        end else if(gpr2_re == 1'b1) begin
            gpr2_data_o <= gpr2_data_i;
        end else if(gpr2_re == 1'b0) begin
            gpr2_data_o <= imm;
        end else begin
            gpr2_data_o <= 1'b0;
        end
    end

    always @ (*) begin  
      if(rst == `RstEnable) begin  
        curid_inst_delayslot_o <= 1'b0;  
      end else begin  
        curid_inst_delayslot_o <= curid_inst_delayslot_i;   
      end  
    end  

    assign inst_o    = inst_i;

    assign stall_req = gpr1_loadrelate_stallreq | gpr2_loadrelate_stallreq;
    assign pre_inst_load = ((ex_inst_type == `INST_T_LB ) ||
                            (ex_inst_type == `INST_T_LBU) ||
                            (ex_inst_type == `INST_T_LH ) ||
                            (ex_inst_type == `INST_T_LHU) ||
                            (ex_inst_type == `INST_T_LW ) ||
                            (ex_inst_type == `INST_T_LWR) ||
                            (ex_inst_type == `INST_T_LWL) ||
                            (ex_inst_type == `INST_T_LL ) ||
                            (ex_inst_type == `INST_T_SC )) ?
                            1'b1 : 1'b0;

    assign except_type = {19'b0,excepttype_is_eret,2'b0, ~inst_valid, excepttype_is_syscall,8'b0};
  //assign excepttye_is_trapinst = 1'b0;

    assign cur_inst_addr = pc_i;




endmodule
