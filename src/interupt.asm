; The hooked interrupts.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
; `include` dependency: none
;
; Procedures:
;       void interrupt my_int8(void);
;       void interrupt my_int1c(void);
;       void interrupt my_int21(void);
;       void interrupt my_int2f(void);
;
; Global variables:
;       void interrupt (*)(void) old_int7, old_int8, old_int1c, old_int21,
;                                old_int2f;
;       void __seg* stored_cseg;
;
; Macros:
;       INT2F_MAGIC_BX  = <a word constant>
;       INT2F_MAGIC_CX  = <a word constant>

pushstate
ideal
radix 10
locals
p386

; The segment:offset of the interrupt vectors before hooking. The word with an
; offset of 0 is the corresponding offset, and the one with an offset of 2 is
; the segment.
old_int7        dd ?
old_int8        dd ?
old_int1c       dd ?
old_int21       dd ?
old_int2f       dd ?

int1c_counter   dw 0
int1c_waiting   db 0
int1c_using     db 0
int1c_routine   dd ?

int2f_mux_id    db 0
INT2F_MAGIC_BX  = 0B6DDh        ; Shift-JIS of half-width katakana 'kawa'
INT2F_MAGIC_CX  = 0BCDBh        ; Shift-JIS of half-width katakana 'shiro'

int21_4b_just_loaded            db 0
INT21_4B_WAIT_LOAD_TIME         = 5           ; unit: 10ms

ON_TICK_CALL_INTERVAL   = 4                   ; unit: 10ms
on_tick_call_counter    db 0

stored_cseg     dw ?

; --------------------------------------------------------------------------
; Function: my_int8
; Description: Our own INT 08h (timer interrupt) routine, which gets called
;              every 10ms. Calls `on_tick` once every `ON_TICK_CALL_INTERVAL`
;              times. Calls `after_load_exe` `INT_21_4b_WAIT_LOAD_TIME`*10 ms
;              after every INT 21h/4Bh call.
; Input/Output: Nothing
; --------------------------------------------------------------------------
proc my_int8 far
        ; Push all the registers to the stack. Note that we need `pushfd` to
        ; push the higher 16 bits of `EFLAGS`.
        pushfd
        pushad
        push    ds es fs gs

        ; Meet the usual assumptions in the .COM file
        cld
        mov     ax, cs
        mov     ds, ax
        assume  ds:cseg

        ; Call the hooked INT 08h routine. Not sure why we're doing this.
        pushf
        call    [dword ptr ds:[old_int8]]

        ; Update the status of the INT 1Ch/02h service.
        mov     al, [int1c_waiting]
        test    al, al
        jz      @@skip_int1c_processing
        dec     [int1c_counter]
        cmp     [int1c_counter], 0
        jne     @@skip_int1c_routine_calling
        xor     ax, ax
        mov     [int1c_waiting], al
        pushf
        call    [dword ptr ds:[int1c_routine]]
@@skip_int1c_routine_calling:
@@skip_int1c_processing:

        ; Check whether some file has just been loaded (through INT 21h/4Bh).
        ; If so, wait for some time for the program to be fully loaded, then
        ; update the menu and inject the code (if its filename matches).
        mov     al, [int21_4b_just_loaded]
        test    al, al
        jz      @@skip_load_check
        dec     al
        mov     [int21_4b_just_loaded], al
        test    al, al
        jnz     @@skip_procedures_after_loading
        call    after_load_exe
@@skip_procedures_after_loading:
@@skip_load_check:

        ; Calls `on_tick` every `ON_TICK_CALL_INTERVAL` times.
        inc     [on_tick_call_counter]
        cmp     [on_tick_call_counter], ON_TICK_CALL_INTERVAL
        jne     @@skip_calling_on_tick
        mov     [on_tick_call_counter], 0
        call    on_tick
@@skip_calling_on_tick:

        ; Restore all the registers
        pop     gs fs es ds
        popad
        popfd
        iret
endp my_int8

; --------------------------------------------------------------------------
; Function: my_int1c
; Description: Our hooked INT 1Ch procedure, providing our own INT 21h/02h
;              service without the usage of INT 08h. Incompatable with the
;              high-resolution mode.
; Input:  AH == 02h: Set the interval timer procedure.
;                    CX: The value of the interval timer, in 10ms. Use 0000h
;                        to specify 655360ms.
;                    ES:BX: The address of the procedure.
;         AH != 02h: Jump to the original INT 1Ch with the input registers.
; Output: AH == 02h: Nothing
;         AH != 02h: (Never returns)
; --------------------------------------------------------------------------
proc my_int1c
        assume  ds:nothing

        ; If not calling INT 1Ch/02h, jump to the original INT 1Ch.
        cmp     ah, 02h
        je      @@skip_jumping_to_original_int1c
        pushf
        call    [dword ptr cs:old_int1c]
        jmp     @@return
@@skip_jumping_to_original_int1c:

        ; Store the registers.
        push    ax ds
        mov     ax, cs
        mov     ds, ax
        assume  ds:cseg

        ; Set the INT 1Ch/02h fields
        mov     [int1c_counter], cx
        mov     [word ptr int1c_routine], bx
        mov     [word ptr int1c_routine + 2], es
        mov     [int1c_waiting], 1

        ; Restore the registers and return
        pop     ds ax
@@return:
        iret
endp my_int1c

; --------------------------------------------------------------------------
; Function: my_int21
; Description: Our hooked INT 21h procedure, setting the `int21_4b_just_loaded`
;              field every time INT21h/4Bh is called.
; Input:  Registers to pass to the original INT 21h.
; Output: (Never returns)
; --------------------------------------------------------------------------
proc my_int21 far
        assume  ds:nothing
        cmp     ah, 4Bh
        jne     @@skip_setting_just_loaded_field
        mov     [cs:int21_4b_just_loaded], INT21_4B_WAIT_LOAD_TIME
@@skip_setting_just_loaded_field:
        jmp     [dword ptr cs:old_int21]
endp my_int21

; --------------------------------------------------------------------------
; Function: my_int2f
; Description: Our hooked INT 2Fh procedure, providing some features such as
;              querying the segment of the installed TSR.
; Input:  AH == [CS:int2f_mux_id]:
;               AL == 00h: Check whether this MUX id has been installed.
;               AL == 01h: Check the segment of the installed TSR.
;               AL == 11h: Re-render the menu, and re-inject the code.
;               AL == 12h: Re-render the menu only.
;         AH != [CS:int2f_mux_id]: Jump to the hooked INT 2Fh procedure.
; Output: AH == [CS:int2f_mux_id]:
;               AL == 00h: AL <- 0FFh, BX <- 0B6DDh, CX <- 0BCDBh
;               AL == 01h: AX <- segment of the installed TSR
;               AL == 11h: Nothing
;               AL == 12h: Nothing
;         AH != [CS:int2f_mux_id]: (Never returns)
; --------------------------------------------------------------------------
proc my_int2f far
        assume  ds:nothing

        ; If not calling our mux service, jump to the hooked INT 2F procedure
        cmp     ah, [cs:int2f_mux_id]
        je      @@skip_jumping_to_original_int2f
        jmp     [dword ptr cs:old_int2f]
@@skip_jumping_to_original_int2f:

        ; Push all the registers to the stack
        push    ds

        ; Meet the usual assumptions in the .COM file
        mov     bx, cs
        mov     ds, bx
        assume  ds:cseg

        ; AL == 00h: Check whether this MUX id has been installed
        test    al, al
        jnz     @@skip_al_00_handling
        mov     al, 0FFh
        mov     bx, INT2F_MAGIC_BX
        mov     cx, INT2F_MAGIC_CX
        jmp     @@return
@@skip_al_00_handling:

        ; AL == 01h: Check the segment of the installed TSR
        cmp     al, 1
        jnz     @@skip_al_01_handling
        mov     ax, [stored_cseg]
        jmp     @@return
@@skip_al_01_handling:

        ; AL == 11h: Re-render the menu, and re-inject the code
        cmp     al, 1
        jnz     @@skip_al_11_handling
        call    store_covered_tram
        call    show_bs_menu
        call    inject
        jmp     @@return
@@skip_al_11_handling:

        ; AL == 12h: Re-render the menu only
        cmp     al, 1
        jnz     @@return
        call    store_covered_tram
        call    show_bs_menu

        ; Restore all the registers and returns
@@return:
        pop     ds
        iret
endp my_int2f

popstate
