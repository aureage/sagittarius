
`timescale 1ns/1ps
module testbench();

  reg     CLOCK_50;
  reg     rst;
  
       
  initial begin
    CLOCK_50 = 1'b0;
    forever #10 CLOCK_50 = ~CLOCK_50;
  end
      
  initial begin
    rst = `RstEnable;
    #195 rst= `RstDisable;
  end
       
//  initial
//  begin
//    $dumpfile("sagittarius.vcd");
//    $dumpvars;
//    #1000;
//    $stop;
//  end

  initial
  begin
    $display("time:%d", $time);
    $fsdbDumpfile("sagittarius.fsdb");
    $fsdbDumpon;
    $fsdbDumpvars("+mda");
    #40000;
    $fsdbDumpoff;
    $display("time:%d", $time);
    $finish;
  end 

//always@(posedge CLOCK_50)
//begin
//    //$dumpMem(testbench.i_sagittarius_top.i_inst_rom.inst_mem);
//    //$fsdbDumpMDA(testbench.i_sagittarius_top.i_inst_rom.inst_mem,);
//    //$fsdbDumpMDA(32, testbench.i_sagittarius_top.i_inst_rom.inst_mem);
//    //$fsdbDumpMDA(testbench.i_sagittarius_top.i_openmips_top.i_gpr );
//    $fsdbDumpMDA(5);
//end

  sagittarius_top  i_sagittarius_top(
		.clk(CLOCK_50),
		.rst(rst)	
	);


  core_monitor i_core_monitor( );

endmodule
