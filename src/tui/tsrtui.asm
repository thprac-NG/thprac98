; Minimized TUI utilities for TSR.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.
; Include dependency: tsrtuidt.asm
; Procedure dependency: print_frame, print_str, and string_length
;
; Structs:
;       ui_window
;       ui_component_common
;       ui_slider
;       ui_tickbox
; Enums:
;       ui_type_t
; Procedures:
;       void near window_switch_cur(ui_window near* window, bool16 direction)
;       void near slider_change_value(ui_slider near* slider, bool16 direction)
;       void near window_insert_component(ui_window near* window,
;                                         void near* pos, void near* component)
;       void near draw_window(ui_window near* window)
;       char near* dword_to_dec(unsigned long num);
;       unsigned near draw_slider(ui_slider near* slider, bool16 highlighted,
;                                 unsigned top_left)
;       void near draw_background_shadow(unsigned top_left_x,
;                                        unsigned top_left_y, unsigned width,
;                                        unsigned height)

pushstate
ideal
radix 10
locals
p386

struc ui_window
        top_left_x              db 0
        top_left_y              db 0
        width                   db 2
        height                  db 2
        first_component_off     dw 0FFFFh
        tail_component_off      dw 0FFFFh
        cur_component_off       dw 0FFFFh
        default_slider_width    db 0
        cur_drawing_x           db 1
        cur_drawing_y           db 1
ends ui_window

enum ui_type_t {
        UI_SLIDER_NUM = 0,
        UI_TICKBOX_NUM = 1
}

struc ui_component_common
        window_off              dw 0FFFFh
        prev_component_off      dw 0FFFFh
        next_component_off      dw 0FFFFh
        ui_type                 ui_type_t ?
ends ui_component_common

struc ui_slider
        window_off              dw 0FFFFh
        prev_component_off      dw 0FFFFh
        next_component_off      dw 0FFFFh
        ui_type                 ui_type_t UI_SLIDER_NUM
        value                   dd 0
        min_value               dd 0
        max_value               dd 0
        ; Must be a divisor of (max_value - min_value) and (value - min_value).
        step                    dd 1
        bottom_indicator        db 1
        width                   db 0FFh         ; 0FFh: use window's default
                                                ; must be odd
        ; A near procedure, of type (const char near* (*near)(dword).
        ; For some reason, you can't correctly set a default value here.
        text_func_off           dw ?
        label_off               dw 0FFFFh
ends ui_slider

struc ui_tickbox
        window_off              dw 0FFFFh
        prev_component_off      dw 0FFFFh
        next_component_off      dw 0FFFFh
        ui_type                 ui_type_t UI_TICKBOX_NUM
        value                   db 0
        width                   db 0FFh         ; 0FFh: use window's default
                                                ; must be odd
        label_off               dw 0FFFFh
ends ui_tickbox

; --------------------------------------------------------------------------
; Function: window_switch_cur
; Description: Switch the current component of the window. Nothing will happen
;              if attempting to switch to the previous component of the first
;              one, or to switch to the next component of the last one.
; Input:  Argument 1 (word): The offset of the window object.
;         Argument 2 (word): Use 0 to switch to the previous component, 1 to
;                            switch to the next component.
; Output: None
; --------------------------------------------------------------------------
proc window_switch_cur near
arg @@window_off:word, @@direction:word
        push    bx di
        mov     bx, [@@window_off]

        mov     di, [bx + ui_window.cur_component_off]
        cmp     di, 0FFFFh
        je      @@return

        cmp     [@@direction], 0
        jne     @@next_component
        mov     di, [di + ui_slider.prev_component_off]
        cmp     di, 0FFFFh
        je      @@return
        mov     [bx + ui_window.cur_component_off], di
        jmp     @@return
@@next_component:
        mov     di, [di + ui_slider.next_component_off]
        cmp     di, 0FFFFh
        je      @@return
        mov     [bx + ui_window.cur_component_off], di

@@return:
        pop     di bx
        ret
endp window_switch_cur

; --------------------------------------------------------------------------
; Function: slider_change_value
; Description: Change the current value of the slider. Nothing will happen if
;              attempting to go out of bounds.
; Input:  Argument 1 (word): The offset of the slider object.
;         Argument 2 (word): Use 0 to go less, 1 to go greater.
; Output: None
; --------------------------------------------------------------------------
proc slider_change_value near
arg @@slider_off:word, @@direction:word
        push    bx
        push    eax
        mov     bx, [@@slider_off]

        mov     eax, [bx + ui_slider.value]
        cmp     [@@direction], 0
        jne     @@go_greater
        cmp     eax, [bx + ui_slider.min_value]
        je      @@return
        sub     eax, [bx + ui_slider.step]
        mov     [bx + ui_slider.value], eax
        jmp     @@return
@@go_greater:
        cmp     eax, [bx + ui_slider.max_value]
        je      @@return
        add     eax, [bx + ui_slider.step]
        mov     [bx + ui_slider.value], eax

@@return:
        pop     eax
        pop     bx
        ret
endp slider_change_value

; --------------------------------------------------------------------------
; Function: window_insert_component
; Description: Insert a UI component to the window.
; Input:  Argument 1 (word): The offset of the window object.
;         Argument 2 (word): The offset of the UI component object in the
;                            linked list to be injected after. 0FFFFh means
;                            insert to the begin of the list.
;         Argument 3 (word): The offset of the UI component object to be
;                            injected
; Output: None
; --------------------------------------------------------------------------
proc window_insert_component near
arg @@window_off:word, @@pos_off:word, @@component_off:word
        push    bx di si ax ds
        mov     ax, cs
        mov     ds, ax

        ; Insert the component to the component linked list of the window
        mov     bx, [@@window_off]
        mov     di, [@@component_off]
        mov     [di + ui_slider.window_off], bx
        cmp     [@@pos_off], 0FFFFh
        jne     @@insert_after_an_object
        ;   Insert to the begin of the list
        mov     [di + ui_slider.prev_component_off], 0FFFFh
        mov     si, [bx + ui_window.first_component_off]
        mov     [di + ui_slider.next_component_off], si
        mov     [bx + ui_window.first_component_off], di
        cmp     si, 0FFFFh
        je      @@L1
        mov     [si + ui_slider.prev_component_off], di
        jmp     @@L3
@@L1:
        mov     [bx + ui_window.cur_component_off], di
@@L3:
        jmp     @@end_of_inserting
@@insert_after_an_object:
        mov     si, [@@pos_off]
        mov     si, [si + ui_slider.next_component_off]
        mov     [di + ui_slider.next_component_off], si
        cmp     si, 0FFFFh
        je      @@L2
        mov     [si + ui_slider.prev_component_off], di
@@L2:
        mov     si, [@@pos_off]
        mov     [si + ui_slider.next_component_off], di
        mov     [di + ui_slider.prev_component_off], si
@@end_of_inserting:

        pop     ds ax si di bx
        ret
endp window_insert_component

; --------------------------------------------------------------------------
; Function: draw_window
; Description: Draw a window to the screen.
; Input:  Argument 1 (word): The offset of the window object.
; Output: None
; --------------------------------------------------------------------------
proc draw_window near
arg @@window_off:word
        push    ax si di
        mov     si, [@@window_off]

        mov     [word ptr si + ui_window.cur_drawing_x], 0101h

        ; Print the outer frame
        push    TEXT_WHITE
        mov     al, [si + ui_window.height]
        cbw
        push    ax
        mov     al, [si + ui_window.width]
        cbw
        push    ax
        mov     al, [si + ui_window.top_left_y]
        cbw
        push    ax
        mov     al, [si + ui_window.top_left_x]
        cbw
        push    ax
        call    print_frame
        add     sp, 10

        ; Draw the components according to their type
        mov     di, [si + ui_window.first_component_off]
@@draw_components_loop:
        cmp     di, 0FFFFh
        je      @@draw_components_loop_break
        cmp     [di + ui_slider.ui_type], UI_SLIDER_NUM
        je      @@draw_slider
        cmp     [di + ui_slider.ui_type], UI_TICKBOX_NUM
        je      @@draw_tickbox
        jmp     @@draw_nothing
@@draw_slider:
        ; The bytes cur_drawing_x and cur_drawing_y are placed next to each
        ; other, so the offset cur_drawing_x can also be treated as a packed
        ; word containing X and Y coordinate.
        mov     ax, [word ptr si + ui_window.cur_drawing_x]
        add     ax, [word ptr si + ui_window.top_left_x]
        push    ax
        xor     ax, ax
        cmp     di, [word ptr si + ui_window.cur_component_off]
        jne     @@L1
        inc     ax
@@L1:
        push    ax di
        call    draw_slider
        add     sp, 6
        inc     [byte ptr si + ui_window.cur_drawing_y]
        jmp     @@draw_end
@@draw_tickbox:
        mov     ax, [word ptr si + ui_window.cur_drawing_x]
        add     ax, [word ptr si + ui_window.top_left_x]
        push    ax
        cmp     di, [word ptr si + ui_window.cur_component_off]
        setz    al
        cbw
        push    ax di
        call    draw_tickbox
        add     sp, 6
        inc     [byte ptr si + ui_window.cur_drawing_y]
        jmp     @@draw_end
@@draw_nothing:
@@draw_end:
        mov     di, [di + ui_slider.next_component_off]
        jmp     @@draw_components_loop
@@draw_components_loop_break:

        pop     di si ax
        ret
endp draw_window

; --------------------------------------------------------------------------
; Function: dword_to_dec
; Description: Print a dword as an unsigned decimal to a static string.
; Input:  Argument 1 (dword): The dword to print.
; Output (in AX): The offset of the static string. Note that the return value
;                 won't always be the same.
; --------------------------------------------------------------------------
proc dword_to_dec near
arg @@num:dword
        push    ds di
        push    eax ebx edx

        mov     ax, cs
        mov     ds, ax
        xor     edx, edx        ; edx = 0
        mov     ax, 10
        cwd
        xchg    eax, ebx        ; ebx = 10
        mov     ax, [word ptr @@num + 2]
        shl     eax, 16
        mov     ax, [word ptr @@num]   ; eax = in
        mov     di, (offset dword_to_dec_str + 9)
@@L1:
        xor     edx, edx
        div     ebx             ; eax = eax / 10, edx = eax % 10
        add     dx, '0'
        mov     [byte ptr ds:di], dl
        dec     di
        test    eax, eax
        jnz     @@L1
        inc     di

        pop     edx ebx eax
        mov     ax, di
        pop     di ds
        ret
endp dword_to_dec

; --------------------------------------------------------------------------
; Function: draw_slider
; Description: Draw a slider onto the screen. Its components are:
;                        <-    value    ->    Label
;               width:  | 2 |  width  | 2 | 1 + strlen(label)
; The characters <- and -> are actually JIS 0x222B and 0x222A, respectively.
; There is a halfwidth space between the character '->' and the content of the
; label. The character '<-' ('->') will not be displayed if the value can't go
; lower (greater). These characters, if displayed, will have a color of aqua
; when not highlighted, and yellow when highlighted.
;
; The bottom indicator (of width 2) is implemented by giving the underline
; attribute to an interval of the characters in the 'value' part. The underline
; below a character always has a 1/4-width offset to the right (see the figure
; below), so the characters must align to the fullwidth boundary, if the value
; string can have half-width characters.
;                         AA              AAaa
;                          --              ----
;       Figure. Illustration of the underline attribute given to the
;       halfwidth and fullwidth characters. 'AA' represents halfwidth
;       character 'A', and 'AAaa' represents a hypothetical fullwidth
;                               character A
;
; Input:  Argument 1 (word): The offset of the slider object.
;         Argument 2 (word): Whether the slider is highlighted.
;         Argument 3 (word): The lower byte is the X coordinate of the top-left
;                            corner, and the upper byte is its Y coordinate.
; Output (in AX): The lower byte is the X coordinate of the bottom-right
;                 corner, and the upper byte is its Y coordinate.
; --------------------------------------------------------------------------
proc draw_slider near
arg @@slider_off:word, @@highlighted:word, @@top_left_x_y:word
local @@value_str_off:word, @@return_value:word, @@width:word
        push    ds es di bx si
        push    eax ecx edx
        mov     ax, cs
        mov     ds, ax
        mov     bx, [@@slider_off]

        mov     al, [bx + ui_slider.width]
        cmp     al, 0FFh
        jne     @@L10
        mov     di, [bx + ui_slider.window_off]
        mov     al, [di + ui_window.default_slider_width]
@@L10:
        mov     [byte ptr @@width], al

        ; Print '<-'
        mov     al, [byte ptr @@top_left_x_y + 1]
        cbw
        imul    dx, ax, 80
        mov     al, [byte ptr @@top_left_x_y]
        cbw
        add     dx, ax
        shl     dx, 1
        mov     di, dx
        mov     ax, TRAM_SEG
        mov     es, ax
        mov     ax, [word ptr bx + ui_slider.value]
        cmp     ax, [word ptr bx + ui_slider.min_value]
        je      @@L1
        mov     [word ptr es:di], 2B02h
        mov     [word ptr es:di + 2], 2B62h
        jmp     @@L2
@@L1:
        mov     [word ptr es:di], 0020h
        mov     [word ptr es:di + 2], 0020h
@@L2:
        mov     ax, TRAM_ATTR_SEG
        mov     es, ax
        mov     al, TEXT_AQUA
        cmp     [@@highlighted], 1
        jne     @@L3
        mov     al, TEXT_YELLOW
@@L3:
        mov     [byte ptr es:di], al
        mov     [byte ptr es:di + 2], al

        ; Print '->'
        add     di, 4
        push    di                              ; push offset of the value part
        mov     al, [byte ptr @@width]
        cbw
        add     di, ax
        add     di, ax
        mov     ax, TRAM_SEG
        mov     es, ax
        mov     ax, [word ptr bx + ui_slider.value]
        cmp     ax, [word ptr bx + ui_slider.max_value]
        je      @@L4
        mov     [word ptr es:di], 2A02h
        mov     [word ptr es:di + 2], 2A62h
        jmp     @@L5
@@L4:
        mov     [word ptr es:di], 0020h
        mov     [word ptr es:di + 2], 0020h
@@L5:
        mov     ax, TRAM_ATTR_SEG
        mov     es, ax
        mov     al, TEXT_AQUA
        cmp     [@@highlighted], 1
        jne     @@L6
        mov     al, TEXT_YELLOW
@@L6:
        mov     [byte ptr es:di], al
        mov     [byte ptr es:di + 2], al

        ; Print the space before the label
        add     di, 4
        mov     [byte ptr es:di], TEXT_WHITE
        mov     ax, TRAM_SEG
        mov     es, ax
        mov     [word ptr es:di], 0020h

        ; Print the label
        push    bx
        push    TEXT_WHITE
        mov     al, [byte ptr @@top_left_x_y + 1]
        cbw
        push    ax
        mov     al, [byte ptr @@top_left_x_y]
        add     al, 5
        add     al, [byte ptr @@width]
        cbw
        push    ax
        push    ds
        push    [bx + ui_slider.label_off]
        call    print_str
        add     sp, 10
        pop     bx

        ; Initialize the 'value' part
        pop     di      ; pop the offset of 'value' part on TRAM
        mov     ax, TRAM_SEG
        mov     es, ax
        mov     ax, 0020h
        mov     cl, [byte ptr @@width]
        xor     ch, ch
        cld
        rep stosw
        mov     ax, TRAM_ATTR_SEG
        mov     es, ax
        mov     ax, TEXT_AQUA
        cmp     [word ptr @@highlighted], 0
        je      @@L7
        mov     ax, TEXT_YELLOW
@@L7:
        mov     cl, [byte ptr @@width]
        xor     ch, ch
        sub     di, 2
        std
        rep stosw
        cld
        add     di, 2   ; now di is back to the offset of the 'value' part
        push    di

        ; Calculate the length of the value string
        push    [word ptr (bx + ui_slider.value) + 2]
        push    [word ptr bx + ui_slider.value]
        call    [word ptr bx + ui_slider.text_func_off]
        add     sp, 4
        mov     [@@value_str_off], ax
        mov     si, ax
        xor     dx, dx
@@value_str_chk_len_loop:
        cmp     [byte ptr si], 0
        je      @@value_str_chk_len_loop_break
        inc     si
        inc     dx
        jmp     @@value_str_chk_len_loop
@@value_str_chk_len_loop_break:                 ; dx = strlen(value_str_off)

        ; Print the value string. Note that this method only works for purely
        ; half-width strings.
        mov     al, [byte ptr @@width]
        cbw
        sub     ax, dx
        add     ax, 1
        and     ax, 0FFFEh
        add     di, ax          ; the offset of the string on TRAM
        mov     ax, TRAM_SEG
        mov     es, ax
        mov     si, [@@value_str_off]
@@print_value_str_loop:
        mov     al, [byte ptr si]
        test    al, al
        jz      @@print_value_str_loop_break
        cbw
        mov     [word ptr es:di], ax
        add     di, 2
        inc     si
        jmp     @@print_value_str_loop
@@print_value_str_loop_break:

        ; Calculate the position of the indicator. The position varies from 0
        ; to (width - 2), so the position of the indicator will be
        ; round((value - min) / (max - min) * (width - 2)), i.e.
        ;                   2 * (value - min) * (width - 2) + 1
        ;            floor( ----------------------------------- ).          (*)
        ;                              2 * (max - min)
        cmp     [bx + ui_slider.bottom_indicator], 0
        je      @@skip_indicator_handling
        mov     al, [byte ptr @@width]
        cbw
        sub     ax, 2
        shl     ax, 1
        cwd
        xchg    ecx, eax        ; ecx = 2 * (width - 2)
        mov     eax, [bx + ui_slider.value]
        sub     eax, [bx + ui_slider.min_value]
        mul     ecx             ; edx:eax = 2 * (value - min) * (width - 2)
        inc     eax
        cmp     eax, 0
        jne     @@L8
        inc     edx
@@L8:                           ; edx:eax = 2 * (value - min) * (width - 2) + 1
        mov     ecx, [bx + ui_slider.max_value]
        sub     ecx, [bx + ui_slider.min_value]
        shl     ecx, 1          ; ecx = 2 * (max - min)
        div     ecx             ; edx:eax = (*)
        pop     di              ; offset of the 'value' part on TRAM
        add     di, ax
        add     di, ax
        mov     ax, TRAM_ATTR_SEG
        mov     es, ax
        mov     al, [byte ptr es:di]
        or      al, TEXT_UNDERLINE_MASK
        mov     [byte ptr es:di], al
        mov     [byte ptr es:di + 2], al
        jmp     @@L9
@@skip_indicator_handling:
        pop     di             ; pop the unused offset of TRAM here
@@L9:

        ; Prepare the return value
        mov     ax, [@@top_left_x_y]
        add     ah, 5
        add     ah, [byte ptr bx + ui_slider.width]
        mov     di, [bx + ui_slider.label_off]
@@label_chk_len_loop:
        cmp     [byte ptr di], 0
        je      @@label_chk_len_loop_break
        inc     di
        inc     ah
        jmp     @@label_chk_len_loop
@@label_chk_len_loop_break:
        mov     [@@return_value], ax

        pop     edx ecx eax
        mov     ax, [@@return_value]
        pop     si bx di es ds
        ret
endp draw_slider

; --------------------------------------------------------------------------
; Function: draw_tickbox
; Description: Draw a tickbox onto the screen. Its components are:
;                        [ ]  Label
;               width:  | 3 | 1 + strlen(label)
; Input:  Argument 1 (word): The offset of the tickbox object.
;         Argument 2 (word): Whether the tickbox is highlighted.
;         Argument 3 (word): The lower byte is the X coordinate of the top-left
;                            corner, and the upper byte is its Y coordinate.
; Output (in AX): The lower byte is the X coordinate of the bottom-right
;                 corner, and the upper byte is its Y coordinate.
; --------------------------------------------------------------------------
proc draw_tickbox near
arg @@tickbox_off:word, @@highlighted:word, @@packed_coord:word
local @@bracket_str:byte:5, @@cur_x:word, @@cur_y:word
        push    si
        mov     si, [@@tickbox_off]

        xor     ax, ax
        mov     [@@cur_x], ax
        mov     [@@cur_y], ax

        ; Print the bracket
        mov     [word ptr @@bracket_str], ' ['
        mov     [word ptr @@bracket_str + 2], ' ]'
        mov     [byte ptr @@bracket_str + 4], 0
        test    [byte ptr si + ui_tickbox.value], 1
        jz      @@skip_adding_cross
        mov     [byte ptr @@bracket_str + 1], 'X'
@@skip_adding_cross:
        mov     ax, TEXT_AQUA
        cmp     [word ptr @@highlighted], 1
        jne     @@skip_setting_color_to_yellow
        mov     ax, TEXT_YELLOW
@@skip_setting_color_to_yellow:
        mov     cx, [@@packed_coord]
        mov     [byte ptr @@cur_x], cl
        mov     [byte ptr @@cur_y], ch
        lea     cx, [@@bracket_str]
        push    ax [word ptr @@cur_y] [word ptr @@cur_x] ss cx
        call    print_str
        add     sp, 10

        ; Print the label
        add     [word ptr @@cur_x], 4
        push    TEXT_WHITE [word ptr @@cur_y] [word ptr @@cur_x]
        push    ds [word ptr si + ui_tickbox.label_off]
        call    print_str
        add     sp, 10

        ; Prepare return value
        push    ds [word ptr si + ui_tickbox.label_off]
        call    string_length
        add     sp, 4
        add     al, [byte ptr @@cur_x]
        add     al, 4
        mov     ah, [byte ptr @@cur_y]

        pop     si
        ret
endp draw_tickbox

; --------------------------------------------------------------------------
; Function: draw_background_shadow
; Description: Draw a shadow color on every VRAM plane in a rectangular region.
; Input:  Argument 1 (word): The X coordinate of the top left corner / 8.
;         Argument 2 (word): The Y coordinate of the top left corner.
;         Argument 3 (word): The width of the region / 8.
;         Argument 4 (word): The height of the region.
; Output: None
; --------------------------------------------------------------------------
proc draw_background_shadow near
arg @@top_left_x:word, @@top_left_y:word, @@width:word, @@height:word
local @@vram_seg_arr:dword
        push    es bx ax si di

        xor     di, di
@@vram_plane_loop:
        mov     ah, [cs:di + vram_seg_arr]
        xor     al, al
        mov     es, ax
        xor     si, si
@@draw_lines_loop:
        cmp     si, [@@height]
        je      @@draw_lines_loop_break
        mov     bx, [@@top_left_y]
        add     bx, si
        imul    bx, bx, 50h
        add     bx, [@@top_left_x]
        xor     cx, cx
@@draw_a_line_loop:
        cmp     cx, [@@width]
        je      @@draw_a_line_loop_break
        mov     al, 0AAh
        test    si, 01h
        jz      @@L1
        mov     al, 000h
@@L1:
        and     [byte ptr es:bx], al
        inc     bx
        inc     cx
        jmp     @@draw_a_line_loop
@@draw_a_line_loop_break:
        inc     si
        jmp     @@draw_lines_loop
@@draw_lines_loop_break:
        inc     di
        cmp     di, 4
        jne     @@vram_plane_loop

        pop     di si ax bx es
        ret
endp draw_background_shadow

popstate
