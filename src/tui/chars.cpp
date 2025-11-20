#include "src/tui/chars.hpp"

int modern_box_drawing_helper(unsigned shape) {
  switch (shape ^ 0xF) {
    case BD_LEFT:
      return 0;
    case BD_UP:
      return 1;
    case BD_RIGHT:
      return 2;
    case BD_DOWN:
      return 3;
    case 0:
      return 4;
  }
  return -1;
}

// For internal use only. Returns JIS code if success, 0xFFFF if failed.
unsigned modern_box_drawing(box_drawing_t bitmap) {
  if (bitmap & (BD_DASHED | BD_DENSELY_DASHED)) {
    return 0xFFFF;
  }
  bool has_heavy = !!((bitmap >> 4) & bitmap & 0xF);
  bool has_normal = !!((~bitmap >> 4) & bitmap & 0xF);
  unsigned shape = bitmap & 0xF;
  if (!has_heavy && !has_normal) {
    return JIS_FULLWIDTH_SPACE;
  }
  if (has_heavy ^ has_normal) {
    unsigned offset = has_heavy ? 0x0B : 0;
    switch (popcount_data[shape]) {
      case 1:
        return 0xFFFF;
      case 2:
        switch (shape) {
          case BD_HORIZONTAL:
            return offset + 0x2821;
          case BD_VERTICAL:
            return offset + 0x2822;
          case BD_RIGHT | BD_DOWN:
            return offset + 0x2823;
          case BD_LEFT | BD_DOWN:
            return offset + 0x2824;
          case BD_LEFT | BD_UP:
            return offset + 0x2825;
          case BD_RIGHT | BD_UP:
            return offset + 0x2826;
        }
        return 0xFFFF;  // unreachable
      case 3:
      case 4:
        return offset + 0x2827 + modern_box_drawing_helper(shape);
    }
    return 0xFFFF;  // unreachable
  }
  int code = modern_box_drawing_helper(shape);
  unsigned heaviness = (bitmap >> 4) & bitmap & 0xF;
  static const box_drawing_t heaviness_check[5][2] = {
      {BD_VERTICAL, BD_RIGHT},
      {BD_HORIZONTAL, BD_DOWN},
      {BD_VERTICAL, BD_LEFT},
      {BD_HORIZONTAL, BD_UP},
      {BD_HORIZONTAL, BD_VERTICAL}};
  if (code != -1) {
    if (heaviness == heaviness_check[code][0]) {
      return code + 0x2837;
    }
    if (heaviness == heaviness_check[code][1]) {
      return code + 0x283C;
    }
  }
  return 0xFFFF;
}

unsigned box_drawing(box_drawing_t bitmap, bool use_shift_jis) {
  unsigned jis = 0;
  if (bitmap & BD_MODERN) {
    jis = modern_box_drawing(bitmap);
    if (jis == 0xFFFF) {
      jis = JIS_FULLWIDTH_QUESTION_MARK;
    }
    return use_shift_jis ? jis_to_shiftjis(jis) : jis;
  }
  unsigned shape = bitmap & 0xF;
  unsigned heaviness = (bitmap >> 4) & bitmap & 0xF;
  if (bitmap & (BD_DASHED | BD_DENSELY_DASHED)) {
    if ((shape != BD_HORIZONTAL) && (shape != BD_VERTICAL)) {
      jis = JIS_FULLWIDTH_QUESTION_MARK;
    } else if ((shape & BD_DASHED) && (shape & BD_DENSELY_DASHED)) {
      jis = JIS_FULLWIDTH_QUESTION_MARK;
    } else {
      jis = 0x2C28 | (0x01 & -!!heaviness) | (0x02 & -(shape == BD_VERTICAL)) |
            (0x04 & -!!(bitmap & BD_DASHED));
    }
    return use_shift_jis ? jis_to_shiftjis(jis) : jis;
  }

  static const uint8 x2C40_rearrange[8] = {0, 1, 2, 5, 3, 6, 4, 7};
  static const uint8 x2C60_rearrange[16] = {0, 1, 2,  3,  4, 7,  8,  11,
                                            5, 9, 10, 12, 6, 13, 14, 15};
  unsigned bitmask = 0x01, shift = 0x01, offset = 0;
  switch (popcount_data[shape]) {
    case 0:
      jis = JIS_FULLWIDTH_SPACE;
      break;
    case 1:
      jis = JIS_FULLWIDTH_QUESTION_MARK;
      break;
    case 2:
      if (shape == BD_VERTICAL || shape == BD_HORIZONTAL) {
        if (heaviness != 0 && heaviness != shape) {
          jis = JIS_FULLWIDTH_QUESTION_MARK;
        } else {
          jis =
              0x2C24 | (0x01 & -!!heaviness) | (0x02 & -(shape == BD_VERTICAL));
        }
        break;
      }
      switch (shape) {
        case BD_RIGHT | BD_DOWN:
          jis = 0x2C30;
          break;
        case BD_LEFT | BD_DOWN:
          jis = 0x2C34;
          break;
        case BD_RIGHT | BD_UP:
          jis = 0x2C38;
          break;
        case BD_LEFT | BD_UP:
          jis = 0x2C3C;
          break;
      }
      jis |= (0x01 & -!!(heaviness & BD_HORIZONTAL));
      jis |= (0x02 & -!!(heaviness & BD_VERTICAL));
      break;
    case 3:
      switch (shape ^ 0x0F) {
        case BD_LEFT:
          jis = 0x2C40;
          break;
        case BD_RIGHT:
          jis = 0x2C48;
          break;
        case BD_UP:
          jis = 0x2C50;
          break;
        case BD_DOWN:
          jis = 0x2C58;
          break;
      }
      for (bitmask = 0x01; bitmask != 0x10; bitmask <<= 1) {
        if (shape & bitmask) {
          if (heaviness & bitmask) {
            offset |= shift;
          }
          shift <<= 1;
        }
      }
      if (0x2C40 <= jis && jis <= 0x2C4F) {
        offset = x2C40_rearrange[offset];
      }
      jis |= offset;
      break;
    case 4:
      jis = 0x2C60 | x2C60_rearrange[heaviness];
      break;
  }

  if (bitmap & BD_HALFWIDTH) {
    if (jis == JIS_FULLWIDTH_SPACE) {
      jis = ' ';
    } else if (jis == JIS_FULLWIDTH_QUESTION_MARK) {
      jis = '?';
    } else {
      jis -= 0x100;
    }
  }
  return use_shift_jis ? jis_to_shiftjis(jis) : jis;
}

unsigned ank_box_drawing(ank_box_drawing_t bitmap) {
  // Characters that cannot be combined
  if (bitmap & ANK_BD_TOPMOST_HORIZONTAL) {
    return bitmap == ANK_BD_TOPMOST_HORIZONTAL ? 0x94 : '?';
  }
  if (bitmap & ANK_BD_RIGHTMOST_VERTICAL) {
    return bitmap == ANK_BD_RIGHTMOST_VERTICAL ? 0x97 : '?';
  }
  if (bitmap & (ANK_BD_MAIN_DIAGONAL | ANK_BD_ANTI_DIAGONAL)) {
    if (bitmap & ~(ANK_BD_MAIN_DIAGONAL | ANK_BD_ANTI_DIAGONAL)) {
      return '?';
    }
    // (bitmap>>4): 1 for anti-diag, 2 for main-diag, 3 for both
    return 0xED + (bitmap >> 4);
  }

  if ((bitmap & ANK_BD_DOUBLE) && (bitmap & (ANK_BD_HORIZONTAL))) {
    switch (bitmap ^ ANK_BD_DOUBLE) {
      case ANK_BD_HORIZONTAL:
        return 0xE0;
      case ANK_BD_VERTICAL | ANK_BD_RIGHT:
        return 0xE1;
      case ANK_BD_VERTICAL | ANK_BD_HORIZONTAL:
        return 0xE2;
      case ANK_BD_VERTICAL | ANK_BD_LEFT:
        return 0xE3;
      default:
        return '?';
    }
  }

  unsigned shape = bitmap & 0xF;
  unsigned offset = 0;
  switch (popcount_data[shape]) {
    case 0:
      return ' ';
    case 1:
      return '?';
    case 2:
      if (shape == ANK_BD_HORIZONTAL) {
        return 0x95;
      }
      if (shape == ANK_BD_VERTICAL) {
        return 0x96;
      }
      offset = (bitmap & ANK_BD_ARC) ? 4 : 0;
      switch (shape) {
        case ANK_BD_RIGHT | ANK_BD_DOWN:
          return 0x98 + offset;
        case ANK_BD_LEFT | ANK_BD_DOWN:
          return 0x99 + offset;
        case ANK_BD_RIGHT | ANK_BD_UP:
          return 0x9a + offset;
        case ANK_BD_LEFT | ANK_BD_UP:
          return 0x9b + offset;
      }
      return '?';  // unreachable
    case 3:
      switch (shape ^ 0xF) {
        case ANK_BD_DOWN:
          return 0x90;
        case ANK_BD_UP:
          return 0x91;
        case ANK_BD_RIGHT:
          return 0x92;
        case ANK_BD_LEFT:
          return 0x93;
      }
    case 4:
      return 0x8F;
  }
  return '?';  // unreachable
}

unsigned ank_left_x_of_8_square(unsigned x) {
  if (x == 0) {
    return ' ';
  }
  if (x == 8) {
    return 0x87;
  }
  if (x < 8) {
    return 0x87 + x;
  }
  return '?';
}
unsigned ank_bottom_x_of_8_square(unsigned x) {
  if (x == 0) {
    return ' ';
  }
  if (x <= 8) {
    return 0x7F + x;
  }
  return '?';
}