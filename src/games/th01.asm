ideal
model tiny, cpp
radix 10
locals
p386

segment cseg para private 'CODE' USE16
org 100h
        assume  cs:cseg, ds:cseg

start:
        jmp     real_start

ENV_SEG_OFF     EQU 2Ch

BS_MENU_WIDTH   EQU 21
BS_MENU_HEIGHT  EQU 8
FX_COUNT        EQU (BS_MENU_HEIGHT - 2)  ; Should be no greater than 6,
                                          ; otherwise INT18h/04h won't work
                                          ; properly.

f1_text         db 'F1: Invincible', 0
f2_text         db 'F2: Inf. Lives', 0
f3_text         db 'F3: Inf. Bombs', 0
f4_text         db 'F4: Time Lock', 0
f5_text         db 'F5: Inf. Card Combo', 0
f6_text         db 'F6: Inf. Item Combo', 0
fx_text         dw offset f1_text, offset f2_text, offset f3_text, \
                   offset f4_text, offset f5_text, offset f6_text

bs_covered_tram         dw (BS_MENU_HEIGHT * BS_MENU_WIDTH) dup (?)
bs_covered_tram_attr    dw (BS_MENU_HEIGHT * BS_MENU_WIDTH) dup (?)

; The high byte represents "down", and the low byte alternates each time pressed
bs_state        dw 0
fx_state        dw FX_COUNT dup(0)
prac_menu_state dw 0
key_z_up_once   db 0
arrow_state     db 0    ; stored in bit 2,3,4,5 for up, left, right, down
space_state     db 0    ; stored in bit 4

; These are byte ptrs, and need to check if is both cleared before any DOS call
; in a TSR.
indos_flag_addr                 dd ?
critical_error_flag_addr        dd ?

cur_psp         dw ?
temp_proc       dd ?

include 'interupt.asm'  ; Hooked Interrupts

; --------------------------------------------------------------------------
; Function: after_load_exe
; Description: Handles procedures after loading an executable. Get called
;              `WAIT_LOAD_TIME`*10 ms after every INT 21h/4Bh call.
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc after_load_exe near
        call    store_covered_tram
        call    show_bs_menu
        call    inject
        ret
endp

; --------------------------------------------------------------------------
; Function: on_tick
; Description: Maintains the UI of the practice menu and backspace menu, and
;              injects the code. Get called every `MY_INT8_CALL_INTERVAL`*10 ms.
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc on_tick near
local @@return_val:byte
        ; Maintain the backspace menu. The return value of `maintain_bs_menu_ui`
        ; indicates whether the status of the FX has been updated, and we are
        ; passing the value to `inject`.
        call    maintain_bs_menu_ui
        mov     [@@return_val], al
        call    inject
        call    maintain_prac_menu_ui
        movzx   ax, [@@return_val]
        ret
endp on_tick

; ===========================================================================
;                                INJECT CODE
; ===========================================================================

; NOPs:
; 1byte: 90 (nop)
; 2bytes: 89 xx (mov r16, r16). C0 (ax), DB (bx), C9 (cx), D2 (dx),
;                               E4 (sp), ED (bp), F6 (si), FF (di)
; 3bytes: 8D xx 00 (lea r16, [r16 + 00h]). 5F (bx), 6E (bp), 74 (si), 7D (di)
; 4bytes: 8D xx 00 00 (lea r16, [r16 + 0000h]). 9F (bx), AE (bp),
;                                               B4 (si), BD (di)
;
; REIIDEN.EXE modifications
; ==============================================================
;
; For the discompiled version of the Fx modifications, check:
; F1-F3: https://github.com/H-J-Granger/ReC98/commit/d159a9960ae4d52c4c2bb6d91fcd5046f6dad4e5
; F4: https://github.com/H-J-Granger/ReC98/commit/c2e20cc6a5d7b27e71ac219433e2eb4285b69adc
; F5-F6: https://github.com/H-J-Granger/ReC98/commit/d420132646f2fc895b7be87642c7489760dbfd8b
;
; F1: Invincibile {
;   0B50:29A9 | 7E 2F -> 89 DB
;   0B50:29BA | C4 1E FC 47 26 FE 4F 15 -> C6 06 AF 00 00 E9 A2 FD
; }
; F2: Inf. Lives {
;   0B50:29BE | 26 FE 4F 15 FF 0E E0 00 -> 8D B4 00 00 8D BD 00 00
;   1967:198B | 9A 95 08 58 28 -> 90 8D B4 00 00
;             |          ^^ ^^ (*1)
; }
; F3: Inf. Bombs {
;   1967:08B3 | 40 -> 90
;   1967:08AB | FE 0E 92 00 -> 8D 9F 00 00
; }
; F4: Lock Time {
;   1924:0154 | 83 2E 0C 54 02 -> 8D 9F 00 00 90
; }
; F5: Inf. Card Combo {
;   0B50:12EE | C7 06 E4 00 00 00 -> 89 D2 8D 9F 00 00
; }
; F6: Inf. Item Combo {
;   17CA:07BD | 26 C7 47 49 00 00 -> 8D 74 00 8D 7D 00
; }
; F7: Everlasting BGM
;
; -----------------------
; (*1) This is an absolute call, the segment address might differ.

reiiden_exe     db "REIIDEN.EXE", 0
op_exe          db "OP.EXE", 0

include "..\src\inject.asm"

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
time_lock_org           db 083h, 02Eh, 00Ch, 054h, 002h
time_lock_pat           db 08Dh, 09Fh, 000h, 000h, 090h
time_lock               inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 1924h, \
        off = 0154h, \
        len = 5, \
        original_mem = offset time_lock_org, \
        patched_mem = offset time_lock_pat, \
}
inf_card_combo_org      db 0C7h, 006h, 0E4h, 000h, 000h, 000h
inf_card_combo_pat      db 089h, 0D2h, 08Dh, 09Fh, 000h, 000h
inf_card_combo          inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 0B50h, \
        off = 12EEh, \
        len = 6, \
        original_mem = offset inf_card_combo_org, \
        patched_mem = offset inf_card_combo_pat, \
}
inf_item_combo_org      db 026h, 0C7h, 047h, 049h, 000h, 000h
inf_item_combo_pat      db 08Dh, 074h, 000h, 08Dh, 07Dh, 000h
inf_item_combo          inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 17CAh, \
        off = 07BDh, \
        len = 6, \
        original_mem = offset inf_item_combo_org, \
        patched_mem = offset inf_item_combo_pat, \
}

; stage_num_animate (restore the menu after "STAGE XX" animation): {
;   0B50:0775 | 1E 68 59 01 9A 7A 62 00 10 83 C4 0E ->
;             |                      ^^ ^^ (*1)
;             | 9A yy yy xx xx 8D 9F 00 00 83 C4 0A
; }, where "xxxx" is cseg, and "yyyy" is (offset my_0b50_0775).
; Original assembly:
;   0B50:0775 | 1E                push    DS
;   0B50:0776 | 68 59 01          push    159h    ; offset of the string "\x1B*"
;   0B50:0779 | 9A 7A 62 00 10    callf   printf
;   0B50:077E | 83 C4 0E          add     sp, 0Eh
; Modified assembly:
;   0B50:0775 | 9A yy yy xx xx    callf   my_0b50_0775
;   0B50:077A | 8D 9F 00 00       lea     bx, [bx + 0000h]  ; effectively nop
;   0B50:077E | 83 C4 0A          add     sp, 0Ah
; Check https://github.com/H-J-Granger/ReC98/blob/d892535e723b3691612363d1bbdbd2a54f43fb43/th01/main_01.cpp#L314
; for the C version of the original code.
;
; harry_up_anmiate (restore the menu after "HARRY UP" animation): {
;   1924:0364 | 9A 6A 0C 00 00 -> 9A yy yy xx xx
;             |          ^^ ^^ (*1)
; }, where "xxxx" is cseg, and "yyyy" is (offset my_1924_0364).
; Original assembly: call text_clear (provided by master.lib)
; Modified assembly: call my_1924_0364
;
; -----------------------
; (*1) This is an absolute call, the segment address might differ.

stage_num_animate_org   db 01Eh, 068h, 059h, 001h, 09Ah, 07Ah, 062h, 000h, \
                           010h, 083h, 0C4h, 00Eh
stage_num_animate_pat   db 09Ah, 000h, 000h, 000h, 000h, 08Dh, 09Fh, 000h, \
                           000h, 083h, 0C4h, 00Ah
stage_num_animate_var   db 7 dup(0), 1, 1, 3 dup(0)
stage_num_animate       inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 0B50h, \
        off = 0775h, \
        len = 12, \
        original_mem = offset stage_num_animate_org, \
        patched_mem = offset stage_num_animate_pat, \
        variable_mem = offset stage_num_animate_var, \
}
harry_up_animate_org    db 09Ah, 06Ah, 00Ch, 000h, 000h
harry_up_animate_pat    db 09Ah, 000h, 000h, 000h, 000h
harry_up_animate_var    db 0, 0, 0, 1, 1
harry_up_animate        inject_code_t { \
        filename = offset reiiden_exe, \
        seg = 1924h, \
        off = 0364h, \
        len = 5, \
        original_mem = offset harry_up_animate_org, \
        patched_mem = offset harry_up_animate_pat, \
        variable_mem = offset harry_up_animate_var, \
}

; --------------------------------------------------------------------------
; Function: my_0b50_0775
; Description: (See the comment above)
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc my_0b50_0775 far
        assume  ds:nothing
        push    ax
        mov     ax, [cs:cur_psp]
        add     ax, 10h
        mov     [word ptr cs:temp_proc], 627Ah
        mov     [word ptr cs:temp_proc + 2], ax
        push    ds 159h
        call    [dword ptr cs:temp_proc]
        add     sp, 4
        mov     ah, [cs:int2f_mux_id]
        mov     al, 12h
        int     2Fh
        pop     ax
        assume  ds:cseg
        ret
endp my_0b50_0775

; --------------------------------------------------------------------------
; Function: my_1924_0364
; Description: (See the comment above)
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc my_1924_0364 far
        assume  ds:nothing
        push    ax
        mov     ax, [cs:cur_psp]
        add     ax, 10h
        mov     [word ptr cs:temp_proc], 0C6Ah
        mov     [word ptr cs:temp_proc + 2], ax
        call    [dword ptr cs:temp_proc]
        mov     ah, [cs:int2f_mux_id]
        mov     al, 12h
        int     2Fh
        pop     ax
        assume  ds:cseg
        ret
endp my_1924_0364

; OP.EXE modifications
; ==============================================================
;
; practise_menu_part1 {
;   0A1C:0612 | 9A 0C 00 00 00 -> 9A yy yy xx xx
;             |          ^^ ^^ (*1)
; }, where "xxxx" is cseg, and "yyyy" is
; (offset hooked_resident_create_and_stuff_set).
; Original assembly: call resident_create_and_stuff_set
; Modified assembly: call hooked_resident_create_and_stuff_set
; Check https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/op_01.cpp#L343-L349
; for the C version of the original code.
;
; practise_menu_part2 {
;   0A1C:0664 | 26 C6 47 14 00 26 C7 47 3F 00 00 A0 93 00 04 02 26 88 47 15 ->
;             | 8D AE 00 00 8D B4 00 00 8D BD 00 00 8D AE 00 00 8D B4 00 00
; }
; Original assembly: (es:bx has been set to the address of `resident`)
;   0A1C:0664 | 26 C6 47 14 00          mov     [byte ptr es:bx +
;             |                                  resdient_t.route], ROUTE_MAKAI
;   0A1C:0669 | 26 C7 47 3F 00 00       mov     [word ptr es:bx +
;             |                                  resident_t.stage_id], 0000h
;   0A1C:066F | A0 93 00                mov     al, [ds:opts + cfg_options_t.
;             |                                      credit_lives_extra]
;   0A1C:0672 | 04 02                   add     al, 02h
;   0A1C:0674 | 26 88 47 15             mov     [byte ptr es:bx +
;             |                                  route_t.rem_lives], al
; Modified assembly: (effectively nop)
;   0A1C:0664 | 8D AE 00 00             lea     bp, [bp + 0000h]
;   0A1C:0668 | 8D B4 00 00             lea     si, [si + 0000h]
;   0A1C:066C | 8D BD 00 00             lea     di, [di + 0000h]
;   0A1C:0670 | 8D AE 00 00             lea     bp, [bp + 0000h]
;   0A1C:0674 | 8D B4 00 00             lea     si, [si + 0000h]
; Check https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/op_01.cpp#L378-L380
; for the C version of the original code.

practise_menu_part1_org db 09Ah, 00Ch, 000h, 000h, 000h
practise_menu_part1_pat db 09Ah
                        dw offset cseg:hooked_resident_create_and_stuff_set
                        db 000h, 000h
practise_menu_part1_var db 0, 0, 0, 1, 1
practise_menu_part1     inject_code_t {                         \
        filename        = offset op_exe,                        \
        seg             = 0A1Ch,                                \
        off             = 0612h,                                \
        len             = 5,                                    \
        original_mem    = offset practise_menu_part1_org,       \
        patched_mem     = offset practise_menu_part1_pat,       \
        variable_mem    = offset practise_menu_part1_var,       \
}
practise_menu_part2_org db 026h, 0C6h, 047h, 014h, 000h, 026h, 0C7h, 047h, \
                           03Fh, 000h, 000h, 0A0h, 093h, 000h, 004h, 002h, \
                           026h, 088h, 047h, 015h
practise_menu_part2_pat db 08Dh, 0AEh, 000h, 000h, 08Dh, 0B4h, 000h, 000h, \
                           08Dh, 0BDh, 000h, 000h, 08Dh, 0AEh, 000h, 000h, \
                           08Dh, 0B4h, 000h, 000h
practise_menu_part2     inject_code_t {                         \
        filename        = offset op_exe,                        \
        seg             = 0A1Ch,                                \
        off             = 0664h,                                \
        len             = 20,                                   \
        original_mem    = offset practise_menu_part2_org,       \
        patched_mem     = offset practise_menu_part2_pat,       \
}

; The segment and offset of the variable `resident` (of type resident_t far)
; defined in
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/core/resstuff.cpp#L11 .
RESSTUFF_CPP_RESIDENT_SEG       EQU 1229h
RESSTUFF_CPP_RESIDENT_OFF       EQU 1C56h

; The offset of the variable `opts` (of type cfg_options_t far) defined in
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/op_01.cpp#L67-L72 .
; (Its segment is the same as `resident`)
OP_01_CPP_OPTS_OFF              EQU 0090h

SCENE_COUNT             EQU 4
STAGES_PER_SCENE        EQU 5

; For the C version of these structures, see
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/resident.hpp#L8-L72 .

enum bgm_mode_t \
        BGM_MODE_OFF, BGM_MODE_MDRV2, BGM_MODE_COUNT
enum route_t                                    \
        ROUTE_MAKAI, ROUTE_JIGOKU, ROUTE_COUNT, \
        route_t_FORCE_INT16 = 7FFFh
enum end_sequence_t \
        ES_NONE, ES_MAKAI, ES_JIGOKU
enum debug_mode_t                               \
        DM_OFF = 0, DM_TEST = 1, DM_FULL = 3,   \
        debug_mode_t_FORCE_INT16 = 7FFFh

struc resident_t
        id                      db 14 dup (?)   ; sizeof(RES_ID)
                                                ; (i.e. "ReiidenConfig")
        rank                    db ?
        bgm_mode                bgm_mode_t ?
        rem_bombs               db ?
        credit_lives_extra      db ?            ; Add 2 for the actual
                                                ; number of lives
        end_flag                end_sequence_t ?
        unused_1                db ?
        route                   db ?            ; actual type: route_t
        rem_lives               db ?
        snd_need_init           db ?            ; actual type: bool
        unused_2                db ?
        debug_mode              db ?            ; actual type: debug_mode_t
        pellet_speed            dw ?            ; pre-multiplied by 40
        rand                    dd ?
        score                   dd ?
        continues_total         dd ?
        continues_per_scene     dw SCENE_COUNT dup (?)
        bonus_per_stage         dd (STAGES_PER_SCENE - 1) dup (?)
                                                ; of the current scene, without
                                                ; the boss stage
        stage_id                dw ?
        hiscore                 dd ?
        score_highest           dd ?            ; among all continues
        point_value             dw ?
ends resident_t

; For the C version of the structure, see
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/formats/cfg.hpp#L7-L12 .
struc cfg_options_t
        rank                    db ?
        bgm_mode                bgm_mode_t ?
        credit_bombs            db ?
        credit_lives_extra      db ?    ; Add 2 for the actual number of lives
ends cfg_options_t

; --------------------------------------------------------------------------
; Function: hooked_resident_create_and_stuff_set
; Description: (See the comment above)
; Input: (See the code in ReC98)
; Output: Nothing
; --------------------------------------------------------------------------
proc hooked_resident_create_and_stuff_set far
arg @@rank:word, @@bgm_mode:word, @@rem_bombs:word, @@credit_lives_extra:word, \
    @@rand:dword
local @@route:byte, @@saved_df:byte
        assume  ds:nothing
        ; Push all the registers that may be modified by the near procedures.
        pushad
        push    ds
        pushfd

        push    [dword ptr @@rand] [@@credit_lives_extra] [@@rem_bombs]
        push    [@@bgm_mode] [@@rank]
        call    [dword ptr cs:practise_menu_part1_org + 1]
        add     sp, 0Ch

        ; Meet the assumptions of the .COM procedures
        mov     ax, cs
        mov     ds, ax
        cld

        call    show_practise_menu

        ; Calculate selected route
        mov     bx, 0
        mov     ax, [word ptr section_slider.value]
        test    ax, ax
        jz      @@skip_route_checking
        inc     ax
        and     ax, 1
        mov     bx, ax
@@skip_route_checking:
        mov     [@@route], bl

        ; Set es:bx to variable `resident`
        mov     ah, 62h
        int     21h
        lea     ax, [bx + 10h + RESSTUFF_CPP_RESIDENT_SEG]
        mov     es, ax
        les     bx, [dword ptr es:RESSTUFF_CPP_RESIDENT_OFF]

        cmp     [word ptr cs:playing_mode_slider.value], 0
        je      @@original_mode
        mov     al, [@@route]
        mov     [byte ptr es:bx + resident_t.route], al
        mov     al, [real_stage]
        dec     al
        mov     [byte ptr es:bx + resident_t.stage_id], al
        mov     al, [byte ptr life_slider.value]
        mov     [byte ptr es:bx + resident_t.rem_lives], al
        mov     al, [byte ptr bomb_slider.value]
        mov     [byte ptr es:bx + resident_t.rem_bombs], al
        jmp     @@end_of_resident_field_setting
@@original_mode:
        ; Simulate the original behaviour
        mov     [byte ptr es:bx + resident_t.route], ROUTE_MAKAI
        mov     [word ptr es:bx + resident_t.stage_id], 0
        mov     ax, [@@credit_lives_extra]
        add     al, 2
        mov     [byte ptr es:bx + resident_t.rem_lives], al
@@end_of_resident_field_setting:

        popfd
        pop     ds
        popad
        ret
endp hooked_resident_create_and_stuff_set

inject_failed   db 0

; --------------------------------------------------------------------------
; Function: inject
; Description: Check the filename of the current program, and inject the
;              code if needed.
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc inject near
arg @@updated:word
local @@saved_psp:word, @@saved_filename_ptr:dword
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
        jz      @@save_to_inject
        mov     [inject_failed], 1
        jmp     @@return
@@save_to_inject:

        mov     ah, 62h
        int     21h
        mov     [@@saved_psp], bx  ; Stored PSP segment
        mov     [cs:cur_psp], bx
        mov     es, bx
        mov     es, [es:2Ch]  ; Get environment segment
        xor     di, di
@@find_2_continuous_zero_loop:
        mov     cx, [word ptr es:di]
        inc     di
        test    cx, cx
        jnz     @@find_2_continuous_zero_loop
        ; Now, ES:DI is pointing to the full path of the executing program
        add     di, 3
        lea     dx, [di - 1]    ; DX: last encountered 3C
@@scan_for_backslash_loop:
        mov     cl, [byte ptr es:di]
        cmp     cl, '\'
        jne     @@not_backslash
        mov     dx, di
@@not_backslash:
        inc     di
        test    cl, cl
        jnz     @@scan_for_backslash_loop
        inc     dx  ; the filename of the executing program
        mov     [word ptr @@saved_filename_ptr], dx
        mov     [word ptr @@saved_filename_ptr + 2], es
        push    es dx ds (offset reiiden_exe)
        call    strcmp_ignore_case
        add     sp, 8
        test    ax, ax
        jnz     @@skip_reiiden_exe_patches

        movzx   ax, [byte ptr fx_state + 1]
        push    [word ptr @@saved_psp] ax (offset invincible_part1)
        call    inject_one
        add     sp, 6
        movzx   ax, [byte ptr fx_state + 1]
        push    [word ptr @@saved_psp] ax (offset invincible_part2)
        call    inject_one
        add     sp, 6

        movzx   ax, [byte ptr fx_state + 3]
        push    [word ptr @@saved_psp] ax (offset inf_lives_part1)
        call    inject_one
        add     sp, 6
        movzx   ax, [byte ptr fx_state + 3]
        push    [word ptr @@saved_psp] ax (offset inf_lives_part2)
        call    inject_one
        add     sp, 6

        movzx   ax, [byte ptr fx_state + 5]
        push    [word ptr @@saved_psp] ax (offset inf_bombs_part1)
        call    inject_one
        add     sp, 6
        movzx   ax, [byte ptr fx_state + 5]
        push    [word ptr @@saved_psp] ax (offset inf_bombs_part2)
        call    inject_one
        add     sp, 6

        movzx   ax, [byte ptr fx_state + 7]
        push    [word ptr @@saved_psp] ax (offset time_lock)
        call    inject_one
        add     sp, 6

        movzx   ax, [byte ptr fx_state + 9]
        push    [word ptr @@saved_psp] ax (offset inf_card_combo)
        call    inject_one
        add     sp, 6

        movzx   ax, [byte ptr fx_state + 11]
        push    [word ptr @@saved_psp] ax (offset inf_item_combo)
        call    inject_one
        add     sp, 6

        push    [word ptr @@saved_psp] 1 (offset stage_num_animate)
        call    inject_one
        add     sp, 6
        push    [word ptr @@saved_psp] 1 (offset harry_up_animate)
        call    inject_one
        add     sp, 6
@@skip_reiiden_exe_patches:

        push    [dword ptr @@saved_filename_ptr] ds (offset op_exe)
        call    strcmp_ignore_case
        add     sp, 8
        test    ax, ax
        jnz     @@skip_op_exe_patches

        push    [word ptr @@saved_psp] 1 (offset practise_menu_part1)
        call    inject_one
        add     sp, 6
        push    [word ptr @@saved_psp] 1 (offset practise_menu_part2)
        call    inject_one
        add     sp, 6
@@skip_op_exe_patches:
@@return:
        ret
endp inject

; --------------------------------------------------------------------------
; Function: maintain_bs_menu_ui
; Description: Maintain the UI of the backspace menu.
; Input: Nothing
; Output (in AX): 1 if the FX status has been updated, 0 otherwise
; --------------------------------------------------------------------------
proc maintain_bs_menu_ui near
local @@update:word, @@prev_bs_state:byte, @@prev_fx_state:byte:FX_COUNT, \
@@return_val:word
        mov     al, [byte ptr bs_state + 1]
        mov     [@@prev_bs_state], al
        xor     dx, dx
@@save_fx_state_loop:
        mov     bx, offset fx_state + 1
        add     bx, dx
        add     bx, dx
        mov     al, [byte ptr ds:bx]
        lea     bx, [@@prev_fx_state]
        add     bx, dx
        mov     [byte ptr ss:bx], al
        inc     dx
        cmp     dx, FX_COUNT
        jne     @@save_fx_state_loop

        mov     [word ptr @@update], 0
        mov     [word ptr @@return_val], 0
        mov     ax, 0401h
        int     18h
        shr     ah, 6
        and     ah, 1
        cmp     [byte ptr bs_state], ah
        jge     @@skip_flipping_bs_state
        xor     [byte ptr bs_state + 1], 1  ; [bs_state] == 0, prev == 1, flip
        mov     [@@update], 1
@@skip_flipping_bs_state:
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
        jge     @@skip_flipping_fx_state
        xor     [byte ptr bx + 1], 1  ; current state == 0, prev == 1, flip
        mov     [@@update], 1
        mov     [@@return_val], 1
@@skip_flipping_fx_state:
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
        ; Store the covered TRAM space
        call    store_covered_tram
@@show_bs_menu_without_storing:
        ; Show the BS menu
        call    show_bs_menu
        jmp     @@end_of_bs_menu_update
@@restore_bs_covered:
        call    restore_covered_tram
@@end_of_bs_menu_update:
        mov     ax, [@@return_val]
        ret
endp maintain_bs_menu_ui

; --------------------------------------------------------------------------
; Function: link_components
; Description: Link the given component list. Note that the front/tail
;              component of the window object is not modified.
; Input:  Argument 1 (word): offset to an 0FFFFh-ending array of component
;                            offsets.
; Output: Nothing
; --------------------------------------------------------------------------
proc link_components near
arg @@component_arr:word
        push    si di
        mov     bx, [@@component_arr]
@@main_loop:
        mov     si, [bx]
        mov     di, [bx + 2]
        cmp     di, 0FFFFh
        je      @@return
        mov     [word ptr si + ui_component_common.next_component_off], di
        mov     [word ptr di + ui_component_common.prev_component_off], si
        add     bx, 2
        jmp     @@main_loop
@@return:
        pop     di si
        ret
endp link_components

current_ui_boss db 0
regular_stage_linking   dw (offset stage_slider), (offset life_slider), 0FFFFh
shingyoku_linking       dw (offset stage_slider), (offset phase_slider), \
                           (offset hp_slider), (offset p2_attack), \
                           (offset skip_opening), (offset life_slider), 0FFFFh
last_phase      db 0

; --------------------------------------------------------------------------
; Function: update_prac_window_components_from_its_values
; Description: As the name suggests, the components of the practise window is
;              relavant to its value (e.g. only the game mode slider is visible
;              when its value is 'Original'). This procedure updates it.
; Warning: This function assumes the next component (if any) of the playing
;          mode slider is always the section slider, and the last component (if
;          the playing mode is 'Custom' is always the bomb slider.
; Input:  Nothing
; Output: Nothing
; --------------------------------------------------------------------------
proc update_prac_window_components_from_its_values near
        ; Dealing with the game mode slider. AL: whether the game mode is
        ; 'Original', AH: whether the window only contains the game mode slider.
        cmp     [byte ptr playing_mode_slider.value], 0
        setz    al
        cmp     [playing_mode_slider.next_component_off], 0FFFFh
        setz    ah
        cmp     ah, al
        je      @@end_of_updating_game_mode_slider  ; skip if already up to date
        ; If the playing mode is 'Original', remove all other components on the
        ; list. Note that we don't modify the data of the removed components.
        test    al, al
        jz      @@skip_unlinking_every_other_slider
        mov     [playing_mode_slider.next_component_off], 0FFFFh
        mov     [practise_menu_window.tail_component_off], \
                        (offset playing_mode_slider)
        jmp     @@end_of_updating_game_mode_slider
@@skip_unlinking_every_other_slider:
        ; If the playing mode is 'Custom', link the section slider right after
        ; the playing mode slider. Destroys AX.
        mov     [playing_mode_slider.next_component_off], \
                        (offset section_slider)
        mov     [practise_menu_window.tail_component_off], (offset bomb_slider)
@@end_of_updating_game_mode_slider:

        ; Regular stage
        cmp     [byte ptr stage_slider.value], 5
        je      @@add_bosses
        cmp     [byte ptr current_ui_boss], 0
        je      @@skip_regular_stage
        mov     [byte ptr current_ui_boss], 0
        push    (offset regular_stage_linking)
        call    link_components
        add     sp, 2
@@skip_regular_stage:
        jmp     @@skip_adding_bosses

@@add_bosses:
        ; Shingyoku
        cmp     [byte ptr section_slider.value], 0
        jne     @@skip_shingyoku
        cmp     [byte ptr current_ui_boss], 1
        je      @@skip_shingyoku_linking
        mov     [byte ptr current_ui_boss], 1
        mov     [byte ptr phase_slider.max_value], 2
        mov     [byte ptr skip_opening.value], 0
        mov     [byte ptr p2_attack.value], 0
        mov     [byte ptr p2_attack.min_value], 0
        mov     [byte ptr p2_attack.max_value], 4
        mov     [word ptr p2_cur_first_attack_str], \
                (offset p2_attack_shingyoku_1)
        push    (offset shingyoku_linking)
        call    link_components
        add     sp, 2
        mov     [byte ptr last_phase], 0
@@skip_shingyoku_linking:
        ; TODO: Maybe make the following HP handling code into a procedure?
        mov     al, [byte ptr last_phase]
        cmp     [byte ptr phase_slider.value], al
        je      @@skip_shingyoku_init_hp
        mov     al, 8
        mov     [byte ptr hp_slider.min_value], 7
        cmp     [byte ptr phase_slider.value], 2
        jne     @@skip_shingyoku_p2_hp
        mov     [byte ptr hp_slider.min_value], 1
        mov     al, 6
@@skip_shingyoku_p2_hp:
        mov     [byte ptr hp_slider.max_value], al
        mov     [byte ptr hp_slider.value], al
@@skip_shingyoku_init_hp:
        mov     al, [byte ptr phase_slider.value]
        mov     [byte ptr last_phase], al
@@skip_shingyoku:
@@skip_adding_bosses:
        ret
endp update_prac_window_components_from_its_values

; --------------------------------------------------------------------------
; Function: maintain_prac_menu_ui
; Description: As the name suggests, the components of the practise window is
;              relavant to its value (e.g. only the game mode slider is visible
;              when its value is 'Original'). This procedure updates it.
; Warning: This function assumes the next component (if any) of the playing
;          mode slider is always the section slider, and the last component (if
;          the playing mode is 'Custom' is always the bomb slider.
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc maintain_prac_menu_ui near
local @@to_redraw:byte, \
@@arrow_state_rising_edge:byte  ; bit 2,3,4,5: up, left, right, down
        cmp     [prac_menu_state], 0
        je      @@return

        mov     [byte ptr @@to_redraw], 0

        ; Check and respond to arrow key presses
        mov     ax, 0407h
        int     18h
        mov     bl, [arrow_state]
        not     bl
        and     bl, ah
        mov     [@@arrow_state_rising_edge], bl
        mov     [arrow_state], ah

        mov     si, offset practise_menu_window
        mov     di, [si + ui_window.cur_component_off]
        cmp     [byte ptr di + ui_component_common.ui_type], UI_SLIDER_NUM
        jne     @@skip_left_right
        test    [byte ptr @@arrow_state_rising_edge], 08h
        jz      @@skip_left
        push    0 di
        call    slider_change_value
        add     sp, 4
@@skip_left:
        test    [byte ptr @@arrow_state_rising_edge], 10h
        jz      @@skip_right
        push    1 di
        call    slider_change_value
        add     sp, 4
@@skip_right:
@@skip_left_right:
        test    [byte ptr @@arrow_state_rising_edge], 04h
        jz      @@skip_up
        push    0 si
        call    window_switch_cur
        add     sp, 4
@@skip_up:
        test    [byte ptr @@arrow_state_rising_edge], 20h
        jz      @@skip_down
        push    1 si
        call    window_switch_cur
        add     sp, 4
@@skip_down:
        mov     di, [si + ui_window.cur_component_off]
        test    [byte ptr @@arrow_state_rising_edge], 3Ch
        setnz   al
        mov     [@@to_redraw], al

        ; Check and respond to the Space key press
        cmp     [byte ptr di + ui_component_common.ui_type], UI_TICKBOX_NUM
        jne     @@skip_space_check
        mov     ax, 0406h
        int     18h
        mov     bl, [space_state]
        not     bl
        and     bl, ah
        mov     [space_state], ah
        test    bl, 10h
        jz      @@skip_space
        xor     [byte ptr di + ui_tickbox.value], 1
        mov     [byte ptr @@to_redraw], 1
@@skip_space:
@@skip_space_check:

        test    [byte ptr @@to_redraw], 1
        jz      @@skip_redraw
        call    update_prac_window_components_from_its_values
        push    si
        call    draw_window
        add     sp, 2
@@skip_redraw:

        ; Check and respond to 'Z' key presses (start the game). We first wait
        ; for a release of 'Z', then detect its pressing.
        mov     ax, 0405h
        int     18h
        cmp     [key_z_up_once], 0
        je      @@z_hasnt_been_released
        and     ah, 02h
        jz      @@skip_z_press
        mov     [prac_menu_state], 0
        mov     [key_z_up_once], 0
        jmp     @@end_z_press
@@z_hasnt_been_released:
        and     ah, 02h
        jnz     @@skip_set_key_z_up_once
        mov     [key_z_up_once], 1
@@skip_set_key_z_up_once:
@@end_z_press:
@@skip_z_press:

@@return:
        ret
endp maintain_prac_menu_ui

; --------------------------------------------------------------------------
; Function: store_covered_tram
; Description: Store the TRAM space (text and attribute) covered by the
;              backspace menu.
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc store_covered_tram near
        push    ds si di

        mov     ax, ds
        mov     es, ax
        mov     ax, TRAM_SEG
        mov     ds, ax
        assume  ds:nothing
        xor     si, si
        mov     di, offset bs_covered_tram
@@store_tram_loop:
        mov     cx, BS_MENU_WIDTH
        rep movsw
        add     si, 0A0h - 2 * BS_MENU_WIDTH
        cmp     si, (0A0h * BS_MENU_HEIGHT)
        jne     @@store_tram_loop
        mov     ax, TRAM_ATTR_SEG
        mov     ds, ax
        xor     si, si
        mov     di, offset bs_covered_tram_attr
@@store_tram_attr_loop:
        mov     cx, BS_MENU_WIDTH
        rep movsw
        add     si, 0A0h - 2 * BS_MENU_WIDTH
        cmp     si, (0A0h * BS_MENU_HEIGHT)
        jne     @@store_tram_attr_loop

        pop     di si ds
        assume  ds:cseg
        ret
endp store_covered_tram

; --------------------------------------------------------------------------
; Function: resstore_covered_tram
; Description: Restore the TRAM space (text and attribute) covered by the
;              backspace menu from data saved by store_covered_tram.
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc restore_covered_tram near
        push    di si

        mov     ax, TRAM_SEG
        mov     es, ax
        xor     di, di
        mov     si, (offset bs_covered_tram)
@@restore_tram_loop:
        mov     cx, BS_MENU_WIDTH
        rep movsw
        add     di, 0A0h - (2 * BS_MENU_WIDTH)
        cmp     di, (0A0h * BS_MENU_HEIGHT)
        jne     @@restore_tram_loop
        mov     ax, TRAM_ATTR_SEG
        mov     es, ax
        xor     di, di
        mov     si, offset bs_covered_tram_attr
@@restore_tram_attr_loop:
        mov     cx, BS_MENU_WIDTH
        rep movsw
        add     di, 0A0h - (2 * BS_MENU_WIDTH)
        cmp     di, (0A0h * BS_MENU_HEIGHT)
        jne     @@restore_tram_attr_loop

        pop     si di
        ret
endp restore_covered_tram

; --------------------------------------------------------------------------
; Function: resstore_covered_tram
; Description: Restore the TRAM space (text and attribute) covered by the
;              backspace menu from data saved by store_covered_tram.
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc show_bs_menu near
        cmp     [byte ptr bs_state + 1], 0
        je      @@return

        push    TEXT_WHITE BS_MENU_HEIGHT BS_MENU_WIDTH 0 0
        call    print_frame
        add     sp, 10

        mov     dx, 1
@@main_loop:
        mov     bx, offset fx_state - 1
        add     bx, dx
        add     bx, dx
        mov     cx, TEXT_WHITE
        test    [byte ptr bx], 1
        jz      @@set_text_white
        mov     cx, TEXT_GREEN
@@set_text_white:
        mov     bx, offset fx_text - 2
        add     bx, dx
        add     bx, dx
        push    dx
        push    cx dx 1 ds [word ptr bx]
        call    print_str
        add     sp, 10
        pop     dx
        inc     dx
        cmp     dx, FX_COUNT + 1
        jne     @@main_loop
@@return:
        ret
endp show_bs_menu

; --------------------------------------------------------------------------
; Function: show_practise_menu
; Description: Show the practise menu and get its input. Won't return after a
;              'Z' key is pressed.
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc show_practise_menu near
        push    (offset practise_menu_window)
        call    init_window
        add     sp, 2

        ; Draw the background shadow
        movzx   ax, [byte ptr practise_menu_window.height]
        shl     ax, 4
        push    ax
        movzx   ax, [byte ptr practise_menu_window.width]
        push    ax
        movzx   ax, [byte ptr practise_menu_window.top_left_y]
        shl     al, 4
        push    ax
        movzx   ax, [byte ptr practise_menu_window.top_left_x]
        push    ax
        call    draw_background_shadow
        add     sp, 8

        mov     [word ptr prac_menu_state], 1
        mov     [byte ptr arrow_state], 0

        push    (offset playing_mode_slider) 0FFFFh
        push    (offset practise_menu_window)
        call    window_insert_component                         ; delayed sp+6
        push    (offset section_slider) (offset playing_mode_slider)
        push    (offset practise_menu_window)
        call    window_insert_component                         ; delayed sp+6
        push    (offset stage_slider) (offset section_slider)
        push    (offset practise_menu_window)
        call    window_insert_component                         ; delayed sp+6
        push    (offset life_slider) (offset stage_slider)
        push    (offset practise_menu_window)
        call    window_insert_component                         ; delayed sp+6
        push    (offset bomb_slider) (offset life_slider)
        push    (offset practise_menu_window)
        call    window_insert_component                         ; delayed sp+6
        add     sp, 30                                          ; sp+30

        call    update_prac_window_components_from_its_values
        push    offset practise_menu_window
        call    draw_window
        add     sp, 2

@@wait_for_z_pressed_loop:
        xor     ax, ax
@@stall:                        ; stall for a while between two checks of memory
        inc     ax
        test    ax, 100h
        jnz     @@stall
        cmp     [word ptr prac_menu_state], 1
        je      @@wait_for_z_pressed_loop

        ret
endp show_practise_menu

; ============================================================================
;                                PRACTISE MENU UI
; ============================================================================
include "..\src\tui\tsrtuidt.asm"
include "..\src\tui\tsrtui.asm"

practise_menu_window    ui_window {     \
        top_left_x              = 40,   \
        top_left_y              = 12,   \
        width                   = 36,   \
        height                  = 11,   \
        default_slider_width    = 22    \
}

playing_mode_original_str       db 'Original', 0
playing_mode_custom_str         db 'Custom', 0
proc playing_mode_text_func near
arg @@in_lo:word, @@in_hi:word
        mov     ax, offset playing_mode_custom_str
        cmp     [@@in_lo], 0
        jne     @@skip_set_playing_mode_original
        mov     ax, offset playing_mode_original_str
@@skip_set_playing_mode_original:
        ret
endp playing_mode_text_func
playing_mode_label      db 'Mode', 0
playing_mode_slider     ui_slider {                             \
        value           = 0,                                    \
        min_value       = 0,                                    \
        max_value       = 1,                                    \
        label_off       = offset playing_mode_label,            \
        text_func_off   = offset cseg:playing_mode_text_func,   \
        window_off      = offset practise_menu_window           \
}
; TODO: Maybe compress this a little bit.
section_str_arr                 dw \
        (offset section_str_1_5), \
        (offset section_str_makai_6_10), (offset section_str_jigoku_6_10), \
        (offset section_str_makai_11_15), (offset section_str_jigoku_11_15), \
        (offset section_str_makai_16_20), (offset section_str_jigoku_16_20)
section_str_1_5                 db '1-5', 0
section_str_makai_6_10          db ' Makai 6-10', 0
section_str_jigoku_6_10         db 'Jigoku 6-10', 0
section_str_makai_11_15         db ' Makai 11-15', 0
section_str_jigoku_11_15        db 'Jigoku 11-15', 0
section_str_makai_16_20         db ' Makai 16-20', 0
section_str_jigoku_16_20        db 'Jigoku 16-20', 0
proc section_text_func near
arg @@in_lo:word, @@in_hi:word
        mov     bx, [@@in_lo]
        add     bx, bx
        mov     ax, [bx + (offset section_str_arr)]
        ret
endp section_text_func
section_label      db 'Section', 0
section_slider    ui_slider {                                   \
        value           = 0,                                    \
        min_value       = 0,                                    \
        max_value       = 6,                                    \
        label_off       = offset section_label,                 \
        text_func_off   = offset cseg:section_text_func,        \
        window_off      = offset practise_menu_window           \
}
real_stage      db 0
proc stage_text_func near
arg @@in_lo:word, @@in_hi:word
        ; Real stage number = (Route slider value + 1) / 2 * 5 + display value
        mov     ax, [word ptr section_slider.value]
        inc     ax
        sar     ax, 1
        imul    ax, 5
        add     ax, [@@in_lo]
        mov     [real_stage], al
        push    0 ax
        call    dword_to_dec
        add     sp, 4
        ret
endp stage_text_func
stage_slider_label      db 'Stage', 0
stage_slider    ui_slider {                             \
        value           = 1,                            \
        min_value       = 1,                            \
        max_value       = 5,                            \
        label_off       = offset stage_slider_label,    \
        text_func_off   = offset cseg:stage_text_func,  \
        window_off      = offset practise_menu_window   \
}
life_slider_label       db 'Life', 0
life_slider     ui_slider {                             \
        value           = 6,                            \
        min_value       = 0,                            \
        max_value       = 6,                            \
        label_off       = offset life_slider_label,     \
        text_func_off   = offset cseg:dword_to_dec,     \
        window_off      = offset practise_menu_window   \
}
bomb_slider_label       db 'Bomb', 0
bomb_slider     ui_slider {                             \
        value           = 5,                            \
        min_value       = 0,                            \
        max_value       = 5,                            \
        label_off       = offset bomb_slider_label,     \
        text_func_off   = offset cseg:dword_to_dec,     \
        window_off      = offset practise_menu_window   \
}
phase_slider_label      db 'Phase', 0
phase_slider    ui_slider {                             \
        value           = 1,                            \
        min_value       = 1,                            \
        max_value       = 2,                            \
        label_off       = offset phase_slider_label,    \
        text_func_off   = offset cseg:dword_to_dec,     \
        window_off      = offset practise_menu_window   \
}
hp_slider_label         db 'HP', 0
hp_slider       ui_slider {                             \
        value           = 1,                            \
        min_value       = 1,                            \
        max_value       = 2,                            \
        label_off       = offset hp_slider_label,       \
        text_func_off   = offset cseg:dword_to_dec,     \
        window_off      = offset practise_menu_window   \
}
skip_opening_label      db 'Skip Opening Animation', 0
skip_opening    ui_tickbox {                            \
        label_off       = offset skip_opening_label,    \
        window_off      = offset practise_menu_window   \
}

vanilla_attack          db 'Vanilla', 0
p2_attack_shingyoku_1   db '1', 0
p2_attack_shingyoku_2   db '2', 0
p2_attack_shingyoku_3   db '3', 0
p2_attack_shingyoku_4   db '4', 0
p2_cur_first_attack_str dw (offset p2_attack_shingyoku_1)
; Returns 'Vanilla' if [@@val] is 0, the ([@@val]-1)-th string starting from
; @@first_str otherwise.
proc attack_text_func near
arg @@val:word, @@first_str:word
local @@last_str:word, @@remain:word
        push    si

        cmp     [byte ptr @@val], 0
        jne     @@not_0
        mov     ax, (offset vanilla_attack)
        jmp     @@return
@@not_0:
        mov     si, [@@first_str]
        mov     ax, [@@val]
        mov     [@@remain], ax
@@main_loop:
        mov     [@@last_str], si
        dec     [word ptr @@remain]
        cmp     [word ptr @@remain], 0
        jne     @@not_found_yet
        mov     ax, [@@last_str]
        jmp     @@return
@@not_found_yet:
        push    ds si
        call    string_length
        add     sp, 4
        add     si, ax
        inc     si
        jmp     @@main_loop

@@return:
        pop     si
        ret
endp attack_text_func
proc p2_text_func near
arg @@in_lo:word, @@in_hi:word
        push    [word ptr p2_cur_first_attack_str] [word ptr @@in_lo]
        call    attack_text_func
        add     sp, 4
        ret
endp p2_text_func
p2_attack_label         db 'P2 Atk', 0
p2_attack       ui_slider {                             \
        label_off       = offset p2_attack_label,       \
        text_func_off   = offset cseg:p2_text_func,     \
        window_off      = offset practise_menu_window   \
}

; Initialize the component linked list of a window object, then print it onto
; the screen.
; Argument 1: The offset of the window object
proc init_window near
arg @@window_off:word
        ; Initialize the component linked list
        mov     bx, [@@window_off]
        xor     ax, ax
        dec     ax
        mov     [bx + ui_window.first_component_off], ax
        mov     [bx + ui_window.tail_component_off], ax
        mov     [bx + ui_window.cur_component_off], ax

        ; Print the frame onto the screen
        push    TEXT_WHITE
        movzx   ax, [byte ptr bx + ui_window.height]
        push    ax
        mov     al, [bx + ui_window.width]
        push    ax
        mov     al, [bx + ui_window.top_left_y]
        push    ax
        mov     al, [bx + ui_window.top_left_x]
        push    ax
        call    print_frame
        add     sp, 10
        ret
endp init_window

struc int18_47_argument_block_t
        3plane_drawing_mode     db 00h
        unused_1                db ?
        1plane_drawing_mode     db 00h
        rect_type               db ?
        unused_2                db 4 dup (?)
        start_x_coord           dw ?
        start_y_coord           dw ?
        unused_3                db 10 dup (?)
        end_x_coord             dw ?
        end_y_coord             dw ?
        line_style              dw 0FFFFh
        unused_4                db 6 dup (?)
        graphic_type            db 1
        working_area            db 20h dup (?)
ends int18_47_argument_block_t

int18_47_argument_block int18_47_argument_block_t {}

; ------------------------------ Helper functions ----------------------------

; For some reason, Turbo Assembler refuses to take the following path as a
; relative path to the include path specified in the command option, so we'll
; have to make it relative to the build path.
include "..\src\asmutils\strcmpnc.asm"
include "..\src\asmutils\sprnthex.asm"
include "..\src\asmutils\tramprnt.asm"
include "..\src\asmutils\memcpy.asm"
include "..\src\asmutils\prntfrme.asm"
include "..\src\asmutils\strlen.asm"

label end_of_resident byte
; ===========================================================================
;                            NON-RESIDENT PART
; ===========================================================================

dos_version_low_message         db 'The version of DOS is too low. DOS 3+ is ',\
                                   'required.$'
successfully_installed          db 'Successfully installed thprac98.$'
failed_to_install               db 'Failed to install thprac98: $'
cannot_get_cef                  db 'Cannot get the address of Critical ', \
                                   'Error Flag. Error Code: '
cannot_get_cef_num              db '??h.$'
cannot_get_mux_id               db 'Cannot register in INT 2Fh.$'
already_installed               db 'Thprac98 has already been installed. $'
failed_to_uninstall             db 'Failed to uninstall thprac98: $'
successfully_uninstalled        db 'Successfully uninstalled thprac98.$'
not_installed                   db "Thprac98 hasn't been installed. $"
int_vector_hooked               db 'INT '
int_vector_hooked_num           db '??h is hooked by someone else.$'
cannot_find_mcb                 db "Can't find the MCB of the previous TSR ", \
                                   "in the MCB chain.$"
unknown_parameter               db 'Unknown paramter.$'

COMMAND_PARAM_LEN_OFFSET        EQU 80h
COMMAND_PARAM_OFFSET            EQU 81h

include 'hookint.asm'   ; Hook Interrupts

; --------------------------------------------------------------------------
; Function: my_main
; Description: Our main function. We need this to use the local variables.
; Input:  Nothing
; Output: The value of AX:
;               00h: Success
;               1Xh: Installation failure
;                       11h: Cannot register in INT 2Fh
;                       12h: Thprac98 has already been installed
;                       13h: Cannot get the Critical Error Flag
;               2Xh: Uninstallation failure
;                       21h: Some interrupt has been hooked by someone else,
;                            cannot uninstall
;                       22h: Thprac98 hasn't been installed
;                       23h: Can't find the MCB of the previous TSR in the
;                            MCB chain
;               F1h: DOS version <3
;               FFh: Unknown parameter
;         The value of DX:
;               00h: Perform INT 21h/4Ch to exit (with an errorlevel of AX)
;               01h: Perform INT 21h/3100h to terminate and stay resident
; --------------------------------------------------------------------------
proc my_main near
local @@told_to_uninstall:byte, @@int_no_hooked:word
        ; Check if we're using DOS 3+
        mov     ah, 30h
        int     21h
        cmp     al, 3
        jae     @@using_dos_3_plus
        mov     dx, offset dos_version_low_message
        mov     ah, 09h
        int     21h
        mov     ax, 0F1h
        jmp     @@return
@@using_dos_3_plus:

        ; Check the parameter
        mov     [@@told_to_uninstall], 0
        mov     al, [cs:COMMAND_PARAM_LEN_OFFSET]
        test    al, al
        jz      @@end_of_parameter_check        ; param == "": to install
        mov     [@@told_to_uninstall], 1
        cmp     [byte ptr cs:COMMAND_PARAM_OFFSET + 1], '/'
        jne     @@unknown_parameter
        cmp     [byte ptr cs:COMMAND_PARAM_OFFSET + 2], 'U'
        je      @@end_of_parameter_check
        cmp     [byte ptr cs:COMMAND_PARAM_OFFSET + 2], 'u'
        je      @@end_of_parameter_check
@@unknown_parameter:  ; param[1] != '/' || (param[2] != 'U' && param[2] != 'u')
        mov     dx, offset unknown_parameter
        mov     ah, 09h
        int     21h
        mov     ax, 0FFh
        jmp     @@return
@@end_of_parameter_check:

        cmp     [@@told_to_uninstall], 1
        je      @@uninstall

        ; ----------- Install the TSR -----------

        ; Save the current segment
        mov     [stored_cseg], cs

        ; Get the address of two flags for DOS calls in TSR
        mov     ah, 34h
        int     21h             ; Get InDOS flag address in ES:BX
        mov     [word ptr indos_flag_addr], bx
        mov     [word ptr indos_flag_addr + 2], es
        push    ds              ; Save DS (used in INT 21h/5D06h to return)
        mov     ax, 5D06h
        int     21h             ; Get Critical Error Flag address in DS:SI
        jnc     @@successfully_get_critical_error_flag_addr
        pop     ds              ; Restore DS (branch 1)
        push    ax (offset cannot_get_cef_num)
        call    sprint_byte
        add     sp, 4
        mov     dx, offset failed_to_install
        mov     ah, 09h
        int     21h
        mov     dx, offset cannot_get_cef
        mov     ah, 09h
        int     21h
        mov     ax, 13h
        jmp     @@return
@@successfully_get_critical_error_flag_addr:
        mov     [word ptr cs:critical_error_flag_addr], si
        mov     [word ptr cs:critical_error_flag_addr + 2], ds
        pop     ds              ; Restore DS (branch 2)

        ; Set up some injected code that can only be determined in the runtime
        mov     [word ptr stage_num_animate_pat + 1], offset my_0b50_0775
        mov     [word ptr stage_num_animate_pat + 3], cs
        mov     [word ptr harry_up_animate_pat + 1], offset my_1924_0364
        mov     [word ptr harry_up_animate_pat + 3], cs
        mov     [word ptr practise_menu_part1_pat + 3], cs

        ; Initialize the Keyboard BIOS
        mov     ah, 03h
        int     18h

        ; Hook the interrupts, and print an error message if an error occurs
        call    hook_interrupts
        test    ax, ax
        jz      @@hook_interrupt_success
        push    ax
        mov     dx, offset failed_to_install
        mov     ah, 09h
        int     21h
        pop     ax
        test    ax, 01h
        jne     @@skip_printing_cannot_get_mux_id
        push    ax
        mov     dx, offset cannot_get_mux_id
        mov     ah, 09h
        int     21h
        pop     ax
@@skip_printing_cannot_get_mux_id:
        test    ax, 02h
        jne     @@skip_printing_already_installed
        push    ax
        mov     dx, offset already_installed
        mov     ah, 09h
        int     21h
        pop     ax
@@skip_printing_already_installed:
        jmp     @@return
@@hook_interrupt_success:

        ; Print 'Successfully installed'
        mov     dx, (offset successfully_installed)
        mov     ah, 09h
        int     21h

        ; Release the environment block. We assume the INT 21h/49h call always
        ; success, since the environment MCB will always on the chain, if our
        ; .COM file is loaded by DOS.
        mov     ax, [es:ENV_SEG_OFF]
        mov     es, ax
        mov     ah, 49h
        int     21h

        jmp     @@terminate_and_stay_resident

@@uninstall:
        ; ---------- Uninstall the TSR ----------

        call    uninstall_previous_tsr
        mov     [@@int_no_hooked], dx
        test    ax, ax
        jz      @@uninstall_previous_tsr_success
        push    ax
        mov     dx, offset failed_to_uninstall
        mov     ah, 09h
        int     21h
        pop     ax
        cmp     ax, 01h
        jne     @@skip_printing_int_vector_hooked
        push    ax
        push    [@@int_no_hooked] (offset int_vector_hooked_num)
        call    sprint_byte
        add     sp, 4
        mov     dx, offset int_vector_hooked
        mov     ah, 09h
        int     21h
        pop     ax
@@skip_printing_int_vector_hooked:
        cmp     ax, 02h
        jne     @@skip_printing_not_installed
        push    ax
        mov     dx, offset not_installed
        mov     ah, 09h
        int     21h
        pop     ax
@@skip_printing_not_installed:
        cmp     ax, 03h
        jne     @@skip_printing_cannot_find_mcb
        push    ax
        mov     dx, offset cannot_find_mcb
        mov     ah, 09h
        int     21h
        pop     ax
@@skip_printing_cannot_find_mcb:
        jmp     @@return
@@uninstall_previous_tsr_success:

        ; Print 'Successfully uninstalled'
        mov     dx, (offset successfully_uninstalled)
        mov     ah, 09h
        int     21h
        jmp     @@return_0

@@terminate_and_stay_resident:
        mov     dx, 01h
        jmp     @@return
@@return_0:
        xor     dx, dx
@@return:
        ret
endp my_main

; Return value:
real_start:
        call    my_main
        test    dx, dx
        jz      @@return_with_int21_4c

        ; Terminate and stay resident. The parameter to INT 21h/3100h (via DX)
        ; is the numbers of paragraph to stay resident. Adding the 100h bytes
        ; of PSP, we have DX = ceil(((offset end_of_resident) + 100h) / 16.0).
        mov     dx, offset end_of_resident + 10Fh
        shr     dx, 4
        mov     ax, 3100h
        int     21h

@@return_with_int21_4c:
        mov     ah, 4Ch
        int     21h
ends cseg
end start