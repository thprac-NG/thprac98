; The linkable assembly source file for the non-TSR users of this folder
ideal
model small, cpp
radix 10
locals
stack 100h
p386

codeseg
        public to_hex_digit
        public sprint_byte
        public sprint_word
        public sprint_dword
        public strcmp_ignore_case
        public print_ch
        public print_str
        public memory_copy
        public print_frame

        public _to_hex_digit
        public _sprint_byte
        public _sprint_word
        public _sprint_dword
        public _strcmp_ignore_case
        public _print_ch
        public _print_str
        public _memory_copy
        public _print_frame

proc _to_hex_digit near
        jmp     to_hex_digit
endp _to_hex_digit
proc _sprint_byte near
        jmp     sprint_byte
endp _sprint_byte
proc _sprint_word near
        jmp     sprint_word
endp _sprint_word
proc _sprint_dword near
        jmp     sprint_dword
endp _sprint_dword
proc _strcmp_ignore_case near
        jmp     strcmp_ignore_case
endp _strcmp_ignore_case
proc _print_ch near
        jmp     print_ch
endp _print_ch
proc _print_str near
        jmp     print_str
endp _print_str
proc _memory_copy near
        jmp     memory_copy
endp _memory_copy
proc _print_frame near
        jmp     print_frame
endp _print_frame

include "..\src\asmutils\sprnthex.asm"
include "..\src\asmutils\strcmpnc.asm"
include "..\src\asmutils\tramprnt.asm"
include "..\src\asmutils\memcpy.asm"
include "..\src\asmutils\prntfrme.asm"

end
