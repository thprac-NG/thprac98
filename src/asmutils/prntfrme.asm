; Print a frame onto the TRAM.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
;
; Procedures:
;       void near print_frame(unsigned x0, unsigned y0, unsigned width,
;                             unsigned height, unsigned attr);

pushstate
ideal
radix 10
locals
p386

; --------------------------------------------------------------------------
; Function: print_frame
; Description: Print a frame onto the TRAM. The area inside the frame will be
;              filled with halfwidth spaces (0x0020). The box-drawing
;              characters used are shown below:
;                          _   _
;                         |     |   |_   _|   --    |
;                         98h  99h  9Ah  9Bh  95h  96h
;
; Input:  Argument 1 (word): X coordinate of the top-left corner
;         Argument 2 (word): Y coordinate of the top-left corner
;         Argument 3 (word): width of the frame
;         Argument 4 (word): height of the frame
;         Argument 5 (word): The text attribute
; Output: None
; --------------------------------------------------------------------------
proc print_frame near
arg @@x0:word, @@y0:word, @@width:word, @@height:word, @@attr:word
        push    es di ax cx si
        mov     ax, TRAM_SEG
        mov     es, ax
        cld

        ; Print the first row
        mov     di, [@@y0]
        imul    di, 80
        add     di, [@@x0]
        shl     di, 1
        mov     [word es:di], 98h
        add     di, 2
        mov     cx, [@@width]
        sub     cx, 2
        mov     ax, 95h
        rep stosw
        mov     [word es:di], 99h

        ; Print the last row
        mov     di, [@@y0]
        add     di, [@@height]
        dec     di
        imul    di, 80
        add     di, [@@x0]
        shl     di, 1
        mov     [word es:di], 9Ah
        add     di, 2
        mov     cx, [@@width]
        sub     cx, 2
        mov     ax, 95h
        rep stosw
        mov     [word es:di], 9Bh

        ; Print the middle rows
        mov     si, 2           ; si: the 1-based index of row now printing
@@L1:
        mov     di, [@@y0]
        add     di, si
        dec     di
        imul    di, 80
        add     di, [@@x0]
        shl     di, 1
        mov     [word ptr es:di], 96h
        add     di, 2
        mov     ax, 20h
        mov     cx, [@@width]
        sub     cx, 2
        rep stosw
        mov     [word ptr es:di], 96h
        inc     si
        cmp     si, [@@height]
        jne     @@L1

        ; Set the attribute
        mov     ax, TRAM_ATTR_SEG
        mov     es, ax
        mov     ax, [@@attr]
        mov     si, 0           ; si: the 0-based index of row now printing
@@L2:
        mov     di, [@@y0]
        add     di, si
        imul    di, 80
        add     di, [@@x0]
        shl     di, 1
        mov     cx, [@@width]
        rep stosw
        inc     si
        cmp     si, [@@height]
        jne     @@L2

        pop     si cx ax di es
        ret
endp print_frame

popstate
