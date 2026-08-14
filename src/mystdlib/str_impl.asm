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
arg @@stosd_addr:dword, @@stosd_count:word, @@val:word
        push    di

        mov     ax, [word ptr @@stosd_addr + 2]
        mov     es, ax
        mov     di, [word ptr @@stosd_addr]
        mov     ax, [@@val]
        mov     cx, ax
        shl     eax, 10h
        mov     ax, cx
        mov     cx, [@@stosd_count]
        ; # TODO: Make the following instruction aligned to 4-byte border to
        ;         improve performance.
        rep stosd

        pop     di
        ret
endp _MEMSET_HELPER

proc _MEMCPY_HELPER near
arg @@dest:dword, @@src:dword, @@movsb_count:word
        push    ds si di

        mov     es, [word ptr @@dest + 2]
        mov     di, [word ptr @@dest]
        mov     ds, [word ptr @@src + 2]
        assume  ds:nothing
        mov     si, [word ptr @@src]
        mov     cx, [@@movsb_count]
        ; # TODO: Make the following instruction aligned to 4-byte border to
        ;         improve performance.
        rep movsb

        pop     di si ds
        assume  ds:dataseg
        ret
endp _MEMCPY_HELPER
end