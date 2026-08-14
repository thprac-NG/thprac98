; Inject into the current process.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
; `include` dependency: none
; Procedure dependency: memory_copy
;
; Structs:
;       inject_code_t
; Global variables:
;       int8_t must_match[1]
; Procedures:
;       void near inject_one(inject_code_t near* inject_code, bool16 to_inject,
;                            void __seg* psp_seg);

must_match      db -1

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
        variable_mem    dw (offset must_match)
ends inject_code_t

; --------------------------------------------------------------------------
; Function: inject_one
; Description: Inject the code into the current process.
; Input:  Argument 1 (word): offset to the inject_code_t structure
;         Argument 2 (word): 1 means to inject, 0 means to restore
;         Argument 3 (word): the PSP segment of the current program
; Output: None
; --------------------------------------------------------------------------
proc inject_one near
arg @@inject_code:word, @@flag:word, @@psp_seg:word
local @@must_match:byte
        push    si di
        mov     si, [@@inject_code]
        add     [@@psp_seg], 10h  ; Add the size of PSP (100h)
        mov     ax, [@@psp_seg]
        add     ax, [word ptr si + inject_code_t.seg]
        mov     es, ax
        mov     si, [@@inject_code]
        test    [@@flag], 1
        jz      @@restore
        ; Inject the code.
        mov     dl, [byte ptr si + inject_code_t.variable_mem]
        mov     [@@must_match], dl
        xor     ax, ax
@@check_inject_code_matching_loop:
        mov     di, [word ptr si + inject_code_t.off]
        add     di, ax
        mov     cl, [byte ptr es:di]
        mov     bx, [word ptr si + inject_code_t.original_mem]
        add     bx, ax
        cmp     cl, [byte ptr bx]
        je      @@byte_match
        cmp     [@@must_match], -1
        je      @@return
        mov     bx, [word ptr si + inject_code_t.variable_mem]
        add     bx, ax
        cmp     [byte ptr bx], 1
        jne     @@return
@@byte_match:
        inc     ax
        cmp     ax, [word ptr si + inject_code_t.len]
        jne     @@check_inject_code_matching_loop
        mov     di, [word ptr si + inject_code_t.off]
        mov     bx, [word ptr si + inject_code_t.original_mem]
        push    es
        push    [word ptr si + inject_code_t.len] es di ds bx
        call    memory_copy
        add     sp, 10
        pop     es
        mov     bx, [word ptr si + inject_code_t.patched_mem]
        push    es
        push    [word ptr si + inject_code_t.len] ds bx es di
        call    memory_copy
        add     sp, 10
        pop     es
        jmp     @@return
@@restore:
        ; Restore the code.
        xor     ax, ax
@@restore_code_loop:
        mov     di, [word ptr si + inject_code_t.off]
        add     di, ax
        mov     bx, [word ptr si + inject_code_t.patched_mem]
        add     bx, ax
        mov     cl, [byte ptr es:di]
        cmp     cl, [byte ptr bx]
        jne     @@return
        inc     ax
        cmp     ax, [word ptr si + inject_code_t.len]
        jne     @@restore_code_loop
        mov     bx, [word ptr si + inject_code_t.original_mem]
        mov     di, [word ptr si + inject_code_t.off]
        push    [word ptr si + inject_code_t.len] ds bx es di
        call    memory_copy
        add     sp, 10
@@return:
        pop     di si
        ret
endp inject_one

popstate
