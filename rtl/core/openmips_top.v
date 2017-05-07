
module openmips_top(

    input  wire                               clk,
    input  wire                               rst,

    input  wire[5:0]                          int_vec,
    output wire                               tim_int,

    input  wire [`RegWidth-1:0]               ibus_data_i, 
    input  wire                               ibus_ack_i, 
    output wire [`RegWidth-1:0]               ibus_addr_o, 
    output wire [`RegWidth-1:0]               ibus_data_o, 
    output wire                               ibus_we_o, 
    output wire [3:0]                         ibus_sel_o, 
    output wire                               ibus_stb_o, 
    output wire                               ibus_cyc_o, 
    
    input  wire [`RegWidth-1:0]               dbus_data_i, 
    input  wire                               dbus_ack_i, 
    output wire [`RegWidth-1:0]               dbus_addr_o, 
    output wire [`RegWidth-1:0]               dbus_data_o, 
    output wire                               dbus_we_o, 
    output wire [3:0]                         dbus_sel_o, 
    output wire                               dbus_stb_o, 
    output wire                               dbus_cyc_o 

);
    // wire between ifid and id
    wire[`InstBusAddrWidth-1:0] if_ifid_pc;
    wire[`InstBusAddrWidth-1:0] ifid_id_pc;
    wire[`InstBusDataWidth-1:0] ifid_id_inst;
    // wire between id and idex
    wire[`InstClassWidth-1:0] id_idex_instClass;
    wire[`InstTypeWidth-1:0]  id_idex_instType;
    wire[`GPR_DataWidth-1:0]  id_idex_gpr1Data;
    wire[`GPR_DataWidth-1:0]  id_idex_gpr2Data;
    wire[`GPR_AddrWidth-1:0]  id_idex_targetGpr;
    wire                      id_idex_gprWe;
    // wire between idex and ex
    wire[`InstClassWidth-1:0] idex_ex_instClass;
    wire[`InstTypeWidth-1:0]  idex_ex_instType;
    wire[`GPR_DataWidth-1:0]  idex_ex_gpr1Data;
    wire[`GPR_DataWidth-1:0]  idex_ex_gpr2Data;
    wire[`GPR_AddrWidth-1:0]  idex_ex_targetGpr;
    wire                      idex_ex_gprWe;
    /* output of execute stage */
    wire[`RegWidth-1:0]      hilo_ex_hi;
    wire[`RegWidth-1:0]      hilo_ex_lo;

    wire[`RegWidth-1:0]      ex_exmem_hi;
    wire[`RegWidth-1:0]      ex_exmem_lo;
    wire                     ex_exmem_hiloWe;

    wire                     ex_x_gprWe;
    wire[`GPR_AddrWidth-1:0] ex_x_targetGpr;
    wire[`GPR_DataWidth-1:0] ex_x_exeResult;
    // wire form ex to exmem
    wire                     ex_exmem_gprWe;
    wire[`GPR_AddrWidth-1:0] ex_exmem_targetGpr;
    wire[`GPR_DataWidth-1:0] ex_exmem_exeResult;
    // wire form ex to id  (data forward) 
    wire                     df_exid_gprWe;
    wire[`GPR_AddrWidth-1:0] df_exid_targetGpr;
    wire[`GPR_DataWidth-1:0] df_exid_exeResult;

    // wire between exmem and mem
    wire                     exmem_mem_gprWe;
    wire[`GPR_AddrWidth-1:0] exmem_mem_targetGpr;
    wire[`GPR_DataWidth-1:0] exmem_mem_exeResult;

    wire[`RegWidth-1:0]      exmem_mem_hi; 
    wire[`RegWidth-1:0]      exmem_mem_lo; 
    wire                     exmem_mem_hiloWe; 



    /* output of mem stage */
    wire                     mem_x_gprWe;
    wire[`GPR_AddrWidth-1:0] mem_x_targetGpr;
    wire[`GPR_DataWidth-1:0] mem_x_exeResult;

    wire[`RegWidth-1:0]      mem_x_hi;
    wire[`RegWidth-1:0]      mem_x_lo;
    wire                     mem_x_hiloWe;

    wire[`RegWidth-1:0]      df_memex_hi;
    wire[`RegWidth-1:0]      df_memex_lo;
    wire                     df_memex_hiloWe;

    // wire form mem to memwb 
    wire[`RegWidth-1:0]      mem_memwb_hi;
    wire[`RegWidth-1:0]      mem_memwb_lo;
    wire                     mem_memwb_hiloWe;

    wire                     mem_memwb_gprWe;
    wire[`GPR_AddrWidth-1:0] mem_memwb_targetGpr;
    wire[`GPR_DataWidth-1:0] mem_memwb_exeResult;


    // wire form mem to id  (data forward) 
    wire                     df_memid_gprWe;
    wire[`GPR_AddrWidth-1:0] df_memid_targetGpr;
    wire[`GPR_DataWidth-1:0] df_memid_exeResult;

    // wire between memwb and wb
    wire                     memwb_wb_gprWe;
    wire[`GPR_AddrWidth-1:0] memwb_wb_targetGpr;
    wire[`GPR_DataWidth-1:0] memwb_wb_exeResult;

    wire[`RegWidth-1:0]      wb_x_hi;
    wire[`RegWidth-1:0]      wb_x_lo;
    wire                     wb_x_hiloWe;

    wire[`RegWidth-1:0]      wb_hilo_hi;
    wire[`RegWidth-1:0]      wb_hilo_lo;
    wire                     wb_hilo_hiloWe;
    wire[`RegWidth-1:0]      df_wbex_hi;
    wire[`RegWidth-1:0]      df_wbex_lo;
    wire                     df_wbex_hiloWe;
 
    // wire between id and gpr
    wire                     id_gpr_gpr1Re;
    wire                     id_gpr_gpr2Re;
    wire[`GPR_DataWidth-1:0] gpr_id_gpr1Data;
    wire[`GPR_DataWidth-1:0] gpr_id_gpr2Data;
    wire[`GPR_AddrWidth-1:0] id_gpr_gpr1Addr;
    wire[`GPR_AddrWidth-1:0] id_gpr_gpr2Addr;
  
    wire                        if_ctrl_stallReq;
    wire                        id_ctrl_stallReq;
    wire                        ex_ctrl_stallReq;
    wire                        mem_ctrl_stallReq;
    wire[5:0]                   ctrl_x_stallCtrl;

    wire[5:0]                   ctrl_if_stallCtrl;
    wire[5:0]                   ctrl_ifid_stallCtrl;
    wire[5:0]                   ctrl_idex_stallCtrl;
    wire[5:0]                   ctrl_exmem_stallCtrl;
    wire[5:0]                   ctrl_memwb_stallCtrl;
    wire[5:0]                   ctrl_ibus_stallCtrl;
    wire[5:0]                   ctrl_dbus_stallCtrl;

    wire[`DoubleRegWidth-1:0]   exmem_ex_hiloTmp;
    wire[1:0]                   exmem_ex_cyclCnt;
    wire[`DoubleRegWidth-1:0]   ex_exmem_hiloTmp;
    wire[1:0]                   ex_exmem_cyclCnt;

    // div module interface
    wire[`DoubleRegWidth-1:0]   div_ex_divRes;
    wire                        div_ex_divDone;
    wire                        ex_div_signedDiv;
    wire[`RegWidth-1:0]         ex_div_divOpdata1;
    wire[`RegWidth-1:0]         ex_div_divOpdata2;
    wire                        ex_div_divStart;

    // jump branch instruchions

    wire                        id_pc_branchFlag;
    wire[`RegWidth-1:0]         id_pc_branchTargetAddr;
    wire[`RegWidth-1:0]         id_idex_linkAddr;
    wire[`RegWidth-1:0]         idex_ex_linkAddr;

    wire                        id_idex_nxtidInstDelayslot;
    wire                        id_idex_InstDelayslot;
    wire                        idex_id_instDelayslot;
    wire                        idex_ex_instDelayslot;

    wire [`InstTypeWidth-1:0]   exmem_mem_instType;
    wire [`RegWidth-1:0]        exmem_mem_dmemAddr;
    wire [`RegWidth-1:0]        exmem_mem_lsDataTmp;

    wire [`InstTypeWidth-1:0]   ex_exmem_instType;  
    wire [`InstTypeWidth-1:0]   ex_id_instType;  
    wire [`InstTypeWidth-1:0]   ex_x_instType;  

    wire [`RegWidth-1:0]        ex_exmem_dmemAddr;  
    wire [`RegWidth-1:0]        ex_exmem_lsDataTmp;  

    wire                        memwb_llbit_llbitWe;
    wire                        memwb_llbit_llbitValue;
    wire                        memwb_mem_llbitWe;
    wire                        memwb_mem_llbitValue;
    wire                        memwb_x_llbitWe;
    wire                        memwb_x_llbitValue;
    wire                        llbit_mem_llbitValue;
    wire                        mem_memwb_llbitWe;
    wire                        mem_memwb_llbitValue;

    wire[`RegWidth-1:0]         id_idex_inst;
    wire[`RegWidth-1:0]         idex_ex_inst;

    wire [4:0]                  ex_cp0_cp0Raddr;
    wire [`RegWidth-1:0]        cp0_ex_cp0Rdata;
       
    wire                        ex_exmem_cp0We;      
    wire [4:0]                  ex_exmem_cp0Waddr;   
    wire [`RegWidth-1:0]        ex_exmem_cp0Wdata;   
    wire                        exmem_mem_cp0We;     
    wire [4:0]                  exmem_mem_cp0Waddr;  
    wire [`RegWidth-1:0]        exmem_mem_cp0Wdata;  
       
    wire                        mem_x_cp0We;         
    wire [4:0]                  mem_x_cp0Waddr;      
    wire [`RegWidth-1:0]        mem_x_cp0Wdata;      
    wire                        mem_memwb_cp0We;    
    wire [4:0]                  mem_memwb_cp0Waddr; 
    wire [`RegWidth-1:0]        mem_memwb_cp0Wdata; 
    wire                        mem_ex_cp0We;     
    wire [4:0]                  mem_ex_cp0Waddr;  
    wire [`RegWidth-1:0]        mem_ex_cp0Wdata;  
       
    wire                        wb_x_cp0We;         
    wire [4:0]                  wb_x_cp0Waddr;      
    wire [`RegWidth-1:0]        wb_x_cp0Wdata;      
    wire                        wb_ex_cp0We;      
    wire [4:0]                  wb_ex_cp0Waddr;   
    wire [`RegWidth-1:0]        wb_ex_cp0Wdata;   
    wire                        wb_cp0_cp0We;
    wire [4:0]                  wb_cp0_cp0Waddr;
    wire [`RegWidth-1:0]        wb_cp0_cp0Wdata;
    // for exception
    wire                        ctrl_x_flush;           
    wire [`RegWidth-1:0]        ctrl_pc_newPc;
    wire [`RegWidth-1:0]        id_idex_exceptType;
    wire [`RegWidth-1:0]        id_idex_instAddr;
    wire [`RegWidth-1:0]        idex_ex_exceptType;
    wire [`RegWidth-1:0]        idex_ex_instAddr;

    wire [`RegWidth-1:0]        ex_exmem_exceptType;
    wire [`RegWidth-1:0]        ex_exmem_instAddr;
    wire                        ex_exmem_instDelayslot;
    wire [`RegWidth-1:0]        exmem_mem_exceptType;
    wire [`RegWidth-1:0]        exmem_mem_instAddr;
    wire                        exmem_mem_instDelayslot;

    wire [`RegWidth-1:0]        cp0_mem_status;
    wire [`RegWidth-1:0]        cp0_mem_cause;
    wire [`RegWidth-1:0]        cp0_mem_epc;

    wire                        wb_mem_cp0We;
    wire [4:0]                  wb_mem_cp0Waddr;      
    wire [`RegWidth-1:0]        wb_mem_cp0Wdata;      

    wire [`RegWidth-1:0]        mem_x_exceptType;
    wire [`RegWidth-1:0]        mem_ctrl_exceptType;
    wire [`RegWidth-1:0]        mem_cp0_exceptType;
    wire [`RegWidth-1:0]        mem_ctrl_epc;

    wire [`RegWidth-1:0]        mem_cp0_instAddr;
    wire                        mem_cp0_instDelayslot;

    wire[`RegWidth-1:0]                dbus_mem_data;
    wire[`RegWidth-1:0]                mem_dbus_data;
    wire[`RegWidth-1:0]                mem_dbus_addr;
    wire[3:0]                          mem_dbus_byteSel;
    wire                               mem_dbus_we;
    wire                               mem_dbus_ce;

    wire[`RegWidth-1:0]                ibus_ifid_data;
    wire[`RegWidth-1:0]                if_ibus_addr;
    wire                               if_ibus_ce;

  pc_reg  i_pc_reg(
      .clk                 (clk                   ),
      .rst                 (rst                   ),
      .stall_ctrl          (ctrl_if_stallCtrl     ),
      .branch_flag         (id_pc_branchFlag      ),
      .branch_target_addr  (id_pc_branchTargetAddr),

      .flush               (ctrl_x_flush          ),
      .pc_new              (ctrl_pc_newPc         ),

      .pc                  (if_ifid_pc            ),
      .inst_mem_en         (if_ibus_ce             )    
  );
    
  assign if_ibus_addr = if_ifid_pc;

  pipe_reg_ifid   i_pipe_reg_ifid(
      .clk         (clk                ),
      .rst         (rst                ),
      .stall_ctrl  (ctrl_ifid_stallCtrl),
      .flush       (ctrl_x_flush          ),

      .if_pc       (if_ifid_pc         ),
      .if_inst     (ibus_ifid_data      ),
      .id_pc       (ifid_id_pc         ),
      .id_inst     (ifid_id_inst       ) 
  );
    
  inst_decode   i_inst_decode(
      .rst               (rst        ),
      .pc_i              (ifid_id_pc ),
      .inst_i            (ifid_id_inst),
      // from gpr
      .gpr1_data_i       (gpr_id_gpr1Data),
      .gpr2_data_i       (gpr_id_gpr2Data),
      // to gpr
      .gpr1_re           (id_gpr_gpr1Re),
      .gpr2_re           (id_gpr_gpr2Re),       
      .gpr1_addr         (id_gpr_gpr1Addr),
      .gpr2_addr         (id_gpr_gpr2Addr), 
      // for execute stage
      .inst_type         (id_idex_instType),
      .inst_class        (id_idex_instClass),
      .gpr1_data_o       (id_idex_gpr1Data),
      .gpr2_data_o       (id_idex_gpr2Data),
      .target_gpr        (id_idex_targetGpr),
      .gpr_we            (id_idex_gprWe),
      // data forward for RAW hazard
      .df_exid_gpr_we            (df_exid_gprWe       ),
      .df_exid_target_gpr        (df_exid_targetGpr   ),
      .df_exid_exe_result        (df_exid_exeResult   ),
      .df_memid_gpr_we           (df_memid_gprWe      ),
      .df_memid_target_gpr       (df_memid_targetGpr  ),
      .df_memid_exe_result       (df_memid_exeResult  ),

      .stall_req                 (id_ctrl_stallReq    ),
      // from idex, which means current instruction in id stage is in delayslot
      .curid_inst_delayslot_i    (idex_id_instDelayslot),

      .branch_flag               (id_pc_branchFlag          ),
      .branch_target_addr        (id_pc_branchTargetAddr    ),
      .link_addr                 (id_idex_linkAddr          ),
      // to idex, which means next instruction  
      .nxtid_inst_delayslot_o    (id_idex_nxtidInstDelayslot),
      // to idex, which means current instruction in id stage is in delayslot
      // the "current" here is different from "current" above, think it over.
      // those "current" is the next inst of this "current"
      .curid_inst_delayslot_o    (id_idex_InstDelayslot),

      .inst_o                    (id_idex_inst),

      .ex_inst_type              (ex_id_instType),

      .except_type               (id_idex_exceptType),
      .cur_inst_addr             (id_idex_instAddr  )
    );

  gpr    i_gpr(
      .clk          (clk),
      .rst          (rst),
      .we           (memwb_wb_gprWe),
      .waddr        (memwb_wb_targetGpr),
      .wdata        (memwb_wb_exeResult),
      .re1          (id_gpr_gpr1Re),
      .raddr1       (id_gpr_gpr1Addr),
      .rdata1       (gpr_id_gpr1Data),
      .re2          (id_gpr_gpr2Re),
      .raddr2       (id_gpr_gpr2Addr),
      .rdata2       (gpr_id_gpr2Data)
  );

  pipe_reg_idex    i_pipe_reg_idex(
      .clk                (clk),
      .rst                (rst),
      .stall_ctrl         (ctrl_idex_stallCtrl),
      .flush              (ctrl_x_flush          ),
      // from id 
      .id_inst_type       (id_idex_instType),
      .id_inst_class      (id_idex_instClass),
      .id_gpr1_data       (id_idex_gpr1Data),
      .id_gpr2_data       (id_idex_gpr2Data),
      .id_target_gpr      (id_idex_targetGpr),
      .id_gpr_we          (id_idex_gprWe),

      .id_link_addr         (id_idex_linkAddr          ),
      .id_inst_delayslot    (id_idex_InstDelayslot),
   .nxtid_inst_delayslot    (id_idex_nxtidInstDelayslot),
      .id_except_type       (id_idex_exceptType),
      .id_cur_inst_addr     (id_idex_instAddr  ),
      // to ex
      .ex_inst_type         (idex_ex_instType),
      .ex_inst_class        (idex_ex_instClass),
      .ex_gpr1_data         (idex_ex_gpr1Data),
      .ex_gpr2_data         (idex_ex_gpr2Data),
      .ex_target_gpr        (idex_ex_targetGpr),
      .ex_gpr_we            (idex_ex_gprWe),

      .ex_link_addr         (idex_ex_linkAddr          ),
      .ex_inst_delayslot    (idex_ex_instDelayslot),
      // to id
      .nxt_inst_delayslot   (idex_id_instDelayslot),
      .id_inst              (id_idex_inst),
      .ex_inst              (idex_ex_inst),
      .ex_except_type       (idex_ex_exceptType),
      .ex_cur_inst_addr     (idex_ex_instAddr  )
  );        
  
  inst_execute    i_inst_execute(
      .rst                (rst),
      // from decode
      .inst_type          (idex_ex_instType),
      .inst_class         (idex_ex_instClass),
      .gpr1_data          (idex_ex_gpr1Data),
      .gpr2_data          (idex_ex_gpr2Data),
      .target_gpr         (idex_ex_targetGpr),
      .gpr_we             (idex_ex_gprWe),
      // to mem access stage or id stage
      .gpr_we_o           (ex_x_gprWe      ),
      .target_gpr_o       (ex_x_targetGpr  ),
      .exe_result_o       (ex_x_exeResult  ),
      // data from hilo register
      .hi_i               (hilo_ex_hi      ),
      .lo_i               (hilo_ex_lo      ),
      // hilo data forward
      .df_wbex_hi         (df_wbex_hi      ),
      .df_wbex_lo         (df_wbex_lo      ),
      .df_wbex_hilo_we    (df_wbex_hiloWe  ),
      .df_memex_hi        (df_memex_hi     ),
      .df_memex_lo        (df_memex_lo     ),
      .df_memex_hilo_we   (df_memex_hiloWe ),
      // data write to hilo register
      .hi_o               (ex_exmem_hi     ),
      .lo_o               (ex_exmem_lo     ),
      .hilo_we            (ex_exmem_hiloWe ),

      .hilo_tmp_i         (exmem_ex_hiloTmp),
      .cycl_cnt_i         (exmem_ex_cyclCnt),
      .hilo_tmp_o         (ex_exmem_hiloTmp),
      .cycl_cnt_o         (ex_exmem_cyclCnt),

      .stall_req          (ex_ctrl_stallReq),
      // divider interface
      .div_res             (div_ex_divRes    ),
      .div_done            (div_ex_divDone   ),

      .signed_div          (ex_div_signedDiv ),
      .div_opdata1         (ex_div_divOpdata1),
      .div_opdata2         (ex_div_divOpdata2),
      .div_start           (ex_div_divStart  ),

      // for jump or branch inst
      .cur_inst_delayslot_i(idex_ex_instDelayslot),
      .link_addr           (idex_ex_linkAddr),

      .inst_type_o         (ex_x_instType       ),
      .dmem_addr           (ex_exmem_dmemAddr   ),
      .ls_data_tmp         (ex_exmem_lsDataTmp  ),

      .inst_i              (idex_ex_inst),

      .mem_cp0_we           (mem_ex_cp0We     ),
      .mem_cp0_waddr        (mem_ex_cp0Waddr  ),
      .mem_cp0_wdata        (mem_ex_cp0Wdata  ),
      .wb_cp0_we            (wb_ex_cp0We      ),
      .wb_cp0_waddr         (wb_ex_cp0Waddr   ),
      .wb_cp0_wdata         (wb_ex_cp0Wdata   ),
      .cp0_ex_rdata         (cp0_ex_cp0Rdata  ),
      .ex_cp0_raddr         (ex_cp0_cp0Raddr  ),
      .cp0_we               (ex_exmem_cp0We   ),
      .cp0_waddr            (ex_exmem_cp0Waddr),
      .cp0_wdata            (ex_exmem_cp0Wdata),
      // for exception
      .except_type_i        (idex_ex_exceptType    ),
      .cur_inst_addr_i      (idex_ex_instAddr      ),
      .except_type_o        (ex_exmem_exceptType   ),
      .cur_inst_addr_o      (ex_exmem_instAddr     ),
      .cur_inst_delayslot_o (ex_exmem_instDelayslot)

  );

  pipe_reg_exmem    i_piep_reg_exmem(
      .clk                 (clk           ),
      .rst                 (rst           ),
      // from exe stage 
      .ex_gpr_we           (ex_exmem_gprWe),
      .ex_target_gpr       (ex_exmem_targetGpr),
      .ex_exe_result       (ex_exmem_exeResult),
      .ex_hi               (ex_exmem_hi),
      .ex_lo               (ex_exmem_lo),
      .ex_hilo_we          (ex_exmem_hiloWe),

      // to memory access stage
      .mem_gpr_we          (exmem_mem_gprWe     ),
      .mem_target_gpr      (exmem_mem_targetGpr ),
      .mem_exe_result      (exmem_mem_exeResult ),
      .mem_hi              (exmem_mem_hi        ), 
      .mem_lo              (exmem_mem_lo        ), 
      .mem_hilo_we         (exmem_mem_hiloWe    ),

      .ex_hilo_tmp_i       (ex_exmem_hiloTmp    ),
      .ex_cycl_cnt_i       (ex_exmem_cyclCnt    ),
      .ex_hilo_tmp_o       (exmem_ex_hiloTmp    ),
      .ex_cycl_cnt_o       (exmem_ex_cyclCnt    ),

      .stall_ctrl          (ctrl_exmem_stallCtrl),

      .ex_inst_type        (ex_exmem_instType   ),
      .ex_dmem_addr        (ex_exmem_dmemAddr   ),
      .ex_ls_data_tmp      (ex_exmem_lsDataTmp  ),

      .mem_inst_type       (exmem_mem_instType  ),
      .mem_dmem_addr       (exmem_mem_dmemAddr  ),
      .mem_ls_data_tmp     (exmem_mem_lsDataTmp ),

      .ex_cp0_we           (ex_exmem_cp0We      ),
      .ex_cp0_waddr        (ex_exmem_cp0Waddr   ),
      .ex_cp0_wdata        (ex_exmem_cp0Wdata   ),
      .mem_cp0_we          (exmem_mem_cp0We     ),
      .mem_cp0_waddr       (exmem_mem_cp0Waddr  ),
      .mem_cp0_wdata       (exmem_mem_cp0Wdata  ),
      // for exception
      .flush               (ctrl_x_flush           ),
      .ex_except_type      (ex_exmem_exceptType    ),
      .ex_cur_inst_addr    (ex_exmem_instAddr      ),
      .ex_inst_delayslot   (ex_exmem_instDelayslot ),
      .mem_except_type     (exmem_mem_exceptType   ),
      .mem_cur_inst_addr   (exmem_mem_instAddr     ),
      .mem_inst_delayslot  (exmem_mem_instDelayslot)
 
  );
  
  mem_access    i_mem_access(
      .rst                 (rst                ),
      // from exe stage
      .gpr_we              (exmem_mem_gprWe    ),
      .target_gpr          (exmem_mem_targetGpr),
      .exe_result          (exmem_mem_exeResult),
      .hi                  (exmem_mem_hi       ),
      .lo                  (exmem_mem_lo       ),
      .hilo_we             (exmem_mem_hiloWe   ),
      // to write back stage or id stage
      .gpr_we_o            (mem_x_gprWe        ),
      .target_gpr_o        (mem_x_targetGpr    ),
      .exe_result_o        (mem_x_exeResult    ),
      .hi_o                (mem_x_hi           ),
      .lo_o                (mem_x_lo           ),
      .hilo_we_o           (mem_x_hiloWe       ),

      .inst_type           (exmem_mem_instType ),
      .dmem_addr_i         (exmem_mem_dmemAddr ),
      .ls_data_tmp         (exmem_mem_lsDataTmp),
      .dmem_data_i         (dbus_mem_data       ),

      .dmem_addr_o         (mem_dbus_addr       ),
      .dmem_data_o         (mem_dbus_data       ),
      .dmem_byte_sel       (mem_dbus_byteSel    ),
      .dmem_we             (mem_dbus_we         ),
      .dmem_ce             (mem_dbus_ce         ),

      .llbit_i             (llbit_mem_llbitValue),
      .wb_llbit_we         (memwb_mem_llbitWe   ),
      .wb_llbit_value      (memwb_mem_llbitValue),
      .mem_llbit_we        (mem_memwb_llbitWe   ),
      .mem_llbit_value     (mem_memwb_llbitValue),

      .cp0_we_i            (exmem_mem_cp0We     ),
      .cp0_waddr_i         (exmem_mem_cp0Waddr  ),
      .cp0_wdata_i         (exmem_mem_cp0Wdata  ),
      .cp0_we_o            (mem_x_cp0We         ),
      .cp0_waddr_o         (mem_x_cp0Waddr      ),
      .cp0_wdata_o         (mem_x_cp0Wdata      ),
      // for exception
      .except_type_i       (exmem_mem_exceptType   ),
      .cur_inst_addr_i     (exmem_mem_instAddr     ),
      .in_delayslot_i      (exmem_mem_instDelayslot),
      .cp0_status_i        (cp0_mem_status         ),
      .cp0_cause_i         (cp0_mem_cause          ),
      .cp0_epc_i           (cp0_mem_epc            ),
      .wb_cp0_we           (wb_mem_cp0We           ),
      .wb_cp0_waddr        (wb_mem_cp0Waddr        ),
      .wb_cp0_wdata        (wb_mem_cp0Wdata        ),

      .except_type_o       (mem_x_exceptType     ),
      .cp0_epc_o           (mem_ctrl_epc         ),
      .cur_inst_addr_o     (mem_cp0_instAddr     ),
      .in_delayslot_o      (mem_cp0_instDelayslot)
  );

  pipe_reg_memwb    i_pipe_reg_memwb(
      .clk                    (clk),
      .rst                    (rst),
      // form memory access stage
      .mem_gpr_we             (mem_memwb_gprWe),
      .mem_target_gpr         (mem_memwb_targetGpr),
      .mem_exe_result         (mem_memwb_exeResult),
      .mem_hi                 (mem_memwb_hi       ),
      .mem_lo                 (mem_memwb_lo       ),
      .mem_hilo_we            (mem_memwb_hiloWe   ),
      // to write back stage
      .wb_gpr_we              (memwb_wb_gprWe),
      .wb_target_gpr          (memwb_wb_targetGpr),
      .wb_exe_result          (memwb_wb_exeResult),
      .wb_hi                  (wb_x_hi    ),
      .wb_lo                  (wb_x_lo    ),
      .wb_hilo_we             (wb_x_hiloWe),

      .stall_ctrl             (ctrl_memwb_stallCtrl),
      .flush                  (ctrl_x_flush          ),

      .mem_llbit_we           (mem_memwb_llbitWe   ),
      .mem_llbit_value        (mem_memwb_llbitValue),
      .wb_llbit_we            (memwb_llbit_llbitWe   ),
      .wb_llbit_value         (memwb_llbit_llbitValue),

      .mem_cp0_we             (mem_memwb_cp0We    ),
      .mem_cp0_waddr          (mem_memwb_cp0Waddr ),
      .mem_cp0_wdata          (mem_memwb_cp0Wdata ),
      .wb_cp0_we              (wb_x_cp0We         ),
      .wb_cp0_waddr           (wb_x_cp0Waddr      ),
      .wb_cp0_wdata           (wb_x_cp0Wdata      )

  );

  hilo_reg i_hilo_reg(
      .clk                    (clk            ),
      .rst                    (rst            ),

      .we                     (wb_hilo_hiloWe ),
      .hi_i                   (wb_hilo_hi     ),
      .lo_i                   (wb_hilo_lo     ),

      .hi_o                   (hilo_ex_hi     ),
      .lo_o                   (hilo_ex_lo     )
  );

  llbit_reg i_llbit_reg(
      .clk                    (clk                   ),
      .rst                    (rst                   ),
      .we                     (memwb_llbit_llbitWe   ),
      .flush                  (ctrl_x_flush          ),
      .llbit_i                (memwb_llbit_llbitValue),
      .llbit_o                (llbit_mem_llbitValue  )

  );

  pipe_ctrl i_pipe_ctrl(
      .rst                  (rst             ),
      .stall_req_if         (if_ctrl_stallReq),
      .stall_req_id         (id_ctrl_stallReq),
      .stall_req_ex         (ex_ctrl_stallReq),
      .stall_req_mem        (mem_ctrl_stallReq),
      .flush                (ctrl_x_flush          ),
      .except_type          (mem_ctrl_exceptType   ),
      .cp0_epc              (mem_ctrl_epc          ),
      .pc_new               (ctrl_pc_newPc),
      .stall_ctrl           (ctrl_x_stallCtrl)
  );

  div i_div(
      .clk                  (clk),
      .rst                  (rst),

      .signed_div           (ex_div_signedDiv),
      .div_opdata1          (ex_div_divOpdata1),
      .div_opdata2          (ex_div_divOpdata2),
      .div_start            (ex_div_divStart  ),
      .div_cancel           (ctrl_x_flush     ),

      .div_res              (div_ex_divRes),
      .div_done             (div_ex_divDone)

  );

  coprocessor0  i_coprocessor0(
      .except_type_i     (mem_cp0_exceptType   ),
      .cur_inst_addr_i   (mem_cp0_instAddr     ),
      .in_delayslot_i    (mem_cp0_instDelayslot),

      .clk               (clk),
      .rst               (rst),
      .cp0_reg_we        (wb_cp0_cp0We   ),
      .cp0_reg_waddr     (wb_cp0_cp0Waddr),
      .cp0_reg_wdata     (wb_cp0_cp0Wdata),

      .cp0_reg_raddr     (ex_cp0_cp0Raddr),
      .cp0_reg_rdata     (cp0_ex_cp0Rdata),

      .status_reg        (cp0_mem_status),
      .cause_reg         (cp0_mem_cause ),
      .epc_reg           (cp0_mem_epc   ),
      .count_reg         (),
      .compare_reg       (),
      .config_reg        (),
      .prid_reg          (),

      .int_i             (int_vec),
      .timer_int_o       (tim_int)

  );

// bus interface 

  wb_interface dbus_interface(
        .clk                  (clk),
        .rst                  (rst),

        // from ctrl
        .stall_ctrl           (ctrl_dbus_stallCtrl),
        .flush_i              (ctrl_x_flush       ),

        // CPU interface
        .cpu_ce_i             (mem_dbus_ce),
        .cpu_data_i           (mem_dbus_data),
        .cpu_addr_i           (mem_dbus_addr),
        .cpu_we_i             (mem_dbus_we),
        .cpu_sel_i            (mem_dbus_byteSel),
        .cpu_data_o           (dbus_mem_data),

        // Wishbone interface
        .wb_data_i            (dbus_data_i ),
        .wb_ack_i             (dbus_ack_i  ),
        .wb_addr_o            (dbus_addr_o ),
        .wb_data_o            (dbus_data_o ),
        .wb_we_o              (dbus_we_o   ),
        .wb_sel_o             (dbus_sel_o  ),
        .wb_stb_o             (dbus_stb_o  ),
        .wb_cyc_o             (dbus_cyc_o  ),

        .stall_req            (mem_ctrl_stallReq)
  );

    
  wb_interface ibus_interface(
        .clk                  (clk),
        .rst                  (rst),

        .stall_ctrl           (ctrl_ibus_stallCtrl),
        .flush_i              (ctrl_x_flush       ),

        .cpu_ce_i             (if_ibus_ce),
        .cpu_data_i           (32'h00000000),
        .cpu_addr_i           (if_ibus_addr),
        .cpu_we_i             (1'b0),
        .cpu_sel_i            (4'b1111),
        .cpu_data_o           (ibus_ifid_data),

        .wb_data_i            (ibus_data_i ),
        .wb_ack_i             (ibus_ack_i  ),
        .wb_addr_o            (ibus_addr_o ),
        .wb_data_o            (ibus_data_o ),
        .wb_we_o              (ibus_we_o   ),
        .wb_sel_o             (ibus_sel_o  ),
        .wb_stb_o             (ibus_stb_o  ),
        .wb_cyc_o             (ibus_cyc_o  ),

        .stall_req            (if_ctrl_stallReq)
  );


// memory access stage data out assignment
assign mem_memwb_hi        = mem_x_hi;       
assign mem_memwb_lo        = mem_x_lo;       
assign mem_memwb_hiloWe    = mem_x_hiloWe;   
assign df_memex_hi         = mem_x_hi;
assign df_memex_lo         = mem_x_lo;
assign df_memex_hiloWe     = mem_x_hiloWe;
// write back stage data out assignment
assign wb_hilo_hi          = wb_x_hi;
assign wb_hilo_lo          = wb_x_lo;
assign wb_hilo_hiloWe      = wb_x_hiloWe;
assign df_wbex_hi          = wb_x_hi;
assign df_wbex_lo          = wb_x_lo;
assign df_wbex_hiloWe      = wb_x_hiloWe;
// execute stage data out assigment
assign ex_exmem_gprWe      = ex_x_gprWe;
assign ex_exmem_targetGpr  = ex_x_targetGpr;
assign ex_exmem_exeResult  = ex_x_exeResult;
assign df_exid_gprWe       = ex_x_gprWe;      
assign df_exid_targetGpr   = ex_x_targetGpr;  
assign df_exid_exeResult   = ex_x_exeResult;  
// mem stage data out assigment
assign mem_memwb_gprWe     = mem_x_gprWe;
assign mem_memwb_targetGpr = mem_x_targetGpr;
assign mem_memwb_exeResult = mem_x_exeResult;
assign df_memid_gprWe      = mem_x_gprWe;      
assign df_memid_targetGpr  = mem_x_targetGpr;  
assign df_memid_exeResult  = mem_x_exeResult;  

assign ctrl_if_stallCtrl    = ctrl_x_stallCtrl;
assign ctrl_ifid_stallCtrl  = ctrl_x_stallCtrl;
assign ctrl_idex_stallCtrl  = ctrl_x_stallCtrl;
assign ctrl_exmem_stallCtrl = ctrl_x_stallCtrl;
assign ctrl_memwb_stallCtrl = ctrl_x_stallCtrl;
assign ctrl_ibus_stallCtrl  = ctrl_x_stallCtrl;
assign ctrl_dbus_stallCtrl  = ctrl_x_stallCtrl;

assign memwb_llbit_llbitWe    = memwb_x_llbitWe;
assign memwb_llbit_llbitValue = memwb_x_llbitValue;
assign memwb_mem_llbitWe      = memwb_x_llbitWe;
assign memwb_mem_llbitValue   = memwb_x_llbitValue;

assign ex_exmem_instType    = ex_x_instType; 
assign ex_id_instType       = ex_x_instType; 

assign wb_cp0_cp0We         = wb_x_cp0We;
assign wb_cp0_cp0Waddr      = wb_x_cp0Waddr;
assign wb_cp0_cp0Wdata      = wb_x_cp0Wdata;
assign wb_ex_cp0We          = wb_x_cp0We;
assign wb_ex_cp0Waddr       = wb_x_cp0Waddr;
assign wb_ex_cp0Wdata       = wb_x_cp0Wdata;
assign wb_mem_cp0We         = wb_x_cp0We;
assign wb_mem_cp0Waddr      = wb_x_cp0Waddr;
assign wb_mem_cp0Wdata      = wb_x_cp0Wdata;

assign mem_memwb_cp0We      = mem_x_cp0We;
assign mem_memwb_cp0Waddr   = mem_x_cp0Waddr;
assign mem_memwb_cp0Wdata   = mem_x_cp0Wdata;
assign mem_ex_cp0We         = mem_x_cp0We;
assign mem_ex_cp0Waddr      = mem_x_cp0Waddr;
assign mem_ex_cp0Wdata      = mem_x_cp0Wdata;

assign mem_ctrl_exceptType  = mem_x_exceptType;
assign mem_cp0_exceptType   = mem_x_exceptType;
endmodule
