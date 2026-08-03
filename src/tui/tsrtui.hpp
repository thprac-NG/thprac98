#ifndef THPRAC98_SRC_TUI_TSRTUI_HPP_
#define THPRAC98_SRC_TUI_TSRTUI_HPP_

#include "mystdlib/stdbool.hpp"

struct ui_window {
  unsigned char top_left_x;
  unsigned char top_left_y;
  unsigned char width;
  unsigned char height;
  void near* first_component_off;
  void near* tail_component_off;
  void near* cur_component_off;
  unsigned char default_slider_width;
  unsigned char cur_drawing_x;
  unsigned char cur_drawing_y;

  ui_window() {
    top_left_x = 0;
    top_left_y = 0;
    width = 2;
    height = 2;
    first_component_off = (void near*)(0xFFFFu);
    tail_component_off = (void near*)(0xFFFFu);
    cur_component_off = (void near*)(0xFFFFu);
    default_slider_width = 0;
    cur_drawing_x = 1;
    cur_drawing_y = 1;
    return;
  }
};

enum ui_type_t { UI_SLIDER_NUM = 0 };

struct ui_slider {
  ui_window near* window_off;
  void near* prev_component_off;
  void near* next_component_off;
  ui_type_t ui_type;
  unsigned long value;
  unsigned long min_value;
  unsigned long max_value;
  unsigned long step;
  bool bottom_indicator;
  unsigned char width = 0xFF;
  const char near* (*near text_func_off)(unsigned long);
  char near* label_off;

  ui_slider() {
    window_off = (ui_window near*)(0xFFFFu);
    prev_component_off = (void near*)(0xFFFFu);
    next_component_off = (void near*)(0xFFFFu);
    ui_type = UI_SLIDER_NUM;
    value = 0;
    min_value = 0;
    max_value = 0;
    step = 1;
    bottom_indicator = true;
    width = 0xFF;
    label_off = (char near*)(0xFFFFu);
  }
};

void near window_switch_cur(ui_window near* window, bool16 direction);
void near slider_change_value(ui_slider near* slider, bool16 direction);
void near window_insert_component(ui_window near* window, void near* pos,
                                  void near* component);
void near draw_window(ui_window near* window);
unsigned near draw_slider(ui_slider near* slider, bool16 highlighted,
                          unsigned top_left);
void near draw_background_shadow(unsigned top_left_x, unsigned top_left_y,
                                 unsigned width, unsigned height);

#endif THPRAC98_SRC_TUI_TSRTUI_HPP_  // #ifndef THPRAC98_SRC_TUI_TSRTUI_HPP_
