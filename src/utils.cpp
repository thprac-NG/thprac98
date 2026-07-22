#include "src/utils.hpp"

#include "src/mystdlib/stdio.hpp"

const key_t keygroups[16][8] = {
    {KEY_ESC, KEY_1_NU, KEY_2_FU, KEY_3_A, KEY_4_U, KEY_5_E, KEY_6_O, KEY_7_YA},
    {KEY_8_YU, KEY_9_YO, KEY_0_WA, KEY_MINUS_HO, KEY_CARET_HE, KEY_YEN_CHOONPU,
     KEY_BS, KEY_TAB},
    {KEY_Q_TA, KEY_W_TE, KEY_E_I, KEY_R_SU, KEY_T_KA, KEY_Y_N, KEY_U_NA,
     KEY_I_NI},
    {KEY_O_RA, KEY_P_SE, KEY_AT_DAKUTEN, KEY_LEFT_BRACKET_KUTEN, KEY_ENTER,
     KEY_A_CHI, KEY_S_TO, KEY_D_SHI},
    {KEY_F_HA, KEY_G_KI, KEY_H_KU, KEY_J_MA, KEY_K_NO, KEY_L_RI,
     KEY_SEMICOLON_RE, KEY_COLON_KE},
    {KEY_RIGHT_BRACKET_MU, KEY_Z_TSU, KEY_X_SA, KEY_C_SO, KEY_V_HI, KEY_B_KO,
     KEY_N_MI, KEY_M_MO},
    {KEY_COMMA_NE, KEY_DOT_RU, KEY_SLASH_NU, KEY_RO, KEY_SPACE, KEY_XFER,
     KEY_ROLL_UP, KEY_ROLL_DOWN},
    {KEY_INS, KEY_DEL, KEY_UP, KEY_LEFT, KEY_RIGHT, KEY_DOWN, KEY_HOME_CLR,
     KEY_HELP},
    {KEY_NUMPAD_MINUS, KEY_NUMPAD_DIVIDE, KEY_NUMPAD_7, KEY_NUMPAD_8,
     KEY_NUMPAD_9, KEY_NUMPAD_MULTIPLY, KEY_NUMPAD_4, KEY_NUMPAD_5},
    {KEY_NUMPAD_6, KEY_NUMPAD_PLUS, KEY_NUMPAD_1, KEY_NUMPAD_2, KEY_NUMPAD_3,
     KEY_NUMPAD_EQUAL, KEY_NUMPAD_0, KEY_NUMPAD_DOT},
    {KEY_NUMPAD_DOT, KEY_NFER, KEY_VF1, KEY_VF2, KEY_VF3, KEY_VF4, KEY_VF5,
     KEY_NULL},
    {KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL, KEY_HOME,
     KEY_NULL},
    {KEY_STOP, KEY_COPY, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6},
    {KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL},
    {KEY_SHIFT, KEY_CAPS, KEY_KANA, KEY_GRPH, KEY_CTRL, KEY_NULL, KEY_NULL,
     KEY_NULL},
    {KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL,
     KEY_NULL}};

const int keygroup_and_index_of[127][2] = {
    {15, 0},  // KEY_NULL
    {0, 1},  {0, 2},  {0, 3},  {0, 4},  {0, 5},  {0, 6},  {0, 7},  {1, 0},
    {1, 1},  {1, 2},  {3, 5},  {5, 5},  {5, 3},  {3, 7},  {2, 2},  {4, 0},
    {4, 1},  {4, 2},  {2, 7},  {4, 3},  {4, 4},  {4, 5},  {5, 7},  {5, 6},
    {3, 0},  {3, 1},  {2, 0},  {2, 3},  {3, 6},  {2, 4},  {2, 6},  {5, 4},
    {2, 1},  {5, 2},  {2, 5},  {5, 1},  {1, 3},  {1, 4},  {1, 5},  {3, 2},
    {3, 3},  {4, 6},  {4, 7},  {5, 0},  {6, 0},  {6, 1},  {6, 2},  {6, 3},
    {0, 0},  {1, 6},  {1, 7},  {3, 4},  {6, 4},  {6, 5},  {6, 6},  {6, 7},
    {7, 0},  {7, 1},  {7, 2},  {7, 3},  {7, 4},  {7, 5},  {7, 6},  {7, 7},
    {10, 1}, {11, 6}, {12, 0}, {12, 1}, {14, 0}, {14, 1}, {14, 2}, {14, 3},
    {14, 4}, {9, 1},  {8, 0},  {8, 5},  {8, 1},  {9, 5},  {9, 7},  {9, 6},
    {9, 2},  {9, 3},  {9, 4},  {8, 6},  {8, 7},  {9, 0},  {8, 2},  {8, 3},
    {8, 4},  {12, 2}, {12, 3}, {12, 4}, {12, 5}, {12, 6}, {12, 7}, {13, 0},
    {13, 1}, {13, 2}, {13, 3}, {10, 2}, {10, 3}, {10, 4}, {10, 5}, {10, 6}};

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

unsigned rot(unsigned n) { return (n >> 8) | ((n & 0xff) << 8); }

const unsigned popcount_data[16] = {0, 1, 1, 2, 1, 2, 2, 3,
                                    1, 2, 2, 3, 2, 3, 3, 4};
unsigned popcount(unsigned n) {
  return popcount_data[n & 0xF] + popcount_data[(n >> 4) & 0xF] +
         popcount_data[(n >> 8) & 0xF] + popcount_data[(n >> 12) & 0xF];
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
  if (ch <= 0x7F) {
    return true;
  }  // ASCII
  if (0xA1 <= ch && ch <= 0xDF) {
    return true;
  }  // Half-width katakana
  unsigned upper = ch >> 8, lower = ch & 0xFF;
  if (!((0x81 <= upper && upper <= 0x9F) || (0xE0 <= upper && upper <= 0xEF))) {
    return false;  // First byte out of range
  }
  // Second byte out of range
  if (upper & 1) {
    if (lower == 0x7F) {
      return false;
    }
    if (!(0x40 <= lower && lower <= 0x9E)) {
      return false;
    }
  } else {
    if (!(0x9F <= lower && lower <= 0xFC)) {
      return false;
    }
  }
  return true;
}
bool shiftjis_starting_byte(unsigned ch) {
  return (0x81 <= ch && ch <= 0x9F) || (0xE0 <= ch && ch <= 0xEF);
}

void wait_for_enter_key() {
  printf("--- Press enter key to continue ---");
  int ch = dos_getch();
  while (ch != '\r' && ch != '\n' && ch != EOF) {
    ch = dos_getch();
  }
  putchar('\r');
  putchar('\n');
  return;
}
void print_delimiter(char ch) {
  int i = 0;
  putchar('\r');
  putchar('\n');
  for (i = 0; i < 80; ++i) {
    putchar(ch);
  }
  putchar('\r');
  putchar('\n');
  return;
}
int print_string(const char *str, bool pause, bool kanji, int rows) {
  if (rows <= 0) {
    return 1;
  }
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
      putchar('\r');
      putchar('\n');
      col = 0;
      row++;
    }
    if (col == 80) {
      putchar('\r');
      putchar('\n');
      col = 0;
      row++;
    } else if (col == 79) {
      if (ch > 0xFF && valid_shiftjis(ch) && char_width(ch) == 2) {
        putchar('\r');
        putchar('\n');
        col = 0;
        row++;
      }
    }
    if (row == rows && pause) {
      wait_for_enter_key();
      row = 0;
    }
    if (ch == '\n' || ch == '\r') {
      continue;
    }
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