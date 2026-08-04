; Hook/Unhook the interrupts.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
; `include` dependency: interupt.asm
;
; Procedures:
;       unsigned near check_tsr_status(void);
;       unsigned near hook_interrupts(void);
;       unsigned near uninstall_previous_tsr(void);

pushstate
ideal
radix 10
locals
p386

SMALLEST_POSSIBLE_MUX_ID        = 0C0h

; --------------------------------------------------------------------------
; Function: check_tsr_status
; Description: Check whether thprac98's TSR is hooked into INT 2Fh.
; Input:  Nothing
; Output: AH == 00h: The TSR isn't hooked into INT 2Fh
;         AH != 00h: AH: The MUX id of the TSR in INT 2Fh
; --------------------------------------------------------------------------
proc check_tsr_status near
local @@mux_id:byte
        assume  ds:cseg

        ; Initialize. We don't know whether the other INT 2Fh will change these
        ; callee-saved registers, so we're saving it for safety.
        mov     [@@mux_id], 0
        push    di si ds fs gs

        ; Check through every possible MUX id
        ; ------------------------------------------ {
        mov     ah, SMALLEST_POSSIBLE_MUX_ID
@@check_every_mux_id_loop:
        push    ax
        xor     al, al
        mov     [@@mux_id], ah
        int     2Fh
        pop     dx

        ; Check if AL is 0FFh, and BX, CX match our magic number
        inc     al
        test    al, al
        jnz     @@not_this_mux_id
        cmp     bx, INT2F_MAGIC_BX
        jne     @@not_this_mux_id
        cmp     cx, INT2F_MAGIC_CX
        jne     @@not_this_mux_id
        mov     ah, [@@mux_id]
        jmp     @@return
@@not_this_mux_id:

        mov     ax, dx
        inc     ah
        test    ah, ah
        jnz     @@check_every_mux_id_loop
        ; ------------------------------------------ }

        ; Can't find the MUX id. The AH is already 0 here.

@@return:
        pop    gs fs ds si di           ; Restore the registers
        ret
endp check_tsr_status

; --------------------------------------------------------------------------
; Function: hook_interrupts
; Description: Hook the interrupts. To be more specific, hook INT 07h, INT 08h,
;              INT 1Ch, INT 21h, and INT 2Fh.
; Input:  Nothing
; Output: AX == 00h: Success
;         AX == 01h: Cannot register in INT 2Fh
;         AX == 02h: Thprac98's TSR has already been installed
; --------------------------------------------------------------------------
proc hook_interrupts near
local @@mux_id:byte
        assume  ds:cseg
        push    si

        ; Return 02h if TSR has already been installed
        call    check_tsr_status
        test    ah, ah
        jz      @@tsr_not_intalled
        mov     ax, 02h
        jmp     @@return
@@tsr_not_intalled:

        mov     [@@mux_id], 0
        ; Check through every possible MUX id
        ; ------------------------------------------ {
        mov     ah, SMALLEST_POSSIBLE_MUX_ID
@@check_every_mux_id_loop:
        push    ax
        xor     al, al
        mov     [@@mux_id], ah
        int     2Fh
        pop     dx

        ; If INT 2Fh/AL=00h returns a 0FFh in AL, then it's registered
        inc     al
        test    al, al
        jz      @@this_mux_id_has_been_installed
        mov     [@@mux_id], dh
        jmp     @@check_every_mux_id_loop_break
@@this_mux_id_has_been_installed:

        mov     ax, dx
        inc     ah
        test    ah, ah
        jnz     @@check_every_mux_id_loop
@@check_every_mux_id_loop_break:
        ; ------------------------------------------ }

        cmp     [@@mux_id], 0
        jne     @@avaiable_mux_id_exists
        mov     ax, 01h
        jmp     @@return
@@avaiable_mux_id_exists:
        mov     al, [@@mux_id]
        mov     [int2f_mux_id], al

        ; Store the previous addresses of the interrupts
        mov     ax, 3507h
        int     21h
        mov     [word ptr old_int7], bx
        mov     [word ptr old_int7 + 2], es
        mov     al, 08h
        int     21h
        mov     [word ptr old_int8], bx
        mov     [word ptr old_int8 + 2], es
        mov     al, 1Ch
        int     21h
        mov     [word ptr old_int1c], bx
        mov     [word ptr old_int1c + 2], es
        mov     al, 21h
        int     21h
        mov     [word ptr old_int21], bx
        mov     [word ptr old_int21 + 2], es
        mov     al, 2Fh
        int     21h
        mov     [word ptr old_int2f], bx
        mov     [word ptr old_int2f + 2], es

        ; Save DS and set it to our CS in order to call INT 21h/25h
        push    ds
        mov     ax, cs
        mov     ds, ax

        ; Hook into INT 07h, INT 08h, and INT 1Ch/02h.
        ; In the original INT1Ch/02h routine, it will store your CX input (i.e.,
        ; the delay before calling the routine) 0000:058A, and store your ES:BX
        ; (i.e., the address of the routine) input into the vector of INT7.
        ; Normally, INT8 is masked out if there is no INT1Ch/02h routine
        ; running, and if one hooks into INT8, it won't be called anyway.
        ; If one manually calls INT8 without setting 0000:058A, they effectively
        ; make a call of INT1Ch/02h with CX=0000h, ES:BX=(whatever in the INT7
        ; vector), causing a General Protection Fault to occur after 655.36s.
        ; To prevent this from happening, we can set 0000:058A to an arbitrary
        ; non-zero value and set INT7 to be as INT8.
        mov     dx, offset my_int8
        mov     ax, 2507h
        int     21h
        mov     al, 08h
        int     21h
        mov     dx, offset my_int1c
        mov     al, 1Ch
        int     21h
        mov     ax, 0000h
        mov     es, ax
        mov     si, 058Ah
        mov     [word ptr es:si], 500
        int     08h

        ; Hook into INT 21h/4Bh and INT 2Fh/[@@mux_id].
        mov     ax, 2521h
        mov     dx, offset my_int21
        int     21h
        mov     al, 2Fh
        mov     dx, offset my_int2f
        int     21h

        ; Successfully installed. Restore DS and return 00h.
        pop     ds
        xor     ax, ax

@@return:
        pop     si
        ret
endp hook_interrupts

struc mcb
        type                    db ?
        owner_psp_seg           dw ?
        size_in_paragraph       dw ?
        unused                  db 3 dup (?)
        ascii_filename          db 8 dup (?)
ends mcb

; --------------------------------------------------------------------------
; Function: uninstall_previous_tsr
; Description: Uninstall the already-installed thprac98 TSR.
; Input:  Nothing
; Output: AX == 00h: Success
;         AX == 01h: Some interrupt has been hooked by someone else, cannot
;                    uninstall. (DX: The interrupt number)
;         AX == 02h: Thprac98's TSR hasn't been installed
;         AX == 03h: Can't find the MCB of the previous TSR in the MCB chain
; --------------------------------------------------------------------------
proc uninstall_previous_tsr near
local @@mux_id:byte, @@prev_cseg:word, @@found_mcb:byte, @@prev_env:word
        push    ds

        ; Return 02h if TSR has already been installed
        call    check_tsr_status
        test    ah, ah
        jnz     @@tsr_installed
        mov     ax, 02h
        jmp     @@return
@@tsr_installed:
        mov     [@@mux_id], ah

        ; Check if the interrupt vectors are the same
        mov     ah, [@@mux_id]
        mov     al, 01h
        int     2Fh
        mov     [@@prev_cseg], ax
        xor     dh, dh
        mov     ax, 3508h               ; Check 08h
        mov     dl, al
        int     21h
        mov     cx, es
        cmp     cx, [@@prev_cseg]
        jne     @@vectors_not_match
        cmp     bx, offset my_int8
        jne     @@vectors_not_match
        mov     al, 1Ch                 ; Check 1Ch
        mov     dl, al
        int     21h
        mov     cx, es
        cmp     cx, [@@prev_cseg]
        jne     @@vectors_not_match
        cmp     bx, offset my_int1c
        jne     @@vectors_not_match
        mov     al, 21h                 ; Check 21h
        mov     dl, al
        int     21h
        mov     cx, es
        cmp     cx, [@@prev_cseg]
        jne     @@vectors_not_match
        cmp     bx, offset my_int21
        jne     @@vectors_not_match
        mov     al, 2Fh                 ; Check 2Fh
        mov     dl, al
        int     21h
        mov     cx, es
        cmp     cx, [@@prev_cseg]
        jne     @@vectors_not_match
        cmp     bx, offset my_int2f
        jne     @@vectors_not_match
        jmp     @@vectors_match
@@vectors_not_match:
        mov     ax, 01h
        jmp     @@return
@@vectors_match:

        ; Check through the MCB chain to find the MCB of the previous TSR
        mov     ax, [@@prev_cseg]
        mov     es, ax
        mov     ax, [word ptr es:2Ch]
        mov     [@@prev_env], ax
        mov     [@@found_mcb], 0
        mov     ah, 52h
        int     21h
        mov     ax, [es:bx - 2]
        mov     es, ax                          ; es = segment of the first MCB
        mov     cl, [es:mcb.type]
@@mcb_chain_check_loop:
        cmp     cl, 'Z'
        je      @@mcb_chain_check_loop_break
        cmp     cl, 'M'
        jne     @@mcb_chain_check_loop_break    ; MCB corrupted, break
        ; Check if the current MCB belongs to the previous TSR
        mov     ax, es
        mov     ax, [es:mcb.owner_psp_seg]
        cmp     ax, [@@prev_cseg]
        jne     @@doesnt_belong_to_previous_tsr       ; check MCB owner field
        mov     ax, es
        inc     ax
        cmp     ax, [@@prev_cseg]
        jne     @@not_prev_cseg                 ; Check if it's previous cseg
        or      [@@found_mcb], 1
@@not_prev_cseg:
        cmp     ax, [@@prev_env]
        jne     @@not_prev_env                  ; Check if it's previous env
        or      [@@found_mcb], 2
@@not_prev_env:
        cmp     [@@found_mcb], 3
        je      @@mcb_chain_check_loop_break    ; Break if found both
@@doesnt_belong_to_previous_tsr:
        ; Move to the next MCB
        mov     ax, [es:mcb.size_in_paragraph]
        mov     bx, es
        add     ax, bx
        inc     ax
        cmp     ax, 0A000h
        jae     @@mcb_chain_check_loop_break    ; MCB corrupted, break
        mov     es, ax
        jmp     @@mcb_chain_check_loop
@@mcb_chain_check_loop_break:
        cmp     [@@found_mcb], 0
        jne     @@skip_return_3
        mov     ax, 3
        jmp     @@return
@@skip_return_3:

        ; Restore the interrupt vectors
        mov     ax, [@@prev_cseg]
        mov     es, ax
        lds     dx, [dword ptr es:old_int7]
        mov     ax, 2507h
        int     21h
        lds     dx, [dword ptr es:old_int8]
        mov     al, 08h
        int     21h
        lds     dx, [dword ptr es:old_int1c]
        mov     al, 1Ch
        int     21h
        lds     dx, [dword ptr es:old_int21]
        mov     al, 21h
        int     21h
        lds     dx, [dword ptr es:old_int2f]
        mov     al, 2Fh
        int     21h

        ; Free the memory of TSR. The INT 21h/49h call is guarenteed to success
        ; at this point.
        mov     ax, [@@prev_cseg]
        mov     es, ax
        mov     ah, 49h
        int     21h
        mov     ax, [@@prev_env]
        mov     es, ax
        mov     ah, 49h
        int     21h

        ; Successfully uninstalled TSR. Return 0.
        xor     ax, ax

@@return:
        pop     ds
        ret
endp uninstall_previous_tsr

popstate
