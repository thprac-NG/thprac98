ideal
model small, cpp  ; Set calling convention to C++-style
radix 10  ; The immediates will be recognized as decimal by default
locals  ; Enables block-scoped symbols
stack 100h
p386

codeseg
        public _MEMSET_HELPER
        public _MEMCPY_HELPER

proc _MEMSET_HELPER near
arg @@stosd_seg:word, @@stosd_off:word, @@stosd_count:word, @@val:word
        push    di

        mov     ax, [@@stosd_seg]
        mov     es, ax
        mov     di, [@@stosd_off]
        mov     ax, [@@val]
        mov     cx, ax
        shl     eax, 10h
        mov     ax, cx
        mov     cx, [@@stosd_count]
        ; # TODO: Make the following instruction aligned to 4-byte border to
        ;         improve performance.
        rep stosd

        pop     di
        pop     bp
        ret
endp _MEMSET_HELPER

proc _MEMCPY_HELPER near
arg @@dest_seg:word, @@dest_off:word, @@src_seg:word, @@src_off:word, \
@@movsb_count:word
        push    bp
        mov     bp, sp
        push    ds si di

        mov     ax, [@@dest_seg]
        mov     es, ax
        mov     di, [@@dest_off]
        mov     ax, [@@src_seg]
        mov     ds, ax
        mov     si, [@@src_off]
        mov     cx, [@@movsb_count]
        ; # TODO: Make the following instruction aligned to 4-byte border to
        ;         improve performance.
        rep movsb

        pop     di si ds
        ret
endp _MEMCPY_HELPER
end