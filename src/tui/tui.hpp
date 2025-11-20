#ifndef THPRAC98_SRC_TUI_TUI_HPP_
#define THPRAC98_SRC_TUI_TUI_HPP_

#include "src/tui/chars.hpp"
#include "src/utils.hpp"


/**
 * @brief Controlling class tui (Text-based User Interface).
 * Turbo C++ didn't support namespaces, so here's a workaround.
 * The class can be treated as a basic reimplementation of ImGui.
 */
class tui {
 private:
  static int screen_width;
  static int screen_height;

 public:
  /**
   * @brief Initialize some variables in tui. Must be called before any other
   * tui functions.
   */
  static void init(void);

  enum window_flags_t {
    DEFAULT_WINDOW_FLAG = 0x00,
    NO_WINDOW_SCROLLBAR = 0x01
  };
  /**
   * @brief Push a new window to put widgets on. Similiar to ImGui::Begin.
   * After putting all the widgets on the window, make sure to call end_window.
   * @details Refer to set_next_window_pos and set_next_window_size for
   * configuration.
   *
   * @param name A unique identifier for the window
   * @param window_flags The flags for the windows, see window_flags_t
   * @return false if the window is collapsed, true otherwise
   */
  static bool begin_window(const char* name, window_flags_t window_flags);
  /**
   * @brief End the window just pushed. Similiar to ImGui::End.
   */
  static void end_window();

  /**
   * @brief Set the position of the window created by the next begin_window.
   *
   * @param x Horizontal coordinate of the top-left corner. 0 is the leftmost.
   * @param y Vertical coordinate of the top-left corner. 0 is the topmost.
   */
  static bool set_next_window_pos(unsigned x, unsigned y);
  /**
   * @brief Set the size of the window created by the next begin_window.
   *
   * @param x Horizontal coordinate of the top-left corner. 0 is the leftmost.
   * @param y Vertical coordinate of the top-left corner. 0 is the topmost.
   */
  static bool set_next_window_size(unsigned width, unsigned height);

  class widget_t {};
};

#endif  // #ifndef THPRAC98_SRC_TUI_TUI_HPP_