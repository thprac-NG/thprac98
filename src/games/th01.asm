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
                                          ; otherwise INT18h/04h won't work
                                          ; properly.

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
        ; push    TEXT_WHITE 10 10 [cs:heartbeat_value]
        ; call    print_ch
        ; add     sp, 8
        ; inc     [cs:heartbeat_value]
        ; cmp     [cs:heartbeat_value], 3Ah
        ; jne     @@L1
        ; mov     [cs:heartbeat_value], 30h
@@L1:

        call    maintain_bs_menu_ui
        push    ax
        call    inject
        add     sp, 2

@@return:
        pop     ds
        ret
endp my_int8

masm
comment $
NOPs:
1byte: 90 (nop)
2bytes: 89 xx (mov r16, r16). C0 (ax), DB (bx), C9 (cx), D2 (dx),
                              E4 (sp), ED (bp), F6 (si), FF (di)
3bytes: 8D xx 00 (lea r16, [r16 + 00h]). 5F (bx), 6E (bp), 74 (si), 7D (di)
4bytes: 8D xx 00 00 (lea r16, [r16 + 0000h]). 9F (bx), AE (bp), B4 (si), BD (di)

Note that these addresses are from Ghidra, having a 1000:0 offset.

Check https://github.com/H-J-Granger/ReC98/commit/d159a9960ae4d52c4c2bb6d91fcd5046f6dad4e5
for the discompiled version of these modifications.
F1: Invincibile (
  1B50:29A9 | 7E 2F -> 89 DB
  1B50:29BA | C4 1E FC 47 26 FE 4F 15 -> C6 06 AF 00 00 E9 A2 FD
)
F2: Inf. Lives (
  1B50:29BE | 26 FE 4F 15 FF 0E E0 00 -> 8D B4 00 00 8D BD 00 00
  2967:198B | 9A 95 08 58 28 -> 90 8D B4 00 00
                       ^^ ^^  Note that this is an absolute call, the segment
                              address might differ.
)
F3: Inf. Bombs (
  2967:08B3 | 40 -> 90
  2967:08AB | FE 0E 92 00 -> 8D 9F 00 00
)
F4: Inf. Card Combo
F5: Inf. Item Combo
F6: Everlasting BGM
$
ideal

; Due to the language restriction, the array members are represented as offsets
; of an array stored elsewhere.
struc inject_code_t
        ; The filename to be injected
        filename        dw ?
        seg             dw ?
        off             dw ?
        len             dw 0
        original_mem    dw ?
        patched_mem     dw ?
        ; This array controls the condition of performing the patch.
        ; If variable_mem[i] == 1, then original_mem[i] can vary.
        ; If variable_mem[i] == 0, then original_mem[i] must match.
        ; If variable_mem[0] == -1, then the whole memory must match.
        variable_mem    dw offset must_match
ends inject_code_t

reiiden_exe     db "REIIDEN.EXE", 0
must_match      db -1

invincible_part1_org    db 07Eh, 02Fh
invincible_part1_pat    db 089h, 0DBh
invincible_part1        inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 0B50h, \
        off = 29A9h, \
        len = 2, \
        original_mem = offset invincible_part1_org, \
        patched_mem = offset invincible_part1_pat \
}
invincible_part2_org    db 0C4h, 01Eh, 0FCh, 047h, 026h, 0FEh, 04Fh, 015h
invincible_part2_pat    db 0C6h, 006h, 0AFh, 000h, 000h, 0E9h, 0A2h, 0FDh
invincible_part2        inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 0B50h, \
        off = 29BAh, \
        len = 8, \
        original_mem = offset invincible_part2_org, \
        patched_mem = offset invincible_part2_pat \
}
inf_lives_part1_org     db 026h, 0FEh, 04Fh, 015h, 0FFh, 00Eh, 0E0h, 000h
inf_lives_part1_pat     db 08Dh, 0B4h, 000h, 000h, 08Dh, 0BDh, 000h, 000h
inf_lives_part1         inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 0B50h, \
        off = 29BEh, \
        len = 8, \
        original_mem = offset inf_lives_part1_org, \
        patched_mem = offset inf_lives_part1_pat \
}
inf_lives_part2_org     db 09Ah, 095h, 008h, 058h, 028h
inf_lives_part2_pat     db 090h, 08Dh, 0B4h, 000h, 000h
inf_lives_part2_var     db 0, 0, 0, 1, 1
inf_lives_part2         inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 1967h, \
        off = 198Bh, \
        len = 5, \
        original_mem = offset inf_lives_part2_org, \
        patched_mem = offset inf_lives_part2_pat, \
        variable_mem = offset inf_lives_part2_var, \
}
inf_bombs_part1_org     db 040h
inf_bombs_part1_pat     db 090h
inf_bombs_part1         inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 1967h, \
        off = 08B3h, \
        len = 1, \
        original_mem = offset inf_bombs_part1_org, \
        patched_mem = offset inf_bombs_part1_pat \
}
inf_bombs_part2_org     db 0FEh, 00Eh, 092h, 000h
inf_bombs_part2_pat     db 08Dh, 09Fh, 000h, 000h
inf_bombs_part2         inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 1967h, \
        off = 08ABh, \
        len = 4, \
        original_mem = offset inf_bombs_part2_org, \
        patched_mem = offset inf_bombs_part2_pat, \
}

inject_failed   db 0

proc inject near
arg @@updated:word
        mov     ax, [@@updated]
        or      al, [inject_failed]
        test    ax, ax
        jz      @@return

        mov     bx, [word ptr indos_flag_addr]
        mov     es, [word ptr indos_flag_addr + 2]
        mov     al, [byte ptr es:bx]
        mov     bx, [word ptr critical_error_flag_addr]
        mov     es, [word ptr critical_error_flag_addr + 2]
        or      al, [byte ptr es:bx]
        test    al, al
        jz      @@L1
        mov     [inject_failed], 1
        jmp     @@return
@@L1:

        mov     ah, 62h
        int     21h
        mov     ax, bx  ; Stored PSP segment
        mov     es, bx
        mov     es, [es:2Ch]  ; Get environment segment
        mov     bx, 0
@@L2:
        mov     cx, [word ptr es:bx]
        inc     bx
        test    cx, cx
        jnz     @@L2
        add     bx, 3  ; Get the full path of the executing program
        mov     dh, 0
        mov     dl, bl
        dec     dl
@@L3:
        mov     cl, [byte ptr es:bx]
        cmp     cl, 5Ch
        jne     @@L4
        mov     dl, bl
@@L4:
        inc     bx
        cmp     cl, 0
        jne     @@L3
        inc     dx  ; the filename of the executing program
        push    ax
        push    dx es (offset reiiden_exe) ds
        call    strcmp_ignore_case
        add     sp, 8
        pop     es  ; the PSP segment
        cmp     ax, 1
        jne     @@return

        mov     al, [byte ptr fx_state + 1]
        push    es
        push    es ax (offset invincible_part1)
        call    inject_one
        add     sp, 6
        pop     es
        mov     al, [byte ptr fx_state + 1]
        push    es
        push    es ax (offset invincible_part2)
        call    inject_one
        add     sp, 6
        pop     es

        mov     al, [byte ptr fx_state + 3]
        push    es
        push    es ax (offset inf_lives_part1)
        call    inject_one
        add     sp, 6
        pop     es
        mov     al, [byte ptr fx_state + 3]
        push    es
        push    es ax (offset inf_lives_part2)
        call    inject_one
        add     sp, 6
        pop     es

        mov     al, [byte ptr fx_state + 5]
        push    es
        push    es ax (offset inf_bombs_part1)
        call    inject_one
        add     sp, 6
        pop     es
        mov     al, [byte ptr fx_state + 5]
        push    es
        push    es ax (offset inf_bombs_part2)
        call    inject_one
        add     sp, 6
        pop     es

@@return:
        ret
endp inject

; Argument 1: offset to the inject_code_t structure
; Argument 2: 1 means to inject, 0 means to restore
; Argument 3: the PSP segment of the current program
proc inject_one near
arg @@inject_code:word, @@flag:word, @@psp_seg:word
local @@must_match:byte
        push    si di
        mov     si, [@@inject_code]
        add     [@@psp_seg], 10h  ; Add the size of PSP (100h)
        mov     ax, [@@psp_seg]
        add     ax, [word ptr ds:si + inject_code_t.seg]
        mov     es, ax
        mov     si, [@@inject_code]
        test    [@@flag], 1
        jz      @@restore
        ; Inject the code.
        mov     dl, [byte ptr ds:si + inject_code_t.variable_mem]
        mov     [@@must_match], dl
        mov     ax, 0
@@L1:
        mov     di, [word ptr ds:si + inject_code_t.off]
        add     di, ax
        mov     cl, [byte ptr es:di]
        mov     bx, [word ptr ds:si + inject_code_t.original_mem]
        add     bx, ax
        cmp     cl, [byte ptr ds:bx]
        je      @@L2
        cmp     [@@must_match], -1
        je      @@return
        mov     bx, [word ptr ds:si + inject_code_t.variable_mem]
        add     bx, ax
        cmp     [byte ptr ds:bx], 1
        jne     @@return
@@L2:
        inc     ax
        cmp     ax, [word ptr ds:si + inject_code_t.len]
        jne     @@L1
        mov     di, [word ptr ds:si + inject_code_t.off]
        mov     bx, [word ptr ds:si + inject_code_t.original_mem]
        push    es
        push    [word ptr ds:si + inject_code_t.len] bx ds di es
        call    memory_copy
        add     sp, 10
        pop     es
        mov     bx, [word ptr ds:si + inject_code_t.patched_mem]
        push    es
        push    [word ptr ds:si + inject_code_t.len] di es bx ds
        call    memory_copy
        add     sp, 10
        pop     es
        jmp     @@return
@@restore:
        ; Restore the code.
        mov     ax, 0
@@L3:
        mov     di, [word ptr ds:si + inject_code_t.off]
        add     di, ax
        mov     bx, [word ptr ds:si + inject_code_t.patched_mem]
        add     bx, ax
        mov     cl, [byte ptr es:di]
        cmp     cl, [byte ptr ds:bx]
        jne     @@return
        inc     ax
        cmp     ax, [word ptr ds:si + inject_code_t.len]
        jne     @@L3
        mov     bx, [word ptr ds:si + inject_code_t.original_mem]
        mov     di, [word ptr ds:si + inject_code_t.off]
        push    [word ptr ds:si + inject_code_t.len] di es bx ds
        call    memory_copy
        add     sp, 10
@@return:
        pop     di si
        ret
endp inject_one

; Returns: Whether the FX status has been updated.
proc maintain_bs_menu_ui near
local @@update:word, @@prev_bs_state:byte, @@prev_fx_state:byte:FX_COUNT, \
@@return_val:word
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
        mov     [@@return_val], 0
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
        mov     [@@return_val], 1
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
        mov     ax, [@@return_val]
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

; Argument 1,2: segment, offset of ASCIIZ string1
; Argument 3,4: segment, offset of ASCIIZ string2
; Returns (in ax): Whether the two string is equal (case is ignored)
proc strcmp_ignore_case near
arg @@str1_seg:word, @@str1_off:word, @@str2_seg:word, @@str2_off:word
        mov     ax, 1
@@L1:
        mov     es, [@@str1_seg]
        mov     bx, [@@str1_off]
        mov     cl, [byte ptr es:bx]
        mov     dl, cl
        sub     dl, 'a'
        cmp     dl, 25
        ja      @@L2
        sub     cl, 'a' - 'A'
@@L2:
        mov     es, [@@str2_seg]
        mov     bx, [@@str2_off]
        mov     bl, [byte ptr es:bx]
        mov     dl, bl
        sub     dl, 'a'
        cmp     dl, 25
        ja      @@L3
        sub     bl, 'a' - 'A'
@@L3:
        cmp     bl, cl
        je      @@L4
        mov     ax, 0
        jmp     @@return
@@L4:
        inc     [@@str1_off]
        inc     [@@str2_off]
        cmp     bl, 0
        jne     @@L1
@@return:
        ret
endp strcmp_ignore_case

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