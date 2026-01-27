ideal
model tiny, cpp  ; Set calling convention to C++-style
radix 10  ; The immediates will be recognized as decimal by default
locals  ; Enables block-scoped symbols
p386

segment cseg para public 'CODE'
org 100h
assume cs:cseg, ds:cseg

start:
jmp real_start

bs_frame1 db '+--------------+', 0
bs_frame2 db '|              |', 0
f1_text   db  'F1: Invincible', 0
f2_text   db  'F2: Inf. Lives', 0

old_int8 dd ?
cur dw 30h

proc my_int8_wrapper far
        push ax bx cx dx si di bp es ds
        assume ds:nothing
        pushf
        call [dword ptr cs:[old_int8]]
        call my_int8
        pop ds es bp di si dx cx bx ax
        iret
endp my_int8_wrapper

proc my_int8 near
        assume cs:cseg
        push ds bx
        mov bx, cs
        mov ds, bx

        ; Heartbeat on (10,10)
        push TEXT_WHITE 10 10 [cs:cur]
        call print_ch
        add sp, 8
        inc [cs:cur]
        cmp [cs:cur], 3Ah
        jne @@L1
        mov [cs:cur], 30h
@@L1:

        pop bx ds
        ret
endp my_int8

TEXT_WHITE EQU 0E1h
TEXT_GREEN EQU 81h

SCREEN_WIDTH EQU 80
SCREEN_HEIGHT EQU 25
VRAM_SEG EQU 0A000h
VRAM_ATTR_SEG EQU 0A200h

; Print an ASCIIZ string onto screen.
; Argument 1: segment of pointer to string (byte array)
; Argument 2: offset of pointer to string
; Argument 3: X coordinate of the starting point (0 ~ 79)
; Argument 4: Y coordinate (0 ~ 24)
; Argument 5: The text attribute
proc print_str near
arg str_seg:word, str_off:word, x:word, y:word, attr:word
        push si di
        mov ax, [y]
        cmp ax, SCREEN_HEIGHT
        jae @@return
        mov dx, 160
        mul dx
        mov si, ax
        mov bx, [x]  ; bx: current x
        mov di, [str_off]  ; di: current offset of the string
@@print_a_char:
        cmp bx, SCREEN_WIDTH
        jae @@return
        mov es, [str_seg]
        mov cl, [byte ptr es:di]
        cmp cl, 0
        je @@return
        mov dx, bx
        add dx, bx
        add si, dx   ; si: current offset of TRAM
        mov ax, VRAM_SEG
        mov es, ax
        mov [word ptr es:si], cx
        mov ax, VRAM_ATTR_SEG
        mov es, ax
        mov ax, [attr]
        mov [word ptr es:si], ax
        sub si, dx
        inc di
        inc bx
        jmp @@print_a_char
@@return:
        pop di si
        ret
endp print_str
; Print an ASCII character onto screen.
; Argument 1: The character code
; Argument 2: X coordinate of the starting point (0 ~ 79)
; Argument 3: Y coordinate (0 ~ 24)
; Argument 4: The text attribute
proc print_ch near
arg char:word, x:word, y:word, attr:word
        push si
        mov ax, [y]
        cmp ax, SCREEN_HEIGHT
        jae @@return
        mov dx, 160
        mul dx
        mov si, ax
        mov bx, [x]  ; bx: [x]
        cmp bx, SCREEN_WIDTH
        jae @@return
        mov cx, [char]
        add si, bx
        add si, bx  ; si: offset of TRAM
        mov ax, VRAM_SEG
        mov es, ax
        mov [es:si], cx
        mov ax, VRAM_ATTR_SEG
        mov es, ax
        mov ax, [attr]
        mov [es:si], ax
@@return:
        pop si
        ret
endp print_ch

label end_of_resident byte

real_start:
        ; push TEXT_WHITE 10 10 '0'
        ; call print_ch
        ; add sp, 8
        ; mov al, 00h
        ; mov ah, 4Ch
        ; int 21h

        mov al, 08h
        mov ah, 35h
        int 21h  ; get the old int8 vector
        mov [word ptr old_int8], bx
        mov [word ptr old_int8 + 2], es
        mov dx, offset my_int8_wrapper
        mov al, 08h
        mov ah, 25h
        int 21h  ; set the int8 vector
        pushf
        call [dword ptr cs:[old_int8]]

        mov dx, offset end_of_resident
        add dx, 15
        shr dx, 4
        mov al, 0
        mov ah, 31h
        int 21h
ends cseg
end start