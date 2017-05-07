#////////////////////////////////////////////////////////////////////////////////////
#//                                                                                //
#//                      Copyright (c) Aureage Intelligent Systems                 //
#//                              ALL RIGHTS RESERVED                               //
#//                                                                                //
#//      This software and the associated documentation are confidential and       //
#//      proprietary to Aureage and is not to be disclosed outside of Aureage      //
#//      Intelligent Systems except under a Non-Disclosure Agreement (NDA).        //
#//                                                                                //
#//      The entire notice above must be reproduced on all authorized copies.      //
#//                                                                                //
#////////////////////////////////////////////////////////////////////////////////////
#//                                                                                  
#//  File Name   : Makefile
#//  Author      : ejune.lee                                                         
#//  Function    :                                                                   
#//  Description :                                                                   
#//                                                                                  
#//  Create Date : 2015/03/19 @sec-chip
#//  Version     :                                                                   
#//                                                                                  
#////////////////////////////////////////////////////////////////////////////////////
ifndef TOOLEXT
TOOLEXT = mips-sde-elf-
endif
AS            = $(TOOLEXT)as
CC            = $(TOOLEXT)gcc
LD            = $(TOOLEXT)ld
NM            = $(TOOLEXT)nm
OBJDUMP       = $(TOOLEXT)objdump
OBJCOPY       = $(TOOLEXT)objcopy

#ifdef IPLIB
#INCL          = system.h c_define.h $(LIBNAME).h 
#OBJECTS       = crt0.o $(CASENAME).o $(LIBNAME).o
#else
#INCL          = system.h c_define.h 
#OBJECTS       = crt0.o $(CASENAME).o
#endif
export  TOOLEXT

OBJECTS = $(CASENAME).o

ASFLAGS        = -mips32
		        


# *****************
# File Dependencies
# *****************
#ifdef IPLIB
#$(LIBNAME).o     : $(INCL)
#endif
#
#$(CASENAME).o    : $(INCL) 
#crt0.o           : system.h

# ********************
# Rules of Compilation
# ********************

all: $(CASENAME).om $(CASENAME).bin $(CASENAME).asm  $(CASENAME).data

%.o: %.S
	@printf "\r\t--- Assembling $(<) ---\r\n"
#	$(AS) $< -o $@
	$(AS) $(ASFLAGS) $< -o $@

#ifdef CCASE
#%.o: %.c
#	@printf "\r\t--- Compiling $(<) ---\r\n"
#	$(CC) $(CFLAGS) $< -o $@
#endif

$(CASENAME).om: linker.ld $(OBJECTS)
	$(LD) -T linker.ld $(OBJECTS) -o $@

$(CASENAME).ihex: $(CASENAME).om
	$(OBJCOPY) -O ihex $< $@

$(CASENAME).bin: $(CASENAME).om
	$(OBJCOPY) -O binary $< $@

$(CASENAME).asm: $(CASENAME).om
	$(OBJDUMP) -D $< > $@  

$(CASENAME).data: $(CASENAME).bin
	../../../tools/Bin2Mem -f $< -o $@
	
clean:
	rm -f *.o *.om *.ihex *.bin *.asm *.data 
