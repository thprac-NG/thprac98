; The content of the data segment with tsrtui.asm.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
;
; Global Variables:
;       unsigned char vram_seg_arr[4]
;       char dword_to_dec_str[11]

pushstate
ideal
radix 10
locals
p386

; Used by procedure `draw_background_shadow`
vram_seg_arr    db 0A8h, 0B0h, 0B8h, 0E0h

; Used by procedure `dword_to_dec`
dword_to_dec_str        db 11 dup (0)

popstate
