// Global variable
`define RstEnable           1'b1
`define RstDisable          1'b0
`define InDelaySlot         1'b1
`define NotInDelaySlot      1'b0
`define Branch              1'b1
`define NotBranch           1'b0
`define InterruptAssert     1'b1
`define InterruptNotAssert  1'b0
`define TrapAssert          1'b1
`define TrapNotAssert       1'b0
`define True_v              1'b1
`define False_v             1'b0
`define ChipEnable          1'b1
`define ChipDisable         1'b0

`define InstTypeWidth       8
`define InstClassWidth      3

// Instruction memory (rom)
`define InstBusAddrWidth 32
`define InstBusDataWidth 32
`define InstMemNum       131071
`define InstMemNumLog2   17
`define DataMemNumLog2   17


// General Purpose register
`define GPR_AddrWidth   5
`define GPR_DataWidth   32
`define GPR_Num         32
`define RegWidth        32
`define DoubleRegWidth  64
`define RegNumLog2      5 //
`define NOPRegAddr      5'b00000// register $0
//////////////////////////////////////
// Instruction encoding
//////////////////////////////////////
// logic instruction
`define INST_AND   6'h24   //6'b100100 
`define INST_OR    6'h25   //6'b100101 
`define INST_XOR   6'h26   //6'b100110 
`define INST_NOR   6'h27   //6'b100111 
`define INST_ANDI  6'h0c   //6'b001100 
`define INST_ORI   6'h0d   //6'b001101 
`define INST_XORI  6'h0e   //6'b001110 
`define INST_LUI   6'h0f   //6'b001111 
// shift instruction                    
`define INST_SLL   6'h00   //6'b000000 
`define INST_SLLV  6'h04   //6'b000100 
`define INST_SRL   6'h02   //6'b000010 
`define INST_SRLV  6'h06   //6'b000110 
`define INST_SRA   6'h03   //6'b000011 
`define INST_SRAV  6'h07   //6'b000111 
`define INST_SYNC  6'h0f   //6'b001111 
`define INST_PREF  6'h33   //6'b110011 
// move instruction
`define INST_MOVN  6'h0b   //6'b001011
`define INST_MOVZ  6'h0a   //6'b001010
`define INST_MFHI  6'h10   //6'b010000
`define INST_MTHI  6'h11   //6'b010001
`define INST_MFLO  6'h12   //6'b010010
`define INST_MTLO  6'h13   //6'b010011
// arithmetic instruction
`define INST_SLT   6'h2a   //6'b101010 
`define INST_SLTU  6'h2b   //6'b101011
`define INST_SLTI  6'h0a   //6'b001010
`define INST_SLTIU 6'h0b   //6'b001011
`define INST_ADD   6'h20   //6'b100000
`define INST_ADDU  6'h21   //6'b100001
`define INST_SUB   6'h22   //6'b100010
`define INST_SUBU  6'h23   //6'b100011
`define INST_ADDI  6'h08   //6'b001000
`define INST_ADDIU 6'h09   //6'b001001
`define INST_CLZ   6'h20   //6'b100000
`define INST_CLO   6'h21   //6'b100001
// multiply instruction
`define INST_MULT  6'h18   //6'b011000
`define INST_MULTU 6'h19   //6'b011001
`define INST_MUL   6'h02   //6'b000010

`define INST_MADD  6'h00   //6'b000000  
`define INST_MADDU 6'h01   //6'b000001  
`define INST_MSUB  6'h04   //6'b000100  
`define INST_MSUBU 6'h05   //6'b000101  
// division instruction
`define INST_DIV   6'h1a   //6'b011010  
`define INST_DIVU  6'h1b   //6'b011011 
// jump instruction
`define INST_J      6'h02  //6'b000010  
`define INST_JAL    6'h03  //6'b000011  
`define INST_JALR   6'h09  //6'b001001  
`define INST_JR     6'h08  //6'b001000  
// branch instruction
`define INST_BEQ    6'h04  //6'b000100  
`define INST_BGTZ   6'h07  //6'b000111  
`define INST_BLEZ   6'h06  //6'b000110  
`define INST_BNE    6'h05  //6'b000101 

`define INST_BGEZ   5'h01  //5'b00001  
`define INST_BGEZAL 5'h11  //5'b10001  
`define INST_BLTZ   5'h00  //5'b00000  
`define INST_BLTZAL 5'h10  //5'b10000  


`define INST_LB     6'h20   //6'b100000
`define INST_LBU    6'h24   //6'b100100
`define INST_LH     6'h21   //6'b100001
`define INST_LHU    6'h25   //6'b100101
`define INST_LL     6'h30   //6'b110000
`define INST_LW     6'h23   //6'b100011
`define INST_LWL    6'h22   //6'b100010
`define INST_LWR    6'h26   //6'b100110

`define INST_SB     6'h28   //6'b101000
`define INST_SC     6'h38   //6'b111000
`define INST_SH     6'h29   //6'b101001
`define INST_SW     6'h2b   //6'b101011
`define INST_SWL    6'h2a   //6'b101010
`define INST_SWR    6'h2e   //6'b101110

`define INST_MFC0   5'h00
`define INST_MTC0   5'h04
// exception instructions

`define INST_TEQ    6'h34   //6'b110100
`define INST_TGE    6'h30   //6'b110000
`define INST_TGEU   6'h31   //6'b110001
`define INST_TLT    6'h32   //6'b110010
`define INST_TLTU   6'h33   //6'b110011
`define INST_TNE    6'h36   //6'b110110
   
`define INST_TEQI   5'h0c   //5'b01100
`define INST_TGEI   5'h08   //5'b01000
`define INST_TGEIU  5'h09   //5'b01001
`define INST_TLTI   5'h0a   //5'b01010
`define INST_TLTIU  5'h0b   //5'b01011
`define INST_TNEI   5'h0e   //5'b01110

`define INST_SYSCALL 6'h0c  //6'b001100

//`define INST_ERET 32'b0100 0010 0000 0000 0000 0000 0001 1000
//`define INST_ERET 32'h42000018
`define INST_ERET 6'h18




// nop instruction
`define INST_NOP    6'h0   //6'b000000  
`define INST_SSNOP  32'h00000040
//`define INST_SSNOP  32'b00000000000000000000000001000000

`define SPECIAL_INST  6'h00  //6'b000000
`define REGIMM_INST   6'h01  //6'b000001
`define SPECIAL2_INST 6'h1c  //6'b011100
`define COP0_INST     6'h10  //6'b010000
/////////////////////////////////////////
// Instruction type 
/////////////////////////////////////////
`define INST_T_NOP     8'h00   // 8'b00000000  
// logic instructions
`define INST_T_AND     8'h24   // 8'b00100100  
`define INST_T_OR      8'h25   // 8'b00100101  
`define INST_T_XOR     8'h26   // 8'b00100110  
`define INST_T_NOR     8'h27   // 8'b00100111  
`define INST_T_ANDI    8'h59   // 8'b01011001  
`define INST_T_ORI     8'h5a   // 8'b01011010  
`define INST_T_XORI    8'h5b   // 8'b01011011  
`define INST_T_LUI     8'h5c   // 8'b01011100  
// shift instructions                                               
`define INST_T_SLL     8'h7c   // 8'b01111100  
`define INST_T_SLLV    8'h04   // 8'b00000100  
`define INST_T_SRL     8'h02   // 8'b00000010  
`define INST_T_SRLV    8'h06   // 8'b00000110  
`define INST_T_SRA     8'h03   // 8'b00000011  
`define INST_T_SRAV    8'h07   // 8'b00000111  
// move instructions
`define INST_T_MOVN    8'h0b   //8'b00001011
`define INST_T_MOVZ    8'h0a   //8'b00001010
`define INST_T_MFHI    8'h10   //8'b00010000
`define INST_T_MTHI    8'h11   //8'b00010001
`define INST_T_MFLO    8'h12   //8'b00010010
`define INST_T_MTLO    8'h13   //8'b00010011
// arithmetic instructions
`define INST_T_SLT     8'h2a   // 8'b00101010
`define INST_T_SLTU    8'h2b   // 8'b00101011
`define INST_T_SLTI    8'h57   // 8'b01010111
`define INST_T_SLTIU   8'h58   // 8'b01011000
`define INST_T_ADD     8'h20   // 8'b00100000
`define INST_T_ADDU    8'h21   // 8'b00100001
`define INST_T_SUB     8'h22   // 8'b00100010
`define INST_T_SUBU    8'h23   // 8'b00100011
`define INST_T_ADDI    8'h55   // 8'b01010101
`define INST_T_ADDIU   8'h56   // 8'b01010110
`define INST_T_CLZ     8'hb0   // 8'b10110000
`define INST_T_CLO     8'hb1   // 8'b10110001

`define INST_T_MULT    8'h18   // 8'b00011000
`define INST_T_MULTU   8'h19   // 8'b00011001
`define INST_T_MUL     8'ha9   // 8'b10101001

`define INST_T_MADD    8'ha6   // 8'b10100110
`define INST_T_MADDU   8'ha8   // 8'b10101000
`define INST_T_MSUB    8'haa   // 8'b10101010
`define INST_T_MSUBU   8'hab   // 8'b10101011

`define INST_T_DIV     8'h1a   // 8'b00011010
`define INST_T_DIVU    8'h1b   // 8'b00011011
// jump branch instructions
`define INST_T_J       8'h4f   //8'b01001111
`define INST_T_JAL     8'h50   //8'b01010000
`define INST_T_JALR    8'h09   //8'b00001001
`define INST_T_JR      8'h08   //8'b00001000
`define INST_T_BEQ     8'h51   //8'b01010001
`define INST_T_BGEZ    8'h41   //8'b01000001
`define INST_T_BGEZAL  8'h4b   //8'b01001011
`define INST_T_BGTZ    8'h54   //8'b01010100
`define INST_T_BLEZ    8'h53   //8'b01010011
`define INST_T_BLTZ    8'h40   //8'b01000000
`define INST_T_BLTZAL  8'h4a   //8'b01001010
`define INST_T_BNE     8'h52   //8'b01010010
// load store instructions
`define INST_T_LB      8'he0   //8'b11100000
`define INST_T_LBU     8'he4   //8'b11100100
`define INST_T_LH      8'he1   //8'b11100001
`define INST_T_LHU     8'he5   //8'b11100101
`define INST_T_LL      8'hf0   //8'b11110000
`define INST_T_LW      8'he3   //8'b11100011
`define INST_T_LWL     8'he2   //8'b11100010
`define INST_T_LWR     8'he6   //8'b11100110
`define INST_T_PREF    8'hf3   //8'b11110011
`define INST_T_SB      8'he8   //8'b11101000
`define INST_T_SC      8'hf8   //8'b11111000
`define INST_T_SH      8'he9   //8'b11101001
`define INST_T_SW      8'heb   //8'b11101011
`define INST_T_SWL     8'hea   //8'b11101010
`define INST_T_SWR     8'hee   //8'b11101110

`define INST_T_SYNC    8'h0f   //8'b00001111
// coprocessor0 access instructions
`define INST_T_MFC0    8'h5d   //8'b01011101
`define INST_T_MTC0    8'h60   //8'b01100000
// exception instructions


`define INST_T_TEQ      8'h34    //8'b00110100
`define INST_T_TEQI     8'h48    //8'b01001000
`define INST_T_TGE      8'h30    //8'b00110000
`define INST_T_TGEI     8'h44    //8'b01000100
`define INST_T_TGEIU    8'h45    //8'b01000101
`define INST_T_TGEU     8'h31    //8'b00110001
`define INST_T_TLT      8'h32    //8'b00110010
`define INST_T_TLTI     8'h46    //8'b01000110
`define INST_T_TLTIU    8'h47    //8'b01000111
`define INST_T_TLTU     8'h33    //8'b00110011
`define INST_T_TNE      8'h36    //8'b00110110
`define INST_T_TNEI     8'h49    //8'b01001001

`define INST_T_SYSCALL  8'h0c    //8'b00001100
`define INST_T_ERET     8'h6b    //8'b01101011


/////////////////////////////////////////
// instruction class
/////////////////////////////////////////
`define INST_C_NOP          3'b000

`define INST_C_LOGIC        3'b001
`define INST_C_SHIFT        3'b010
`define INST_C_MOVE         3'b011
`define INST_C_ARITH        3'b100
`define INST_C_MUL          3'b101

`define INST_C_JUMPBRANCH   3'b110
`define INST_C_LOADSTORE    3'b111


/////////////////////////////////////////
// Coprocessor 0 register address 
/////////////////////////////////////////
`define CP0_REG_COUNT      5'b01001
`define CP0_REG_COMPARE    5'b01011
`define CP0_REG_STATUS     5'b01100
`define CP0_REG_CAUSE      5'b01101
`define CP0_REG_EPC        5'b01110
`define CP0_REG_PrId       5'b01111
`define CP0_REG_CONFIG     5'b10000

