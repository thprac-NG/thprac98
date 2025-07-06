#include "src/menu.hpp"

#include "src/texts.hpp"
#include "src/utils.hpp"

#include <stdio.h>

launcher_page_t launcher_page = LAUNCHER_GAME_LIST;

void launcher_menu_init(void) {
  int i = 0, j = 0;

  // Initialize system stuff
  text_25line();
  text_systemline_hide();
  text_cursor_hide();

  // Initialize character attribute
  text_fillca(' ', TX_WHITE);
  
  // Initialize the border. The 'normal' box-drawing characters that are used in 
  // today's Shift-JIS encoding (JIS code 0x2820 ~ 0x284F), according to the 
  // PC-9801 Programmer's Bible, page 538, don't exist in PC-98s. Thus, I have 
  // to use the 'full-width' box-drawing characters (JIS code 0x2C20 ~ 0x2C6F)  
  // here. This also means that I can't use the single-quoted characters in this 
  // code, which produced Shift-JIS code corresponding to the former ones.
  
  const int border_width = 80, border_height = 25;
  text_putca(0, 0, 0x2c33, TX_CYAN);  // „¬ (full-width)
  for (i = 2; i < border_width - 2; i += 2) {
    text_putca(i, 0, 0x2c25, TX_CYAN);  // „ª
  }
  text_putca(border_width - 2, 0, 0x2c37, TX_CYAN);  // „­
  for (i = 1; i < border_height - 2; i++) {
    if (i != 2) {
      text_putca(0, i, 0x2c27, TX_CYAN);  // „«
      text_putca(border_width - 2, i, 0x2c27, TX_CYAN);  // „«
    } else {  // print a thin line in line 2
      text_putca(0, i, 0x2c44, TX_CYAN);  // „µ
      for (j = 2; j < border_width - 2; j += 2) {
        text_putca(j, i, 0x2c24, TX_CYAN);  // „Ÿ
      }
      text_putca(border_width - 2, i, 0x2c4c, TX_CYAN); // „·
    }
  }
  text_putca(0, border_height - 2, 0x2c3b, TX_CYAN);  // „¯
  for (i = 2; i <= border_width - 2; i += 2) {
    text_putca(i, border_height - 2, 0x2c25, TX_CYAN);  // „ª
  }
  text_putca(border_width - 2, border_height - 2, 0x2c3f, TX_CYAN);  // „®

  // Title
  text_putsa(2, 1, S(THPRAC_LAUNCHER_TITLE), TX_CYAN);

  // System Line
  for (i = 0; i < 4; ++i) {
    text_putsa(4 + i * 7, border_height - 1, S(THPRAC_FX_MENUS[i]),
               TX_WHITE | TX_REVERSE);
  }

  render_page();
  return;
}

void launcher_menu_clear(void) {
  text_clear();
  text_systemline_show();
  text_cursor_show();
  return;
}

void render_page(void) {
  int i = 0;
  switch (launcher_page) {
    case LAUNCHER_GAME_LIST:
      for (i = 0; i < 5; ++i) {
        text_putca(2, 3 + i * 2, '1' + i, TX_YELLOW);
        text_putsa(4, 3 + i * 2, S(THPRAC_GAME_TITLES[i]), TX_WHITE);
      }
  }
}