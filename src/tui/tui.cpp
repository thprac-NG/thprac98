#include "src/tui/tui.hpp"

#include "src/utils.hpp"

int tui::screen_height;
int tui::screen_width;

void tui::init(void) {
  tui::screen_height = 25;
  tui::screen_width = 80;
  return;
}
