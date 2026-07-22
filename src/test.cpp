#include "src/test.hpp"

#include "src/asmutils/asmutils.hpp"
#include "src/mystdlib/ctype.hpp"
#include "src/mystdlib/stdio.hpp"
#include "src/tui/chars.hpp"
#include "src/utils.hpp"

int test_stdint(void) {
#define test_stdint_macro(bit_length)                                \
  bit_length * !((sizeof(uint##bit_length) * 8 == bit_length) &&     \
                 ((uint##bit_length)(-1) > (uint##bit_length)(0)) && \
                 (sizeof(int##bit_length) * 8 == bit_length) &&      \
                 ((int##bit_length)(-1) < (int##bit_length)(0)))
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
      {ANK_BD_ANTI_DIAGONAL | ANK_BD_MAIN_DIAGONAL, 0xF0}};
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
      BD_HEAVY_VERTICAL | BD_HORIZONTAL};
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
      BD_HEAVY_VERTICAL | BD_DASHED};
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
      unsigned jis =
          box_drawing((box_drawing_t)(shape | (heaviness << 4)), false);
      if ((popcount_data[shape] == 1) ||
          ((shape == BD_HORIZONTAL || shape == BD_VERTICAL) &&
           (heaviness & shape) != 0 && (heaviness & shape) != shape)) {
        if (jis != JIS_FULLWIDTH_QUESTION_MARK) {
          return ret;
        }
        continue;
      }
      check_glyph(jis, glyph);
      // In an order of left, right, up, down
      unsigned pops[4];
      pops[0] = pops[1] = 0;
      pops[2] = popcount(glyph[0]);
      pops[3] = popcount(glyph[15]);
      for (i = 0; i < 15; ++i) {
        pops[0] += !!(glyph[i] & 0x8000);
        pops[1] += (glyph[i] & 1);
      }
      unsigned mask = 0x01;
      for (i = 0; i < 4; ++i) {
        switch (pops[i]) {
          case 0:
            if (shape & mask) {
              return ret;
            }
            break;
          case 1:
            if (!((shape & mask) && !(heaviness & mask))) {
              return ret;
            }
            break;
          case 2:
            if (!((shape & mask) && (heaviness & mask))) {
              return ret;
            }
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

int test_strcmpnc(void) {
  struct testcase_t {
    const char *str1, *str2;
    bool expect_to_equal;
  };
#define set_testcase(var, str1_, str2_, expect_to_equal_) \
  {                                                       \
    var.str1 = str1_;                                     \
    var.str2 = str2_;                                     \
    var.expect_to_equal = expect_to_equal_;               \
  }
  static testcase_t testcases[4];
  set_testcase(testcases[0], "", "", true);
  set_testcase(testcases[1], "abc", "", false);
  set_testcase(testcases[2], "abc", "abcdef", false);
  set_testcase(testcases[3], "abcdefghijklmnopqrstuvwxyz",
               "ABCDEFGHIJKLMNOPQRSTUVWXYZ", true);
#undef set_testcase
  int i = 0, j = 0;
  int testcase_cnt = sizeof(testcases) / sizeof(testcases[0]);
  char str1[2] = "a", str2[2] = "b";
  int val_expected = 0;

  for (i = 0; i < testcase_cnt; ++i) {
    if (strcmp_ignore_case(testcases[i].str1, testcases[i].str2) !=
        (testcases[i].expect_to_equal ? 0 : -1)) {
      return i * 2 + 1;
    }
    if (strcmp_ignore_case(testcases[i].str2, testcases[i].str1) !=
        (testcases[i].expect_to_equal ? 0 : -1)) {
      return i * 2 + 2;
    }
  }
  for (i = 1; i < 127; ++i) {
    for (j = 1; j < 127; ++j) {
      str1[0] = i;
      str2[0] = j;
      val_expected = (tolower(i) == tolower(j) ? 0 : -1);
      if (strcmp_ignore_case(str1, str2) != val_expected) {
        return -((i << 7) | j);
      }
    }
  }
  return 0;
}

int test_sprint_hex(void) {
  int i = 0;
  struct testcase_t {
    unsigned long val;
    const char* str;
  };
#define set_testcase(var, val_, str_) \
  {                                   \
    var.val = val_;                   \
    var.str = str_;                   \
  }
  static testcase_t byte_testcases[5];
  set_testcase(byte_testcases[0], 0x00, "00");
  set_testcase(byte_testcases[1], 0x03, "03");
  set_testcase(byte_testcases[2], 0x19, "19");
  set_testcase(byte_testcases[3], 0xA2, "A2");
  set_testcase(byte_testcases[4], 0xAE, "AE");

  static testcase_t word_testcases[7];
  set_testcase(word_testcases[0], 0x0000, "0000");
  set_testcase(word_testcases[1], 0x0003, "0003");
  set_testcase(word_testcases[2], 0x0034, "0034");
  set_testcase(word_testcases[3], 0x0349, "0349");
  set_testcase(word_testcases[4], 0x1234, "1234");
  set_testcase(word_testcases[5], 0xABCD, "ABCD");
  set_testcase(word_testcases[6], 0xA1B2, "A1B2");

  static testcase_t dword_testcases[12];
  set_testcase(dword_testcases[0], 0x00000000l, "00000000");
  set_testcase(dword_testcases[1], 0x00000009l, "00000009");
  set_testcase(dword_testcases[2], 0x00000084l, "00000084");
  set_testcase(dword_testcases[3], 0x00000284l, "00000284");
  set_testcase(dword_testcases[4], 0x0000A284l, "0000A284");
  set_testcase(dword_testcases[5], 0x0004A284l, "0004A284");
  set_testcase(dword_testcases[6], 0x0074A284l, "0074A284");
  set_testcase(dword_testcases[7], 0x0174A284l, "0174A284");
  set_testcase(dword_testcases[8], 0x12372948l, "12372948");
  set_testcase(dword_testcases[9], 0xAFEDBCADl, "AFEDBCAD");
  set_testcase(dword_testcases[10], 0x1A4B2EF0l, "1A4B2EF0");
  set_testcase(dword_testcases[11], 0xF1B3A24El, "F1B3A24E");
#undef set_testcase
  int testcase_size = 0;
  char str[50];

  // Test to_hex_digit. Returns 0x100 | (the byte) if the result is
  // incorrect.
  for (i = 0; i < 10; ++i) {
    if (to_hex_digit(i) != i + '0') {
      return 0x100 | i;
    }
  }
  for (i = 10; i < 16; ++i) {
    if (to_hex_digit(i) != i - 10 + 'A') {
      return 0x100 | i;
    }
  }

  // Test sprint_byte. Returns 0x200 | (testcase index) if the result is
  // incorrect.
  testcase_size = sizeof(byte_testcases) / sizeof(byte_testcases[0]);
  str[2] = '\0';
  for (i = 0; i < testcase_size; ++i) {
    sprint_byte(str, (unsigned)(byte_testcases[i].val));
    if (strcmp(str, byte_testcases[i].str)) {
      return 0x200 | i;
    }
  }

  // Test sprint_word. Returns 0x300 | (testcase index) if the result is
  // incorrect.
  str[4] = '\0';
  testcase_size = sizeof(word_testcases) / sizeof(word_testcases[0]);
  for (i = 0; i < testcase_size; ++i) {
    sprint_word(str, (unsigned)(word_testcases[i].val));
    if (strcmp(str, word_testcases[i].str)) {
      return 0x300 | i;
    }
  }

  // Test sprint_dword. Returns 0x400 | (testcase index) if the result is
  // incorrect.
  str[8] = '\0';
  testcase_size = sizeof(dword_testcases) / sizeof(dword_testcases[0]);
  for (i = 0; i < testcase_size; ++i) {
    sprint_dword(str, dword_testcases[i].val);
    if (strcmp(str, dword_testcases[i].str)) {
      return 0x400 | i;
    }
  }
  return 0;
}

// Some helper functions and arrays of test_tram_print
char saved_tram_data[0x0FA0], saved_tram_attr_data[0x0FA0];

unsigned tram_get(int x, int y) {
  return *(unsigned far*)(MK_FP(0xA000, y * 160 + x * 2));
}
uint8 tram_attr_get(int x, int y) {
  return *(unsigned far*)(MK_FP(0xA200, y * 160 + x * 2));
}

void clear_tram_data() {
  _fmemset(MK_FP(0xA000, 0x0000), 0x00, 0x0FA0);
  _fmemset(MK_FP(0xA200, 0x0000), 0x00, 0x0FA0);
  return;
}
void backup_tram_data() {
  _fmemcpy(saved_tram_data, MK_FP(0xA000, 0x0000), 0x0FA0);
  _fmemcpy(saved_tram_attr_data, MK_FP(0xA200, 0x0000), 0x0FA0);
  return;
}
void restore_tram_data() {
  _fmemcpy(MK_FP(0xA000, 0x0000), saved_tram_data, 0x0FA0);
  _fmemcpy(MK_FP(0xA200, 0x0000), saved_tram_attr_data, 0x0FA0);
  return;
}

int test_tram_print(void) {
  struct print_ch_testcase_t {
    unsigned code, attr;
    int x, y, ret;
  };
#define set_testcase(var, code_, attr_, x_, y_, ret_) \
  {                                                   \
    var.code = code_;                                 \
    var.x = x_;                                       \
    var.y = y_;                                       \
    var.attr = attr_;                                 \
    var.ret = ret_;                                   \
  }
  static print_ch_testcase_t print_ch_testcases[7];
  set_testcase(print_ch_testcases[0], 'Z', 0xE1, 12, 23, 0);
  set_testcase(print_ch_testcases[1], 'Q', 0x20, 10, 10, 0);
  set_testcase(print_ch_testcases[2], 0x14, 0x3A, 3, 7, 0);
  set_testcase(print_ch_testcases[3], 0xA0, 0x3F, 14, 16, 0);
  set_testcase(print_ch_testcases[4], 'T', 0x10, 90, 20, 1);
  set_testcase(print_ch_testcases[5], 'E', 0x30, 30, 27, 1);
  set_testcase(print_ch_testcases[6], 'F', 0x1A, 100, 38, 1);
#undef set_testcase
  struct print_str_testcase_t {
    char const* str;
    unsigned attr;
    int x, y, ret;
  };
#define set_testcase(var, str_, attr_, x_, y_, ret_) \
  {                                                  \
    var.str = str_;                                  \
    var.attr = attr_;                                \
    var.x = x_;                                      \
    var.y = y_;                                      \
    var.ret = ret_;                                  \
  }
  static print_str_testcase_t print_str_testcases[5];
  set_testcase(print_str_testcases[0], "abcd123", 0xF1, 14, 21, 0);
  set_testcase(print_str_testcases[1], "\013\011\021\004\005\002\007", 0x31, 7,
               8, 0);
  set_testcase(print_str_testcases[2], "AF0123", 0x48, 78, 10, 1);
  set_testcase(print_str_testcases[3], "14X94Q;", 0x11, 10, 30, 1);
  set_testcase(print_str_testcases[4], "POQWE324", 0xFF, 90, 30, 1);
#undef set_testcase

  int i = 0, j = 0, k = 0, test_cnt = 0, len = 0;
  unsigned expected_code = 0x0000, expected_attr = 0x0000;
  int ret = 0;
  print_ch_testcase_t cur1;
  print_str_testcase_t cur2;

  backup_tram_data();

  // Test print_ch. Returns 0x100 | (testcase index) if the result is incorrect.
  test_cnt = sizeof(print_ch_testcases) / sizeof(print_ch_testcases[0]);
  for (i = 0; i < test_cnt; ++i) {
    clear_tram_data();
    memcpy(&cur1, &print_ch_testcases[i], sizeof(cur1));
    ret = print_ch(cur1.code, cur1.x, cur1.y, cur1.attr);
    if (ret != cur1.ret) {
      restore_tram_data();
      printf("!@%d\n", i);
      return 0x100 | i;
    }
    for (j = 0; j < 80; ++j) {
      for (k = 0; k < 25; ++k) {
        if (j == cur1.x && k == cur1.y) {
          expected_code = cur1.code;
          expected_attr = cur1.attr;
        } else {
          expected_code = expected_attr = 0x0000;
        }
        if (tram_get(j, k) != expected_code ||
            tram_attr_get(j, k) != (uint8)(expected_attr)) {
          restore_tram_data();
          printf("?@%d\n", i);
          return 0x100 | i;
        }
      }
    }
  }

  // Test print_str. Returns 0x200 | (testcase index) if the result is
  // incorrect.
  test_cnt = sizeof(print_str_testcases) / sizeof(print_str_testcases[0]);
  for (i = 0; i < test_cnt; ++i) {
    clear_tram_data();
    memcpy(&cur2, &print_str_testcases[i], sizeof(cur2));
    len = strlen(cur2.str);
    ret = print_str(cur2.str, cur2.x, cur2.y, cur2.attr);
    if (ret != cur2.ret) {
      restore_tram_data();
      printf("!@%d\n", i);
      return 0x200 | i;
    }
    for (j = 0; j < 80; ++j) {
      for (k = 0; k < 25; ++k) {
        if (k != cur2.y || j < cur2.x || j >= cur2.x + len) {
          expected_code = expected_attr = 0x0000;
        } else {
          expected_code = cur2.str[j - cur2.x];
          expected_attr = cur2.attr;
        }
        if (tram_get(j, k) != expected_code ||
            tram_attr_get(j, k) != (uint8)(expected_attr)) {
          restore_tram_data();
          printf("?@%d\n", i);
          return 0x200 | i;
        }
      }
    }
  }

  restore_tram_data();
  return 0;
}

void test_function(const char* name, int test_func(void)) {
  printf("Testing %s... ", (const char far*)(name));
  fflush(stdout);
  int ret = test_func();
  if (ret == 0) {
    printf("OK.\r\n");
  } else {
    printf("failed (code: %d).\r\n", ret);
  }
  return;
}

int wrapped_main(int argc, char far* near* argv) {
  argc, argv;
  test_function("stdint types", test_stdint);
  test_function("1-byte box-drawing characters handling", test_ank_box_drawing);
  test_function("2-byte box-drawing characters handling", test_box_drawing);
  test_function("functions in strcmpnc.asm", test_strcmpnc);
  test_function("functions in sprnthex.asm", test_sprint_hex);
  // print_ch('Z', 15, 10, 0xE1);
  // print_str("abcd123", 14, 21, 0xE1);
  // print_str("AF0123", 70, 10, 0xE1);
  test_function("functions in tramprnt.asm", test_tram_print);
  printf("The tests are finished.");
  return 0;
}