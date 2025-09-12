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

struct menu_t {
  launcher_page_t launcher_page;
  int which_game_info;
};
extern menu_t menu;

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
 * @brief Init the aqua border and the bottom line.
 *
 */
void init_border(void);

/**
 * @brief Render the current page.
 */
void render_page(void);

/**
 * @brief Print a table to TRAM using full-width box-drawing characters.
 * The outer outline will be bold.
 *
 * @details All coordinates should be has an X value in [0,79] and a Y value
 * in [0,24]. The width should >= 3 and the height should >= 2. For vertical
 * lines (including the bold border), adjacant lines (i.e. with adjacant X
 * coordinates) aren't allowed.
 *
 * @param x_min The minimum of X coordinate of the table.
 * @param y_min The minimum of Y coordinate of the table.
 * @param x_max The maximum of X coordinate of the table.
 * @param y_max The maximum of Y coordinate of the table.
 * @param vertical_line_num The number of extra vertical thin lines.
 * @param vertical_line_xs The address of array storing the X coordinates of
 *        the vertical lines. Won't touch if vertical_line_num is 0. Since a
 *        vertical line has a width of 2, the X coordinate here stands for the
 *        smaller one of the two half-width X coordinates.
 * @param horizontal_line_num The number of extra horizontal thin lines.
 * @param horizontal_line_xs The address of array storing the Y coordinates of
 *        the horizontal lines. Won't touch if horizontal_line_num is 0.
 * @param attribute The attribute that will be sent to master.lib.
 *
 * @return 0 if success, non-zero if failed.
 */
int print_table(int x_min, int y_min, int x_max, int y_max,
                int vertical_line_num, const int* vertical_line_xs,
                int horizontal_line_num, const int* horizontal_line_ys,
                int attribute);

#endif  // #ifndef THPRAC98_SRC_MENU_HPP_