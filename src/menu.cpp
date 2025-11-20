#include "src/menu.hpp"

#include <stdio.h>
#include <string.h>  // memset

#include "src/texts.hpp"
#include "src/utils.hpp"


menu_t menu;

void launcher_menu_init(void) {
  // Initialize system stuff
  printf("\x1B[>5h");  // Clears the function key line
  text_25line();
  text_systemline_hide();
  text_cursor_hide();

  init_border();
  menu.launcher_page = LAUNCHER_GAME_LIST;
  render_page();
  return;
}

void launcher_menu_clear(void) {
  text_clear();
  text_systemline_show();
  text_cursor_show();
  printf("\x1B[>5l");  // Shows the function key line
  return;
}

void init_border(void) {
  int i = 0;
  // Initialize character attribute
  text_fillca(' ', TX_WHITE);
  // Title
  text_putsa(2, 1, S(THPRAC_LAUNCHER_TITLE), TX_CYAN);
  // System Line
  for (i = 0; i < 4; ++i) {
    text_putsa(4 + i * 7, 24, S(THPRAC_FX_MENUS[i]), TX_WHITE | TX_REVERSE);
  }
  return;
}

int print_table(int x_min, int y_min, int x_max, int y_max,
                int vertical_line_num, const int* vertical_line_xs,
                int horizontal_line_num, const int* horizontal_line_ys,
                int attribute) {
  int i = 0, j = 0;
  if (!(0 <= x_min && x_min < SCREEN_WIDTH && 0 <= x_max &&
        x_max < SCREEN_WIDTH && x_min + 2 < x_max)) {
    return 1;
  }
  if (!(0 <= y_min && y_min < SCREEN_HEIGHT && 0 <= y_max &&
        y_max < SCREEN_HEIGHT && y_min < y_max)) {
    return 2;
  }
  class helper_t {
   public:
    uint16 x_bucket[5];
    uint32 y_bucket;
    inline void init() {
      memset(x_bucket, 0x00, sizeof(x_bucket));
      y_bucket = 0;
      return;
    }
    helper_t() {
      init();
      return;
    }
    inline void register_x(int x) {
      x_bucket[x >> 4] |= 1u << (x & 0xF);
      return;
    }
    inline void register_y(int y) {
      y_bucket |= 1ul << y;
      return;
    }
    inline bool check_x(int x) { return (x_bucket[x >> 4] >> (x & 0xF)) & 1; }
    inline bool check_y(int y) { return (y_bucket >> y) & 1; }
  };
  static helper_t helper;
  helper.init();

  helper.register_x(x_min);
  helper.register_x(x_max - 1);
  int tmp = 0;
  for (i = 0; i < vertical_line_num; ++i) {
    tmp = vertical_line_xs[i];
    if (!(x_min + 1 < tmp && tmp + 1 < x_max)) {
      return 3;
    }
    if (helper.check_x(tmp)) {
      return 4;
    }
    if (tmp != 0 && helper.check_x(tmp - 1)) {
      return 5;
    }
    if (tmp != SCREEN_WIDTH - 1 && helper.check_x(tmp + 1)) {
      return 6;
    }
    helper.register_x(tmp);
  }
  helper.register_y(y_min);
  helper.register_y(y_max);
  for (i = 0; i < horizontal_line_num; ++i) {
    tmp = horizontal_line_ys[i];
    if (!(y_min < tmp && tmp < y_max)) {
      return 7;
    }
    if (helper.check_y(tmp)) {
      return 8;
    }
    helper.register_y(tmp);
  }

  // Draw the outer outline
  text_putca(x_min, y_min, 0x86B1, attribute);  // „¬
  for (i = x_min + 2; i <= x_max - 2; i += 2) {
    text_putca(i, y_min, 0x86A3, attribute);  // „ª
  }
  text_putca(x_max - 1, y_min, 0x86B5, attribute);  // „­
  for (i = y_min + 1; i < y_max; ++i) {
    text_putca(x_min, i, 0x86A5, attribute);      // „«
    text_putca(x_max - 1, i, 0x86A5, attribute);  // „«
  }
  text_putca(x_min, y_max, 0x86B9, attribute);  // „¯
  for (i = x_min + 2; i <= x_max - 2; i += 2) {
    text_putca(i, y_max, 0x86A3, attribute);  // „ª
  }
  text_putca(x_max - 1, y_max, 0x86BD, attribute);  // „®

  // Draw the inner thin lines
  for (i = y_min + 1; i <= y_max - 1; ++i) {
    if (!helper.check_y(i)) {
      continue;
    }
    text_putca(x_min, i, 0x86C2, attribute);  // „µ
    for (j = x_min + 2; j <= x_max - 1; j += 2) {
      text_putca(j, i, 0x86A2, attribute);  // „Ÿ
    }
    text_putca(x_max - 1, i, 0x86CA, attribute);  // „·
  }
  for (i = x_min + 2; i <= x_max - 2; ++i) {
    if (!helper.check_x(i)) {
      continue;
    }
    text_putca(i, y_min, 0x86D1, attribute);  // „¶
    for (j = y_min + 1; j <= y_max - 1; ++j) {
      if (helper.check_y(j)) {
        text_putca(i, j, 0x86DE, attribute);  // „©
      } else {
        text_putca(i, j, 0x86A4, attribute);  // „ 
      }
    }
    text_putca(i, y_max, 0x86D9, attribute);  // „¸
  }
  return 0;
}

void render_page(void) {
  int i = 0;
  switch (menu.launcher_page) {
    case LAUNCHER_GAME_LIST: {
      for (i = 0; i < 5; ++i) {
        text_putca(2, 3 + i * 2, '1' + i, TX_YELLOW);
        text_putsa(4, 3 + i * 2, S(THPRAC_GAME_TITLES[i]), TX_WHITE);
      }
      break;
    }
    case LAUNCHER_GAME_INFO: {
    }
  }
}