ideal
model tiny, cpp  ; Set calling convention to C++-style
radix 10  ; The immediates will be recognized as decimal by default
locals  ; Enables block-scoped symbols
p386

segment cseg para public 'CODE'
org 100h
        assume  cs:cseg, ds:cseg

start:
        jmp     real_start

BS_MENU_WIDTH   EQU 16
BS_MENU_HEIGHT  EQU 5
FX_COUNT        EQU (BS_MENU_HEIGHT - 2)  ; Should be no greater than 6,
                                          ; otherwise INT18h/04h won't properly.

bs_frame1       db '+--------------+', 0
bs_frame2       db '|              |', 0
f1_text         db  'F1: Invincible', 0
f2_text         db  'F2: Inf. Lives', 0
f3_text         db  'F3: Inf. Bombs', 0
fx_text         dw offset f1_text, offset f2_text, offset f3_text

bs_covered_tvram        dw (BS_MENU_HEIGHT * BS_MENU_WIDTH) dup (?)
bs_covered_tvram_attr   dw (BS_MENU_HEIGHT * BS_MENU_WIDTH) dup (?)

; The high byte represents "down", and the low byte alternates each time pressed
bs_state        dw 0
fx_state        dw FX_COUNT dup(0)

old_int8        dd ?
heartbeat_value dw 30h

; These are byte ptrs, and need to check if is both cleared before any DOS call
; in a TSR.
indos_flag_addr                 dd ?
critical_error_flag_addr        dd ?

proc my_int8_wrapper far
        push    ax bx cx dx si di bp es ds
        assume  ds:nothing
        pushf
        call    [dword ptr cs:[old_int8]]
        call    my_int8
        pop     ds es bp di si dx cx bx ax
        iret
endp my_int8_wrapper

proc my_int8 near
        assume  cs:cseg
        push    ds
        mov     bx, cs
        mov     ds, bx

        ; Heartbeat on (10,10)
        push    TEXT_WHITE 10 10 [cs:heartbeat_value]
        call    print_ch
        add     sp, 8
        inc     [cs:heartbeat_value]
        cmp     [cs:heartbeat_value], 3Ah
        jne     @@L1
        mov     [cs:heartbeat_value], 30h
@@L1:

        call    maintain_bs_menu_ui

@@return:
        pop     ds
        ret
endp my_int8

proc maintain_bs_menu_ui near
local @@update:word, @@prev_bs_state:byte, @@prev_fx_state:byte:FX_COUNT
        mov     al, [byte ptr bs_state + 1]
        mov     [@@prev_bs_state], al
        mov     dx, 0
@@L8:
        mov     bx, offset fx_state + 1
        add     bx, dx
        add     bx, dx
        mov     al, [byte ptr ds:bx]
        lea     bx, [@@prev_fx_state]
        add     bx, dx
        mov     [byte ptr ss:bx], al
        inc     dx
        cmp     dx, FX_COUNT
        jne     @@L8

        mov     [@@update], 0
        mov     ax, 0401h
        int     18h
        shr     ah, 6
        and     ah, 1
        cmp     [byte ptr bs_state], ah
        jge     @@L2
        xor     [byte ptr bs_state + 1], 1  ; [bs_state] == 0, prev == 1, flip
        mov     [@@update], 1
@@L2:
        mov     [byte ptr bs_state], ah
        cmp     [byte ptr bs_state + 1], 1
        jne     @@skip_fx_checking  ; if the BS menu is hidden, ignore FX inputs
        mov     ax, 040Ch
        int     18h
        shr     ah, 2
        mov     bx, offset fx_state
        mov     dx, 0
@@check_single_fx:
        mov     ch, ah
        and     ch, 1
        cmp     [byte ptr bx], ch
        jge     @@L3
        xor     [byte ptr bx + 1], 1  ; current state == 0, prev == 1, flip
        mov     [@@update], 1
@@L3:
        mov     [byte ptr bx], ch
        shr     ah, 1
        add     bx, 2
        inc     dx
        cmp     dx, FX_COUNT
        jne     @@check_single_fx
@@skip_fx_checking:

        ; Update the BackSpace Menu
        cmp     [@@update], 1
        jne     @@end_of_bs_menu_update
        mov     al, [@@prev_bs_state]
        cmp     al, [byte ptr bs_state + 1]
        jl      @@show_bs_menu
        jg      @@restore_bs_covered
        ; @@update has changed, but bs_state doesn't change. Thus, this is a
        ; FX update.
        jmp     @@show_bs_menu_without_storing
@@show_bs_menu:
        ; Store the covered TVRAM space
        mov     ax, TVRAM_SEG
        mov     es, ax
        mov     ax, 0
        mov     bx, offset bs_covered_tvram
@@L4:
        push    ax bx es
        push    (2 * BS_MENU_WIDTH) bx ds ax es
        call    memory_copy
        add     sp, 10
        pop     es bx ax
        add     ax, 0A0h
        add     bx, (2 * BS_MENU_WIDTH)
        cmp     ax, (0A0h * BS_MENU_HEIGHT)
        jne     @@L4
        mov     ax, TVRAM_ATTR_SEG
        mov     es, ax
        mov     ax, 0
        mov     bx, offset bs_covered_tvram_attr
@@L5:
        push    ax bx es
        push    (2 * BS_MENU_WIDTH) bx ds ax es
        call    memory_copy
        add     sp, 10
        pop     es bx ax
        add     ax, 0A0h
        add     bx, (2 * BS_MENU_WIDTH)
        cmp     ax, (0A0h * BS_MENU_HEIGHT)
        jne     @@L5
@@show_bs_menu_without_storing:
        ; Show the BS menu
        push    TEXT_WHITE 0 0 offset bs_frame1 ds
        call    print_str
        add     sp, 10
        push    TEXT_WHITE (BS_MENU_HEIGHT - 1) 0 offset bs_frame1 ds
        call    print_str
        add     sp, 10
        mov     dx, 1
@@L6:
        push    dx
        push    TEXT_WHITE dx 0 offset bs_frame2 ds
        call    print_str
        add     sp, 10
        pop     dx
        inc     dx
        cmp     dx, (BS_MENU_HEIGHT - 1)
        jne     @@L6
        mov     dx, 1
@@L7:
        mov     bx, offset fx_state - 1
        add     bx, dx
        add     bx, dx
        test    [byte ptr es:bx], 1
        jz      @@L9
        mov     cx, TEXT_GREEN
        jmp     @@L10
@@L9:
        mov     cx, TEXT_WHITE
@@L10:
        mov     bx, offset fx_text - 2
        add     bx, dx
        add     bx, dx
        push    dx
        push    cx dx 1 [word ptr bx] ds
        call    print_str
        add     sp, 10
        pop     dx
        inc     dx
        cmp     dx, FX_COUNT + 1
        jne     @@L7
        jmp     @@end_of_bs_menu_update
@@restore_bs_covered:
        ; Restore the covered TVRAM space
        mov     ax, TVRAM_SEG
        mov     es, ax
        mov     ax, 0
        mov     bx, offset bs_covered_tvram
@@L11:
        push    ax bx es
        push    (2 * BS_MENU_WIDTH) ax es bx ds
        call    memory_copy
        add     sp, 10
        pop     es bx ax
        add     ax, 0A0h
        add     bx, (2 * BS_MENU_WIDTH)
        cmp     ax, (0A0h * BS_MENU_HEIGHT)
        jne     @@L11
        mov     ax, TVRAM_ATTR_SEG
        mov     es, ax
        mov     ax, 0
        mov     bx, offset bs_covered_tvram_attr
@@L12:
        push    ax bx es
        push    (2 * BS_MENU_WIDTH) ax es bx ds
        call    memory_copy
        add     sp, 10
        pop     es bx ax
        add     ax, 0A0h
        add     bx, (2 * BS_MENU_WIDTH)
        cmp     ax, (0A0h * BS_MENU_HEIGHT)
        jne     @@L12
@@end_of_bs_menu_update:
        ret
endp maintain_bs_menu_ui

TEXT_WHITE      EQU 0E1h
TEXT_GREEN      EQU 81h

SCREEN_WIDTH    EQU 80
SCREEN_HEIGHT   EQU 25
TVRAM_SEG       EQU 0A000h
TVRAM_ATTR_SEG  EQU 0A200h

; Print an ASCIIZ string onto screen.
; Argument 1: segment of pointer to string (byte array)
; Argument 2: offset of pointer to string
; Argument 3: X coordinate of the starting point (0 ~ 79)
; Argument 4: Y coordinate (0 ~ 24)
; Argument 5: The text attribute
proc print_str near
arg @@str_seg:word, @@str_off:word, @@x:word, @@y:word, @@attr:word
        push    si di
        mov     ax, [@@y]
        cmp     ax, SCREEN_HEIGHT
        jae     @@return
        mov     dx, 160
        mul     dx
        mov     si, ax
        mov     bx, [@@x]  ; bx: current x
        mov     di, [@@str_off]  ; di: current offset of the string
@@print_a_char:
        cmp     bx, SCREEN_WIDTH
        jae     @@return
        mov     es, [@@str_seg]
        mov     ch, 0
        mov     cl, [byte ptr es:di]
        cmp     cl, 0
        je      @@return
        mov     dx, bx
        add     dx, bx
        add     si, dx   ; si: current offset of TVRAM
        mov     ax, TVRAM_SEG
        mov     es, ax
        mov     [word ptr es:si], cx
        mov     ax, TVRAM_ATTR_SEG
        mov     es, ax
        mov     ax, [@@attr]
        mov     [word ptr es:si], ax
        sub     si, dx
        inc     di
        inc     bx
        jmp     @@print_a_char
@@return:
        pop     di si
        ret
endp print_str

; Print an ASCII character onto screen.
; Argument 1: The character code
; Argument 2: X coordinate of the starting point (0 ~ 79)
; Argument 3: Y coordinate (0 ~ 24)
; Argument 4: The text attribute
proc print_ch near
arg @@char:word, @@x:word, @@y:word, @@attr:word
        push    si
        mov     ax, [@@y]
        cmp     ax, SCREEN_HEIGHT
        jae     @@return
        mov     dx, 160
        mul     dx
        mov     si, ax
        mov     bx, [@@x]  ; bx: [x]
        cmp     bx, SCREEN_WIDTH
        jae     @@return
        mov     cx, [@@char]
        add     si, bx
        add     si, bx  ; si: offset of TVRAM
        mov     ax, TVRAM_SEG
        mov     es, ax
        mov     [es:si], cx
        mov     ax, TVRAM_ATTR_SEG
        mov     es, ax
        mov     ax, [@@attr]
        mov     [es:si], ax
@@return:
        pop     si
        ret
endp print_ch

; Argument 1,2: segment, offset of the source memory
; Argument 3,4: segment, offset of the destination memory
; Argument 5: The bytes to be copied
proc memory_copy near
arg @@src_seg:word, @@src_off:word, @@dest_seg:word, @@dest_off:word, \
@@size:word
        mov     ax, 0
@@move_a_byte:
        cmp     ax, [@@size]
        je      @@return
        mov     bx, [@@src_seg]
        mov     es, bx
        mov     bx, [@@src_off]
        mov     ch, [byte ptr es:bx]
        mov     bx, [@@dest_seg]
        mov     es, bx
        mov     bx, [@@dest_off]
        mov     [byte ptr es:bx], ch
        inc     [@@dest_off]
        inc     [@@src_off]
        inc     ax
        jmp     @@move_a_byte
@@return:
        ret
endp memory_copy


label end_of_resident byte

dos_version_low_message         db 'The version of DOS is too low. DOS 3+ is ',\
                                   'required.$'
cannot_get_critical_error_flag  db 'Failed to get the address of Critical ', \
                                   'Error Flag.$'

real_start:
        ; Check DOS version
        mov     ah, 30h
        int     21h
        cmp     al, 3
        jge     @@using_dos_3_plus
        mov     dx, offset dos_version_low_message
        mov     ah, 09h
        int     21h
        mov     al, 1
        jmp     @@return_with_error_code
@@using_dos_3_plus:

        ; Set up the two flags for DOS calls in TSR
        mov     ah, 34h
        int     21h
        mov     [word ptr indos_flag_addr], bx
        mov     [word ptr indos_flag_addr + 2], es
        push    ds
        mov     ax, 5D06h
        int     21h
        mov     ax, ds
        mov     es, ax
        pop     ds
        jnc     @@successfully_get_critical_error_flag_addr
        mov     dx, offset cannot_get_critical_error_flag
        mov     ah, 09h
        int     21h
        mov     al, 2
        jmp     @@return_with_error_code
@@successfully_get_critical_error_flag_addr:
        mov     [word ptr critical_error_flag_addr], si
        mov     [word ptr critical_error_flag_addr + 2], es

        ; Initialize the keyboard BIOS
        mov     ah, 03h
        int     18h

        ; Hook INT8
        mov     ax, 3508h
        int     21h  ; get the old INT8 vector
        mov     [word ptr old_int8], bx
        mov     [word ptr old_int8 + 2], es
        mov     dx, offset my_int8_wrapper
        mov     ax, 2508h
        int     21h  ; set the INT8 vector
        pushf
        call    [dword ptr cs:[old_int8]]  ; call old_int8 once to initalize

        ; Terminate and stay resident
        mov     dx, offset end_of_resident
        add     dx, 15
        shr     dx, 4
        mov     al, 0
        mov     ah, 31h
        int     21h

@@return_with_error_code:
        mov     ah, 4Ch
        int     21h
ends cseg
end start