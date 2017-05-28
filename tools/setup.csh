# Build up the environment of EDA tools.
#source /eda_tools/aureage_ic.csh
# Build up the environment of openrisc toolchain.
source /eda_tools/toolchain/mips/openmips.csh
source /eda_tools/synopsys_local.csh
# Build up the shotcut of directories.


#setenv SAG_PATH /data_repo/AUReage/SoC/sagittarius
setenv SAG_PATH   `pwd | perl -pe "s/sagittarius.*/sagittarius/"`

alias  sag        'cd $SAG_PATH'
alias  sag_rtl    'cd $SAG_PATH/rtl'
alias  sag_diag   'cd $SAG_PATH/sim'
alias  sag_asic   'cd $SAG_PATH/asic'
alias  sag_fpga   'cd $SAG_PATH/fpga'
alias  sag_tools  'cd $SAG_PATH/tools'

alias  asim       'cd $SAG_PATH/asic/sim_func'
alias  asimg      'cd $SAG_PATH/asic/sim_gate'
alias  alint      'cd $SAG_PATH/asic/lint'
alias  asyn       'cd $SAG_PATH/asic/syn'

alias  rtop       'cd $SAG_PATH/rtl/top'
alias  rcore      'cd $SAG_PATH/rtl/core'
alias  rgpio      'cd $SAG_PATH/rtl/gpio'
alias  ruart      'cd $SAG_PATH/rtl/uart'
alias  rsdr       'cd $SAG_PATH/rtl/sdram'
alias  rflash     'cd $SAG_PATH/rtl/flash'
alias  rwb        'cd $SAG_PATH/rtl/wb'

alias  dcore      'cd $SAG_PATH/sim/core'
alias  dgpio      'cd $SAG_PATH/sim/gpio'
alias  duart      'cd $SAG_PATH/sim/uart'
alias  dsdr       'cd $SAG_PATH/sim/sdram'
alias  dflash     'cd $SAG_PATH/sim/flash'
alias  dwb        'cd $SAG_PATH/sim/wb'
alias  dtb        'cd $SAG_PATH/sim/tb'
alias  alib       'cd $SAG_PATH/sim/libs/alib'
alias  clib       'cd $SAG_PATH/sim/libs/clib'
alias  vlib       'cd $SAG_PATH/sim/libs/vlib'


alias  run        '$SAG_PATH/tools/run_sim'
