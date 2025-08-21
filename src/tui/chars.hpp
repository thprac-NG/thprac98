#ifndef THPRAC98_SRC_TUI_CHARS_HPP_
#define THPRAC98_SRC_TUI_CHARS_HPP_

#include "src/utils.hpp"

// Bitmap enum for function box_drawing
enum box_drawing_t {
  BD_LEFT = 0x01,
  BD_RIGHT = 0x02,
  BD_HORIZONTAL = 0x03,
  BD_UP = 0x04,
  BD_DOWN = 0x08,
  BD_VERTICAL = 0x0C,
  BD_HEAVY_LEFT = 0x11,
  BD_HEAVY_RIGHT = 0x22,
  BD_HEAVY_HORIZONTAL = 0x33,
  BD_HEAVY_UP = 0x44,
  BD_HEAVY_DOWN = 0x88,
  BD_HEAVY_VERTICAL = 0xCC,
  BD_HEAVY = 0xF0,
  BD_DASHED = 0x100,
  BD_DENSELY_DASHED = 0x200,
  // Refer to the box-drawing character in Shift-JIS 0x8643 ~ 0x868F.
  // Not to be confused with characters sparsed in 0x0080 ~ 0x00FF (see
  // ank_box_drawing)
  BD_HALFWIDTH = 0x400,
  // Use the code that modern Shift-JIS uses, 0x849F ~ 0x84BE.
  // Note that this is not supported by NEC PC-98s, and only a subset of the
  // PC-98 specific box-drawing characters are supported.
  // Ignores the BD_HALFWIDTH bit if this bit is set.
  BD_MODERN = 0x800
};
/**
 * @brief Returns the (Shift-)JIS encoding of a box-drawing character.
 *
 * @param bitmap a bitmap with mask defined in box_drawing_t
 * @param use_shift_jis when set to true, use Shift-JIS encoding, otherwise,
 *                      use JIS encoding.
 * @return `unsigned` - the encoding. Returns a "?" if the bitmap is incorrect.
 *                      The width of "?" will follow the BD_HALFWIDTH bit of the
 *                      bitmap (except BD_MODERN is set, in that case it will
 *                      always be fullwidth).
 */
unsigned box_drawing(box_drawing_t bitmap, bool use_shift_jis = true);

// Bitmap enum for function ank_box_drawing
enum ank_box_drawing_t {
  ANK_BD_LEFT = 0x01,
  ANK_BD_RIGHT = 0x02,
  ANK_BD_HORIZONTAL = 0x03,
  ANK_BD_UP = 0x04,
  ANK_BD_DOWN = 0x08,
  ANK_BD_VERTICAL = 0x0C,
  ANK_BD_ANTI_DIAGONAL = 0x10,  // the diagonal from topright to bottomleft
  ANK_BD_MAIN_DIAGONAL = 0x20,  // the diagonal from topleft to bottomright
  ANK_BD_ARC = 0x40,  // make the 90-degree turn an arc.
  ANK_BD_DOUBLE = 0x80,  // doublize the existing horizontal lines
  ANK_BD_TOPMOST_HORIZONTAL = 0x100,
  ANK_BD_RIGHTMOST_VERTICAL = 0x200
};
/**
 * @brief Returns the (Shift-)JIS encoding of a box-drawing character.
 * The term "ANK" is an abbreviation of "Alphabet, Numbers, and Kana",
 * referring to the characters with code 0x0000 ~ 0x00FF.
 *
 * @param bitmap a bitmap with mask defined in ank_box_drawing_t.
 * @return `unsigned` - the encoding. Returns a "?" if the bitmap is incorrect.
 */
unsigned ank_box_drawing(ank_box_drawing_t bitmap);

/**
 * @brief Returns the "left x/8 square" ANK character.
 *
 * @return `unsigned` - the encoding. Returns a "?" if input is incorrect.
 */
unsigned ank_left_x_of_8_square(unsigned x);
/**
 * @brief Returns the "bottom x/8 square" ANK character.
 *
 * @return `unsigned` - the encoding. Returns a "?" if input is incorrect.
 */
unsigned ank_bottom_x_of_8_square(unsigned x);

enum characters_t {
  ANK_FULL_BLOCK = 0x87,
  ANK_LEFT_ARROW = 0x2C,
  ANK_RIGHT_ARROW = 0x2D,
  ANK_UP_ARROW = 0x2E,
  ANK_DOWN_ARROW = 0x2F,
  ANK_BOTTOM_RIGHT_QUARTER = 0xE4,
  ANK_BOTTOM_LEFT_QUARTER = 0xE5,
  ANK_TOP_RIGHT_QUARTER = 0xE6,
  ANK_TOP_LEFT_QUARTER = 0xE7,
  JIS_FULLWIDTH_SPACE = 0x2121,
  JIS_FULLWIDTH_QUESTION_MARK = 0x2129
};

#endif  // #ifndef THPRAC98_SRC_TUI_CHARS_HPP_