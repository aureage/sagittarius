
`define TB_TOP            testbench
`define SOC_TOP           `TB_TOP.i_sagittarius_top
`define CORE_TOP          `SOC_TOP.i_openmips_top
`define CORE_CP0          `CORE_TOP.i_coprocessor0

`define CORE_REG_PC       `CORE_CP0.cur_inst_addr_i[31:0]
`define CORE_REG_EPC      `CORE_CP0.epc_reg[31:0]
`define CORE_REG_STATUS   `CORE_CP0.status_reg[31:0]
`define CORE_REG_CAUSE    `CORE_CP0.cause_reg[31:0]
`define CORE_REG_COMPARE  `CORE_CP0.compare_reg[31:0]
`define CORE_REG_COUNT    `CORE_CP0.count_reg[31:0]
`define CORE_REG_CONFIG   `CORE_CP0.config_reg[31:0]
`define CORE_REG_PRID     `CORE_CP0.prid_reg[31:0]

`define cpu_clk           `CORE_TOP.clk
`define cpu_rst           `CORE_TOP.rst

`define gpr_we            `CORE_TOP.i_gpr.we
`define gpr_index         `CORE_TOP.i_gpr.waddr
`define gpr_value         `CORE_TOP.i_gpr.wdata

module core_monitor(

);

reg [31:0] cpuclk_cnt;
reg [31:0] cpuclk_cnt_r;
reg [31:0] cpuclk_cnt_rr;

reg [31:0] pc_r;
reg [31:0] epc_r;
reg [31:0] status_r;
reg [31:0] cause_r;
reg [31:0] compare_r;
reg [31:0] count_r;
reg [31:0] config_r;
reg [31:0] prid_r;

reg        gpr_we_r;
reg [4:0]  gpr_index_r;
reg [31:0] gpr_value_r;


reg [31:0] pc_rr;
reg [31:0] epc_rr;
reg [31:0] status_rr;
reg [31:0] cause_rr;
reg [31:0] compare_rr;
reg [31:0] count_rr;
reg [31:0] config_rr;
reg [31:0] prid_rr;

reg        gpr_we_rr;
reg [4:0]  gpr_index_rr;
reg [31:0] gpr_value_rr;
// cpu clock counter
initial
begin
  cpuclk_cnt[31:0] = 32'b0;
end
always@(posedge `cpu_clk)
begin
  if(!`cpu_rst)
  begin
  cpuclk_cnt[31:0] = cpuclk_cnt[31:0] + 1;
  end
end

//
integer COREMNT;

initial
begin
   prid_r     = `CORE_REG_PRID;

   pc_r       = 32'hxxxxxxxx;
   epc_r      = 32'hxxxxxxxx;
   status_r   = 32'hxxxxxxxx;
   cause_r    = 32'hxxxxxxxx;
   compare_r  = 32'hxxxxxxxx;
   count_r    = 32'hxxxxxxxx;
   config_r   = 32'hxxxxxxxx;
  
   pc_rr      = 32'hxxxxxxxx;
   epc_rr     = 32'hxxxxxxxx;
   status_rr  = 32'hxxxxxxxx;
   cause_rr   = 32'hxxxxxxxx;
   compare_rr = 32'hxxxxxxxx;
   count_rr   = 32'hxxxxxxxx;
   config_rr  = 32'hxxxxxxxx;

   COREMNT = $fopen({"./core_mnt.log"}); 
   if(COREMNT == 0)
   begin
     $display(">> Error: core_mnt.log open failed!");
     $finish;
   end
   $fwrite(COREMNT,"*********************************************************************\n");
   $fwrite(COREMNT,"*      Aureage Intelligent Microsystems' Core Monitor Logfile       *\n");
   $fwrite(COREMNT,"*********************************************************************\n");
   
end

always @(posedge `cpu_clk)
begin
   pc_r         = `CORE_REG_PC;
   epc_r        = `CORE_REG_EPC;
   status_r     = `CORE_REG_STATUS;
   cause_r      = `CORE_REG_CAUSE;
   compare_r    = `CORE_REG_COMPARE;
   count_r      = `CORE_REG_COUNT;
   config_r     = `CORE_REG_CONFIG;
   cpuclk_cnt_r = cpuclk_cnt;
   
   gpr_we_r     = `gpr_we;
   gpr_index_r  = `gpr_index;
   gpr_value_r  = `gpr_value;
end

//always @(posedge `cpu_clk)
//begin
//   pc_rr         = pc_r;
//   epc_rr        = epc_r;
//   status_rr     = status_r;
//   cause_rr      = cause_r;
//   compare_rr    = compare_r;
//   count_rr      = count_r;
//   config_rr     = config_r;
//   cpuclk_cnt_rr = cpuclk_cnt_r;
//                  
//   gpr_we_rr     = gpr_we_r;
//   gpr_index_rr  = gpr_index_r;
//   gpr_value_rr  = gpr_value_r;
//end

always @(posedge `cpu_clk or posedge `cpu_rst)
begin
  if(!`cpu_rst)
  begin
    $fwrite(COREMNT,"cyc:%5d|",cpuclk_cnt_r);
    $fwrite(COREMNT,"pc:0x%8h|",pc_r);
    $fwrite(COREMNT,"sr:0x%8h|",status_r);
    $fwrite(COREMNT,"epc:0x%8h|",epc_r);
    if(gpr_we_r)
    begin 
      $fwrite(COREMNT,"gpr%2d:0x%8h",gpr_index_r,gpr_value_r);
    end
    $fwrite(COREMNT," \n");
  end
end

endmodule
