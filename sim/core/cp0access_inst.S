   .org 0x0
   .set noat
   .set noreorder
   .set nomacro
   .global _start
_start:
   ori $1,$0,0xf
   mtc0 $1,$11,0x0  # write data into compare register
   lui $1,0x1000
   ori $1,$1,0x401
   mtc0 $1,$12,0x0  # write data into status register
   mfc0 $2,$12,0x0  # read data from status register

_loop:
   j _loop
   nop
