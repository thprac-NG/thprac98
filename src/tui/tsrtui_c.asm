; The linkable assembly source file for tsrtui.asm
ideal
model small, cpp
radix 10
locals
stack 100h
p386

dataseg
include "..\src\tui\tsrtuidt.asm"

codeseg
        public window_switch_cur
        public slider_change_value
        public window_insert_component
        public draw_window
        public draw_slider
        public draw_background_shadow

        public _window_switch_cur
        public _slider_change_value
        public _window_insert_component
        public _draw_window
        public _draw_slider
        public _draw_background_shadow

proc _window_switch_cur near
        jmp     window_switch_cur
endp _window_switch_cur
proc _slider_change_value near
        jmp     slider_change_value
endp _slider_change_value
proc _window_insert_component near
        jmp     window_insert_component
endp _window_insert_component
proc _draw_window near
        jmp     draw_window
endp _draw_window
proc _draw_slider near
        jmp     draw_slider
endp _draw_slider
proc _draw_background_shadow near
        jmp     draw_background_shadow
endp _draw_background_shadow

include "..\src\tui\tsrtui.asm"

end
