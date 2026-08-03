; Copy a specific number of bytes from source to destination.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
;
; Procedures:
;       void near memory_copy(void far* dest, void far* src, unsigned size);

pushstate
ideal
radix 10
locals
p386

; --------------------------------------------------------------------------
; Function: memory_copy
; Description: Copy a specific number of bytes from source to destination.
; Input:  Argument 1 (dword): The address of the destination location.
;         Argument 2 (dword): The address of the source location.
;         Argument 3 (word): The number of bytes to be copied.
; Output: None
; --------------------------------------------------------------------------
proc memory_copy
arg @@dest:dword, @@src:dword, @@size:word
        push    di si ds

        les     di, [@@dest]
        lds     si, [@@src]
        mov     cx, [@@size]
        rep movsb

        pop     ds si di
        ret
endp memory_copy

popstate
