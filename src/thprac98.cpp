#include <stdio.h>

#include "master.h"

#include "src/utils.hpp"
#include "src/menu.hpp"

int main() {
  // text_putca(3, 3, 0x8c, TX_CYAN);
  // return 0;

  launcher_menu_init();
  while (1) {  // main loop
    if (is_pressed(KEY_Q_TA)) {
      puts("Key Q pressed. Exiting.");
      break;
    }
  }
  launcher_menu_clear();
  return 0;
}