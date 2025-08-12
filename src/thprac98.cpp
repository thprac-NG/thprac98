#include <stdio.h>

#include "master.h"

#include "src/utils.hpp"
#include "src/menu.hpp"

volatile bool main_loop_end = false;
const int MAIN_LOOP_CYCLE = 2;   // unit: *10ms
void main_loop() {
  // Reduce the usage of key_scan.
  if (is_pressed(KEY_Q_TA)) {
    main_loop_end = true;
    return;
  }
}

int main() {
  // text_putca(3, 3, 0x8c, TX_CYAN);
  // return 0;

  launcher_menu_init();
  timer_start(MAIN_LOOP_CYCLE, main_loop);
  while (main_loop_end == false) {}
  timer_end();
  launcher_menu_clear();
  return 0;
}