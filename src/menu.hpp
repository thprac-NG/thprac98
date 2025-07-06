#ifndef THPRAC98_SRC_MENU_HPP_
#define THPRAC98_SRC_MENU_HPP_

#include "master.h"

#include "src/utils.hpp"
#include "src/texts.hpp"

enum launcher_page_t {
  LAUNCHER_GAME_LIST,
  LAUNCHER_GAME_INFO,
  LAUNCHER_GAME_SCAN,
  LAUNCHER_LINKS
};
extern launcher_page_t launcher_page;

/**
 * @brief Initialize the thprac launcher menu. Won't work in PC-98 high-
 * resolution mode.
 */
void launcher_menu_init(void);

/**
 * @brief Clear the thprac launcher menu. Only works in 98 Normal mode.
 */
void launcher_menu_clear(void);

/**
 * @brief Render the current page.
 */
void render_page(void);

#endif  // #ifndef THPRAC98_SRC_MENU_HPP_