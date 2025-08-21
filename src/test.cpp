#include "src/test.hpp"

#include <stdio.h>

#include "src/utils.hpp"
#include "src/tui/chars.hpp"

int test_stdint(void) {
#define test_stdint_macro(bit_length) bit_length * !(    \
    (sizeof(uint##bit_length) * 8 == bit_length) &&      \
    ((uint##bit_length)(-1) > (uint##bit_length)(0)) &&  \
    (sizeof(int##bit_length) * 8 == bit_length) &&       \
    ((int##bit_length)(-1) < (int##bit_length)(0))       \
  )
  return test_stdint_macro(8) | test_stdint_macro(16) | test_stdint_macro(32);
#undef test_stdint_macro
}

int test_ank_box_drawing(void) {
  static const unsigned test_cases[][2] = {
    {0, ' '},
    {ANK_BD_HORIZONTAL | ANK_BD_VERTICAL, 0x8F},
    {ANK_BD_HORIZONTAL | ANK_BD_UP, 0x90},
    {ANK_BD_HORIZONTAL | ANK_BD_DOWN, 0x91},
    {ANK_BD_VERTICAL | ANK_BD_LEFT, 0x92},
    {ANK_BD_VERTICAL | ANK_BD_RIGHT, 0x93},
    {ANK_BD_TOPMOST_HORIZONTAL, 0x94},
    {ANK_BD_HORIZONTAL, 0x95},
    {ANK_BD_VERTICAL, 0x96},
    {ANK_BD_RIGHTMOST_VERTICAL, 0x97},
    {ANK_BD_RIGHT | ANK_BD_DOWN, 0x98},
    {ANK_BD_LEFT | ANK_BD_DOWN, 0x99},
    {ANK_BD_RIGHT | ANK_BD_UP, 0x9A},
    {ANK_BD_LEFT | ANK_BD_UP, 0x9B},
    {ANK_BD_RIGHT | ANK_BD_DOWN | ANK_BD_ARC, 0x9C},
    {ANK_BD_LEFT | ANK_BD_DOWN | ANK_BD_ARC, 0x9D},
    {ANK_BD_RIGHT | ANK_BD_UP | ANK_BD_ARC, 0x9E},
    {ANK_BD_LEFT | ANK_BD_UP | ANK_BD_ARC, 0x9F},
    {ANK_BD_DOUBLE | ANK_BD_HORIZONTAL, 0xE0},
    {ANK_BD_DOUBLE | ANK_BD_RIGHT | ANK_BD_VERTICAL, 0xE1},
    {ANK_BD_DOUBLE | ANK_BD_HORIZONTAL | ANK_BD_VERTICAL, 0xE2},
    {ANK_BD_DOUBLE | ANK_BD_LEFT | ANK_BD_VERTICAL, 0xE3},
    {ANK_BD_ANTI_DIAGONAL, 0xEE},
    {ANK_BD_MAIN_DIAGONAL, 0xEF},
    {ANK_BD_ANTI_DIAGONAL | ANK_BD_MAIN_DIAGONAL, 0xF0}
  };
  static const int test_case_count = sizeof(test_cases) / sizeof(unsigned) / 2;
  int i = 0;
  for (i = 0; i < test_case_count; ++i) {
    if (ank_box_drawing((ank_box_drawing_t)(test_cases[i][0])) !=
        test_cases[i][1]) {
      return i + 1;
    }
  }
  return 0;
}

// From PC9801 Programmers' Bible, Section 2-6-6-13
void check_glyph(unsigned jis, unsigned lines[16]) {
  REGS inregs, outregs;
  unsigned char patbuf[17 * 2];
  inregs.x.bx = FP_SEG(patbuf);
  inregs.x.cx = FP_OFF(patbuf);
  inregs.x.dx = jis;
  inregs.h.ah = 0x14;
  int86(0x18, &inregs, &outregs);
  int i = 1;
  for (i = 1; i <= 16; ++i) {
    lines[i - 1] = (unsigned)patbuf[i * 2] * 0x100 + patbuf[i * 2 + 1];
  }
  return;
}

int test_box_drawing(void) {
  static const unsigned modern_charset[] = {
    BD_HORIZONTAL,
    BD_VERTICAL,
    BD_RIGHT | BD_DOWN,
    BD_LEFT | BD_DOWN,
    BD_LEFT | BD_UP,
    BD_RIGHT | BD_UP,
    BD_VERTICAL | BD_RIGHT,
    BD_HORIZONTAL | BD_DOWN,
    BD_VERTICAL | BD_LEFT,
    BD_HORIZONTAL | BD_UP,
    BD_HORIZONTAL | BD_VERTICAL,
    BD_HEAVY_HORIZONTAL,
    BD_HEAVY_VERTICAL,
    BD_HEAVY_RIGHT | BD_HEAVY_DOWN,
    BD_HEAVY_LEFT | BD_HEAVY_DOWN,
    BD_HEAVY_LEFT | BD_HEAVY_UP,
    BD_HEAVY_RIGHT | BD_HEAVY_UP,
    BD_HEAVY_VERTICAL | BD_HEAVY_RIGHT,
    BD_HEAVY_HORIZONTAL | BD_HEAVY_DOWN,
    BD_HEAVY_VERTICAL | BD_HEAVY_LEFT,
    BD_HEAVY_HORIZONTAL | BD_HEAVY_UP,
    BD_HEAVY_HORIZONTAL | BD_HEAVY_VERTICAL,
    BD_HEAVY_VERTICAL | BD_RIGHT,
    BD_HEAVY_HORIZONTAL | BD_DOWN,
    BD_HEAVY_VERTICAL | BD_LEFT,
    BD_HEAVY_HORIZONTAL | BD_UP,
    BD_HEAVY_HORIZONTAL | BD_VERTICAL,
    BD_HEAVY_RIGHT | BD_VERTICAL,
    BD_HEAVY_DOWN | BD_HORIZONTAL,
    BD_HEAVY_LEFT | BD_VERTICAL,
    BD_HEAVY_UP | BD_HORIZONTAL,
    BD_HEAVY_VERTICAL | BD_HORIZONTAL
  };
  static const int modern_charset_size =
      sizeof(modern_charset) / sizeof(unsigned);
  unsigned i = 0;
  for (i = 0; i < modern_charset_size; ++i) {
    if (box_drawing((box_drawing_t)(BD_MODERN | modern_charset[i]), false) !=
        0x2821 + i) {
      return i + 1;
    }
  }
  if (box_drawing(BD_MODERN, false) != JIS_FULLWIDTH_SPACE) {
    return 51;
  }
  if (box_drawing((box_drawing_t)(BD_MODERN | BD_UP), false) !=
      JIS_FULLWIDTH_QUESTION_MARK) {
    return 52;
  }
  static const unsigned dashed_charset[] = {
    BD_HORIZONTAL | BD_DENSELY_DASHED,
    BD_HEAVY_HORIZONTAL | BD_DENSELY_DASHED,
    BD_VERTICAL | BD_DENSELY_DASHED,
    BD_HEAVY_VERTICAL | BD_DENSELY_DASHED,
    BD_HORIZONTAL | BD_DASHED,
    BD_HEAVY_HORIZONTAL | BD_DASHED,
    BD_VERTICAL | BD_DASHED,
    BD_HEAVY_VERTICAL | BD_DASHED
  };
  for (i = 0; i < 8; ++i) {
    if (box_drawing((box_drawing_t)(dashed_charset[i]), false) != 0x2C28 + i) {
      return i + 100;
    }
  }
  unsigned shape = 0, heaviness = 0;
  unsigned glyph[16];
  for (shape = 0; shape <= 0xF; ++shape) {
    for (heaviness = 0; heaviness <= 0xF; ++heaviness) {
      unsigned ret = 10000 + shape * 100 + heaviness;
      unsigned jis = box_drawing((box_drawing_t)(shape | (heaviness << 4)),
                                 false);
      if (
          (popcount_data[shape] == 1) ||
          ((shape == BD_HORIZONTAL || shape == BD_VERTICAL) &&
           (heaviness & shape) != 0 && (heaviness & shape) != shape)
      ) {
        if (jis != JIS_FULLWIDTH_QUESTION_MARK) { return ret; }
        continue;
      }
      check_glyph(jis, glyph);
      // In an order of left, right, up, down
      unsigned pops[4] = {0, 0, popcount(glyph[0]), popcount(glyph[15])};
      for (i = 0; i < 15; ++i) {
        pops[0] += !!(glyph[i] & 0x8000);
        pops[1] += (glyph[i] & 1);
      }
      unsigned mask = 0x01;
      for (i = 0; i < 4; ++i) {
        switch (pops[i]) {
          case 0:
            if (shape & mask) { return ret; }
            break;
          case 1:
            if (!((shape & mask) && !(heaviness & mask))) { return ret; }
            break;
          case 2:
            if (!((shape & mask) && (heaviness & mask))) { return ret; }
            break;
          default:
            return ret;
        }
        mask <<= 1;
      }
    }
  }
  return 0;
}

void test_function(const char* name, int test_func(void)) {
  printf("Testing %s... ", name);
  fflush(stdout);
  int ret = test_func();
  if (ret == 0) {
    printf("OK.\n");
  } else {
    printf("failed (code: %d).\n", ret);
  }
  return;
}

int main() {
  test_function("stdint types", test_stdint);
  test_function("1-byte box-drawing characters handling", test_ank_box_drawing);
  test_function("2-byte box-drawing characters handling", test_box_drawing);
  printf("The tests are finished.");
  return 0;
}