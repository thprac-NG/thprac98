#include "src/utils.hpp"

#include "master.h"

#include <stdio.h>  // putchar

#ifdef DEBUG
bool test_stdint(void) {
#define test_stdint_macro(bit_length)                           \
  if (!((sizeof(uint##bit_length) * 8 == bit_length) &&         \
        ((uint##bit_length)(-1) > (uint##bit_length)(0)))) {    \
    return false;                                               \
  }                                                             \
  if (!((sizeof(int##bit_length) * 8 == bit_length) &&          \
        ((int##bit_length)(-1) < (int##bit_length)(0)))) {      \
    return false;                                               \
  }

  test_stdint_macro(8);
  test_stdint_macro(16);
  test_stdint_macro(32);
  return true;
#undef test_stdint_macro
}
#endif

bool is_pressed(key_t key) {
  int result = key_sense(keygroup_and_index_of[key][0]);
  return result & (0x01 << keygroup_and_index_of[key][1]);
}

int char_width(unsigned ch) {
  return (ch <= 0x00FFu || (0x8540u <= ch && ch <= 0x869Du)) + 1;
}

void wputchar(unsigned ch) {
  putchar(ch >> 8);
  putchar(ch & 0xFF);
  return;
}

unsigned jis_to_shiftjis(unsigned ch) {
  unsigned j1 = ch >> 8, j2 = ch & 0xFF;
  unsigned s1 = 0, s2 = 0;
  s1 = (j1 + 1) / 2;
  if (0x21 <= j1 && j1 <= 0x5E) {
    s1 += 0x70;
  } else if (0x5F <= j1 && j1 <= 0x7E) {
    s1 += 0xB0;
  } else {
    return ch;
  }
  if (j1 & 1) {
    s2 = j2 + 0x1F + (j2 >= 0x60);
  } else {
    s2 = j2 + 0x7E;
  }
  return (s1 << 8) | s2;
}
unsigned shiftjis_to_jis(unsigned ch) {
  unsigned s1 = ch >> 8, s2 = ch & 0xFF;
  unsigned j1 = 0, j2 = 0;
  if (0x81 <= s1 && s1 <= 0x9F) {
    j1 = 2 * (s1 - 0x70);
  } else if (0xE0 <= s1 && s1 <= 0xEF) {
    j1 = 2 * (s1 - 0xB0);
  } else {
    return ch;
  }
  if (0x40 <= s2 && s2 <= 0x7E) {
    j2 = s2 - 0x1F;
    j1--;
  } else if (0x80 <= s2 && s2 <= 0x9E) {
    j2 = s2 - 0x20;
    j1--;
  } else if (0x9F <= s2 && s2 <= 0xFC) {
    j2 = s2 - 0x7E;
  } else {
    return ch;
  }
  return (j1 << 8) | j2;
}

unsigned rot(unsigned n) {
  return (n >> 8) | ((n & 0xff) << 8);
}

bool is_epson = false;