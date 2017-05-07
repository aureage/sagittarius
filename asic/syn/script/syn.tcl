#////////////////////////////////////////////////////////////////////////////////////
#//
#//  File Name   : dc_script
#//  Author      : ejune.lee
#//  Function    : Script for Design Compiler
#//  Description : 
#//  Usage       : 1)make sure the lib in correct dir
#//                2)if you have the file synopsys_dc.setup,
#//                  set synopsys_dc_setup_file 1, if not
#//                  set synopsys_dc_setup_file 0
#//                3)change Step3 Variables to your current design
#//                  especially "top module name, clock name,reset name,
#//                  all files name, and period"
#//                4)typing dc_shell -t -f prj_syn.tcl |tee -i run.log 
#//                  (just execute run_dc in workdir in aureage platform)
#//
#//  Create Date : 2014/04/08
#//  Version     : 1.0
#//
#////////////////////////////////////////////////////////////////////////////////////
sh mkdir /tmp/synopsys_cache
set cache_read  /tmp/synopsys_cache
set cache_write /tmp/synopsys_cache
set synopsys_dc_setup_file 0
#--------------------------------------------------------------------
# Step1:
#        Setting up path and library
#        If you have edited the synopsys_dc.setup,
#        than this step can be skiped
#---------------------------------------------------------------------
set rtl_path             /home/ejune/aureage/soc/sagittarius/hardware/src_rtl
set smic40g_lib_path     /home/ejune/aureage/libs/smic40g
set synopsys_dw_lib_path /eda_tools/synopsys/syn201206sp2/libraries/syn
set std_lib_path         $smic40g_lib_path/StandardCell/SCC40NLL_HDC40_HVT_V0p1/liberty/1.1v/
set symbol_lib_path      $smic40g_lib_path/StandardCell/SCC40NLL_HDC40_HVT_V0.1/SCC40NLL_HDC40_HVT_V0p1/symbol/
set io_lib_path          $smic40g_lib_path/IO/SP40NLLD2RNP_OV3_V0p4a/syn/3p3v


set std_lib    $std_lib_path/scc40nll_hdc40_hvt_tt_v1p1_25c_basic.db 
set io_lib     $io_lib_path/SP40NLLD2RNP_OV3_V0p3_tt_V1p10_25C.db
set symbol_lib $symbol_lib_path/scc40nll_hdc40_hvt.sdb
#set mem_lib


#if{$synopsys_dc_setup_file ==0}{
  set search_path [list $synopsys_dw_lib_path \
                        $smic40g_lib_path \
                        $rtl_path ]
  set target_library $std_lib
#  set target_library "typical.db"
#  set synthetic_library "dw_foundation.sldb standard.sldb"
#  set link_library " * $target_library $synthetic_library"
  set link_library " * $target_library"
  set symbol_library "$symbol_lib"
#}


#--------------------------------------------------------------------
# Step2:
#       Compile Switches 
#---------------------------------------------------------------------
#### if inout used, tri net will be used
#set verilogout_no_tri {true}
#set test_default_scan_style multiplexed_flip_flop
# set_scan_configuration -style multiplexed_flip_flop
#set hdlin_check_no_latch "true"
#set hdlin_merge_nested_conditional_statements "true"


#--------------------------------------------------------------------
# Step3:
#       Define Variables
#---------------------------------------------------------------------
set active_design "openmips_top";
#source files.tcl
set clock_name "clk"
set reset_name "rst"
## Desire Clock Period =1000/Frequency
## dot "." is needed or else any data less than 1 is 0
#set clk_period 50.0
### Uncertainty of clock
#set clk_uncertainty_setup [expr $clk_period/200]
### Network Latency of clock
#set clk_latency [expr $clk_period/10]
### Input delay of all input ports except clock
#set input_delay [expr $clk_period/4]
### Output delay of all output ports
#set output_delay [expr $clk_period/4]
### Desired area, used by set_max_area
#set area_desired 0
### Model of the intra net, used by set_wire_load_model
#set wire_load_model "smic18_wl20";
### Model of the output_load
#set output_load "typical/NAND2BX1/AN";
### Name of report dir
set syn_reports {../report};
#sh mkdir $syn_reports;

set area_report         "$syn_reports/$active_design\_area.rpt";
set cell_report         "$syn_reports/$active_design\_cell.rpt";
set power_report        "$syn_reports/$active_design\_power.rpt";
set timing_report       "$syn_reports/$active_design\_timing.rpt";
set references_report   "$syn_reports/$active_design\_references.rpt";
set constraint_report   "$syn_reports/$active_design\_constraint.rpt";
set timing_max20_report "$syn_reports/$active_design\_timing_max20.rpt";
set check_syntax_report "$syn_reports/$active_design\_check_design.rpt";

## Name of outfile dir
set syn_netlist {../generate};
#sh mkdir $syn_netlist;

set out_netlist  "$syn_netlist/$active_design.v";
set out_db       "$syn_netlist/$active_design.db";
set out_sdf      "$syn_netlist/$active_design.sdf";
set out_sdc      "$syn_netlist/$active_design.sdc";


#--------------------------------------------------------------------
# Step4:
#      Read design to DC Memory 
#---------------------------------------------------------------------
#set file_list "$SAG_PATH/hardware/src_rtl/filelist/sagittarius_syn.filelist"
#foreach active_files $file_list {read_verilog $active_files}
set rtl_files [sh cat /home/ejune/aureage/soc/sagittarius/hardware/src_rtl/filelist/sagittarius_syn.filelist]
analyze -f verilog $rtl_files
elaborate $active_design -lib work

current_design $active_design

link
#uniquify

check_design > $check_syntax_report
#if{[check_design ==0]}{
#  echo "Check Design Error!";
#  exit;
#}


#--------------------------------------------------------------------
# Step5:
#       Constraint
#---------------------------------------------------------------------
## Net Load
#set_wire_load_model -name $wire_load_model
#set_wire_load_mode  top
#set_wire_load_mode enclosed

## Set Clocks
#creat_clock             -name $clock_name -period [expr $clk_period] [get_ports $clock_name] 
#set_clock_uncertainty   -setup $clk_uncertainty_setup [get_clocks $clock_name]
#set_clock_latency       $clk_latency [get_clocks $clock_name]
#set_dont_touch_network  [get_clocks $clock_name]
#set_dont_touch_network  [get_ports  $reset_name]
#set_ideal_network       [get_ports  $reset_name]
#
#set_clock_transition  0.3 [get_clocks $clock_name]

## Drive

#set_driving_cell -lib_cell AND2HD1X -pin Z -library smic18_tt -no_design_rule \
                 [remove_from_collection $ain_ports [get_ports [list rst_n]]]
#set_driving_cell -lib_cell NAND2BX1 -pin Y [all_inputs]
#set_drive 0 [get_ports $clock_name]
#set_drive 0 [get_ports $reset_name]

## Input/Output delay
#set allin_except_CLK [remove_from_collection [all_inputs] [get_ports clk]]
#set_input_delay [expr $input_delay] -clock $clock_name $allin_except_CLK
#set_output_delay [expr $output_delay] -clock $clock_name[all_outputs]

## Output load
#set_load [load_of $output_load] [all_outputs]

## Area
# set_max_area $area_desired

## Insert buffer replace assign
#set_fix_multiple_port_nets -all -buffer_constants


#--------------------------------------------------------------------
# Step6:
#       Compile
#       compile_ultra can also be used to replace compile
#---------------------------------------------------------------------
compile -map_effort medium -boundary_optimization
#compile -map_effort medium -boundary_optimization -area_effort high
#compile -incremental_mapping

#--------------------------------------------------------------------
# Step7:
#       Reports  (Timing, Area ...)
#---------------------------------------------------------------------
#remove_unconnected_ports [get_cells -hier {*}]
#change_names -hierarchy -rules TAN_RULE

check_design > $check_syntax_report
report_area > $area_report
report_reference > $references_report
report_cell [get_cells -hier*] > $cell_report
report_power -analysis_effort high -verbose > $power_report
report_constraint -all_violators -verbose > $constaint_report
report_timing -delay max -max_paths 1 > $timing_report
report_timing -delay max -path end -max_path 80 > $timing_max20_report


#--------------------------------------------------------------------
# Step8:
#       Write Files (Netlist...)
#---------------------------------------------------------------------
change_names -rule verilog -hier
write -format verilog -hierarchy -output $out_netlist
write -format db -hierarchy -output $out_db
write_sdf $out_sdf
write_sdc $out_sdc

#remove_design -all
#exit



# saif dump
#   rtl2saif -output $CAP_PATH/hardware/asic/syn/capricorn_core_top.saif  -design capricorn_testbench
#   lib2saif -output $CAP_PATH/hardware/asic/syn/lib_fw.saif    fast_1v32c0.db




