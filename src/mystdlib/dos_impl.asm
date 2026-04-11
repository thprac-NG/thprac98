ideal
model small, cpp  ; Set calling convention to C++-style
radix 10  ; The immediates will be recognized as decimal by default
locals  ; Enables block-scoped symbols
stack 100h
p386

codeseg
        public _INT86_
        public _INT86X_

; A reimplementation of the C struct WORDREGS in dos.h.
struc wordregs_t
        ax_     dw ?
        bx_     dw ?
        cx_     dw ?
        dx_     dw ?
        si_     dw ?
        di_     dw ?
        cflag_  dw ?
        flags_  dw ?
ends wordregs_t
; A reimplementation of the C struct SREGS in dos.h.
struc sregs_t
        es_     dw ?
        cs_     dw ?
        ss_     dw ?
        ds_     dw ?
ends sregs_t

proc _INT86_ near
arg @@int_no:word, @@in_regs_off:word, @@in_regs_seg:word, \
@@out_regs_off:word, @@out_regs_seg:word
        push    bp
        mov     bp, sp
        push    di si

        ; Set up the interrupt call
        mov     ax, [@@int_no]
        mov     [byte ptr cs:@@int_num_text], al

        ; Load all the registers (the `cflag` field is ignored, since it will be
        ; covered by `flags`)
        mov     ax, [@@in_regs_seg]
        mov     es, ax
        mov     si, [@@in_regs_off]
        mov     ax, [word ptr es:si + wordregs_t.ax_]
        mov     bx, [word ptr es:si + wordregs_t.bx_]
        mov     cx, [word ptr es:si + wordregs_t.cx_]
        mov     dx, [word ptr es:si + wordregs_t.dx_]
        mov     di, [word ptr es:si + wordregs_t.di_]
        push    [word ptr es:si + wordregs_t.flags_]
        popf
        mov     si, [word ptr es:si + wordregs_t.si_]

        ; Call the interrupt
        db      0CDh
@@int_num_text:
        db      00h

        ; Store the registers and the return value (i.e., ax after interrupt)
        push    si ax
        mov     ax, [@@out_regs_seg]
        mov     es, ax
        mov     si, [@@out_regs_off]
        mov     bx, [word ptr es:si + wordregs_t.bx_]
        mov     cx, [word ptr es:si + wordregs_t.cx_]
        mov     dx, [word ptr es:si + wordregs_t.dx_]
        mov     di, [word ptr es:si + wordregs_t.di_]
        pushf
        pop     ax
        mov     [word ptr es:si + wordregs_t.flags_], ax
        and     ax, 1
        mov     [word ptr es:si + wordregs_t.cflag_], ax
        pop     ax
        mov     [word ptr es:si + wordregs_t.ax_], ax
        pop     [word ptr es:si + wordregs_t.si_]

        pop     si di
        pop     bp
endp _INT86_

proc _INT86X_ near
arg @@int_no:word, @@in_regs_off:word, @@in_regs_seg:word, \
@@out_regs_off:word, @@out_regs_seg:word, \
@@seg_regs_off:word, @@seg_regs_seg:word
        push    bp
        mov     bp, sp
        push    ds di si

        ; Set up the interrupt call
        mov     ax, [@@int_no]
        mov     [byte ptr cs:@@int_num_text], al

        ; Load all the registers (the `cflag` field is ignored, since it will be
        ; covered by `flags`)
        mov     ax, [@@seg_regs_seg]
        mov     es, ax
        mov     si, [@@seg_regs_off]
        mov     ax, [word ptr es:si + sregs_t.ds_]
        mov     ds, ax
        push    [word ptr es:si + sregs_t.es_]
        mov     ax, [@@in_regs_seg]
        mov     es, ax
        mov     si, [@@in_regs_off]
        mov     ax, [word ptr es:si + wordregs_t.ax_]
        mov     bx, [word ptr es:si + wordregs_t.bx_]
        mov     cx, [word ptr es:si + wordregs_t.cx_]
        mov     dx, [word ptr es:si + wordregs_t.dx_]
        mov     di, [word ptr es:si + wordregs_t.di_]
        push    [word ptr es:si + wordregs_t.flags_]
        popf
        mov     si, [word ptr es:si + wordregs_t.si_]
        pop     es

        ; Call the interrupt
        db      0CDh
@@int_num_text:
        db      00h

        ; Store the registers and the return value (i.e., ax after interrupt)
        push    si ax
        mov     ax, [@@out_regs_seg]
        mov     es, ax
        mov     si, [@@out_regs_off]
        mov     bx, [word ptr es:si + wordregs_t.bx_]
        mov     cx, [word ptr es:si + wordregs_t.cx_]
        mov     dx, [word ptr es:si + wordregs_t.dx_]
        mov     di, [word ptr es:si + wordregs_t.di_]
        pushf
        pop     ax
        mov     [word ptr es:si + wordregs_t.flags_], ax
        and     ax, 1
        mov     [word ptr es:si + wordregs_t.cflag_], ax
        push    ax
        mov     [word ptr es:si + wordregs_t.ax_], ax
        pop     [word ptr es:di + wordregs_t.si_]

        pop     si di ds
        pop     bp
endp _INT86X_

end