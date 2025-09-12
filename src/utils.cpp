#include "src/utils.hpp"

#include "master.h"

#include <stdio.h>  // putchar

bool is_pressed(key_t key) {
  int result = key_sense(keygroup_and_index_of[key][0]);
  return result & (0x01 << keygroup_and_index_of[key][1]);
}

int char_width(unsigned ch) {
  return 2 - (ch <= 0x00FFu || (0x8540u <= ch && ch <= 0x869Du));
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

const unsigned popcount_data[16] = {
  0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
};
unsigned popcount(unsigned n) {
  return popcount_data[n & 0xF] + popcount_data[(n >> 4) & 0xF]
         + popcount_data[(n >> 8) & 0xF] + popcount_data[(n >> 12) & 0xF];
}

void graph_mode(void) {
  printf("\x1b)3");
  return;
}
void kanji_mode(void) {
  printf("\x1b)0");
  return;
}

template <class T, class U>
pair<T, U> make_pair(T first, U second) {
  pair<T, U> ret(first, second);
  return ret;
}

bool is_epson = false;

bool valid_shiftjis(unsigned ch) {
  // FIXME: 0x8C49 will return false. Fix it.
  if (ch <= 0x7F) { return true; }  // ASCII
  if (0xA1 <= ch && ch <= 0xDF) { return true; }  // Half-width katakana
  unsigned upper = ch >> 8, lower = ch & 0xFF;
  if (!((0x81 <= upper && upper <= 0x9F) || (0xE0 <= upper && upper <= 0xEF))) {
    return false;  // First byte out of range
  }
  // Second byte out of range
  if (upper & 1) {
    if (lower == 0x7F) { return false; }
    if (!(0x40 <= lower && lower <= 0x9E)) { return false; }
  } else {
    if (!(0x9F <= lower && lower <= 0xFC)) { return false; }
  }
  return true;
}
bool shiftjis_starting_byte(unsigned ch) {
  return (0x81 <= ch && ch <= 0x9F) || (0xE0 <= ch && ch <= 0xEF);
}

void wait_for_enter_key() {
  printf("--- Press enter key to continue ---");
  getchar();
  return;
}
void print_delimiter(char ch) {
  int i = 0;
  putchar('\n');
  for (i = 0; i < 80; ++i) {
    putchar(ch);
  }
  putchar('\n');
  return;
}
int print_string(const char* str, bool pause, bool kanji, int rows) {
  if (rows <= 0) { return 1; }
  if (kanji) {
    kanji_mode();
  } else {
    graph_mode();
  }
  int row = 0, col = 0, i = 0;
  unsigned previous_byte = 0;
  unsigned ch = 0;
  for (i = 0; str[i]; ++i) {
    ch = str[i] & 0xFF;
    if (previous_byte) {
      ch |= previous_byte << 8;
      previous_byte = 0;
    } else if (shiftjis_starting_byte(ch) && kanji) {
      previous_byte = ch;
      continue;
    }
    if (ch == '\n') {
      putchar('\n');
      col = 0;
      row++;
    }
    if (col == 80) {
      putchar('\n');
      col = 0;
      row++;
    } else if (col == 79) {
      if (ch > 0xFF && valid_shiftjis(ch) && char_width(ch) == 2) {
        putchar('\n');
        col = 0;
        row++;
      }
    }
    if (row == rows && pause) {
      wait_for_enter_key();
      row = 0;
    }
    if (ch == '\n' || ch == '\r') { continue; }
    col += char_width(ch);
    // if (!valid_shiftjis(ch)) {
    //   putchar('?');
    //   continue;
    // }
    if (ch > 0xFF) {
      putchar(ch >> 8);
    }
    putchar(ch & 0xFF);
    ch = 0;
  }
  return 0;
}