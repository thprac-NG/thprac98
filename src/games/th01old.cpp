#include <MEMORY.H>
#include <dos.h>
#include <stdio.h>
#include <string.h>

#include "masters.h"
#include "src/tsrutils.hpp"

enum constant_t { BS_MENU_WIDTH = 16 };

// Global variables. The normal global variables will be released once the
// program has TSR-ed, so we can't modified their value after then.
// Thus, instead of defining global variables in the normal way, we packed all
// the global variables we need into a struct and allocates some memory for an
// instance of the struct.
struct global_vars {
  void interrupt (*prev_int8)(...);

  bool down[7];
  bool pressed[7];
  int cur;

  bool injection_failed;

  unsigned char bs_covered_tram[4][BS_MENU_WIDTH * 2];
  unsigned char bs_covered_tram_attr[4][BS_MENU_WIDTH * 2];

  inject_code_t inject_codes[10];
  inject_code_t far* inject_batches[5][5];
};
global_vars far* global;

void interrupt my_int8(...);
void far inject();
void backspace_menu(bool save);

int main() {
  // INT 21h/48h: BX = number of paragraphs (16 bytes) to allocate
  // Returns: if successed, AX = the segment of the allocated memory,
  //          if failed, CF = 1
  REGS in_reg, out_reg;
  in_reg.h.ah = 0x48;
  in_reg.x.bx = sizeof(global_vars) / 16 + 1;
  int86(0x21, &in_reg, &out_reg);
  if (out_reg.w.cflag) {
    printf("Failed to allocate memory.");
    return 0;
  }

  global = (global_vars far*)(MK_FP(out_reg.x.ax, 0));
  global->prev_int8 = _dos_getvect(0x08);
  _fmemset(global->down, 0x00, sizeof(global->down));
  _fmemset(global->pressed, 0x00, sizeof(global->pressed));
  global->cur = 0;
  global->injection_failed = false;
  _fmemset(global->inject_batches, 0x00, sizeof(global->inject_batches));

  // Invicible
  global->inject_codes[0] =
      inject_code_t("REIIDEN.EXE", 0x0B50, 0x29A9, 2, "7E2F", "89DB", "11");
  global->inject_codes[1] =
      inject_code_t("REIIDEN.EXE", 0x0B50, 0x29BA, 8, "C41EFC4726FE4F15",
                    "C606AF0000E9A2FD", "11111111");
  global->inject_batches[0][0] = &global->inject_codes[0];
  global->inject_batches[0][1] = &global->inject_codes[1];
  // Infinite Lives
  global->inject_codes[2] =
      inject_code_t("REIIDEN.EXE", 0x0B50, 0x29BE, 8, "26FE4F15FF0EE000",
                    "8DB400008DBD0000", "11111111");
  global->inject_codes[3] = inject_code_t("REIIDEN.EXE", 0x1967, 0x198B, 5,
                                          "9A95085828", "908DB40000", "11100");
  global->inject_batches[1][0] = &global->inject_codes[2];
  global->inject_batches[1][1] = &global->inject_codes[3];

  // text_putc(19, 19, 'o');
  my_int8();  // One must call my_int8 once in main, and I don't know why

  printf("%lx\n", (long)global->prev_int8);
  _dos_setvect(0x08, my_int8);
  keep(0, 0x800);
  return 0;
}

/*

NOPs:
1byte: 90 (nop)
2bytes: 89 xx (mov r16, r16). C0 (ax), DB (bx), C9 (cx), D2 (dx),
                              E4 (sp), ED (bp), F6 (si), FF (di)
3bytes: 8D xx 00 (lea r16, [r16 + 00h]). 5F (bx), 6E (bp), 74 (si), 7D (di)
4bytes: 8D xx 00 00 (lea r16, [r16 + 0000h]). 9F (bx), AE (bp), B4 (si), BD (di)

The instruction "A1 72 3E" is in 1E36:0007.
(temp) 1B50 -> 1A7D, 2967 -> 2894

Note that these addresses are from Ghidra, having a 1000:0 offset.
F1: Invincibile (
  1B50:29A9 | 7E 2F -> 89 DB
  1B50:29BA | C4 1E FC 47 26 FE 4F 15 -> C6 06 AF 00 00 E9 A2 FD
)
F2: Inf. Lives (
  1B50:29BE | 26 FE 4F 15 FF 0E E0 00 -> 8D B4 00 00 8D BD 00 00
  2967:198B | 9A 95 08 58 28 -> 90 8D B4 00 00
                       ^^ ^^  Note that this is an absolute call, the segment
                              address might differ.
)
F3: Inf. Bombs
F4: Inf. Card Combo
F5: Inf. Item Combo
F6: Everlasting BGM
*/

void interrupt my_int8(...) {
  if (global->injection_failed) {
    inject();
  }

  text_putc(20, 20, global->cur + '0');
  global->cur = (global->cur + 1) % 10;

  unsigned char prev_down[7];
  _fmemcpy(prev_down, global->down, sizeof(global->down));
  global->down[0] = !!(key_sense(0x01) & 0x40);  // backspace
  if (!prev_down[0] && global->down[0]) {
    global->pressed[0] ^= 1;
    backspace_menu(true);
  }

// For some reason, the following loop doesn't work properly, so I have to
// unwarp it manually.
#if 0
  int tmp = key_sense(0x0C);
  int i = 0;
  for (i = 1; i <= 2; ++i) {
    global->down[i] = !!(tmp & (1 << (i + 1)));
    if (!prev_down[i] && global->down[i]) {
      global->pressed[i] ^= 1;
      backspace_menu(false);
    }
  }
#endif

  int tmp = key_sense(0x0C);
  bool changed = false;
#define THPRAC98_CHECK_FX(i)                  \
  global->down[i] = !!(tmp & (1 << (i + 1))); \
  if (!prev_down[i] && global->down[i]) {     \
    global->pressed[i] ^= 1;                  \
    changed = true;                           \
  }
  THPRAC98_CHECK_FX(1);
  THPRAC98_CHECK_FX(2);
#undef THPRAC98_CHECK_FX
  if (changed) {
    backspace_menu(false);
    inject();
  }

  text_putc(20, 21, global->down[0] + '0');
  text_putc(21, 21, global->down[1] + '0');
  text_putc(22, 21, global->down[2] + '0');

  text_putc(20, 22, global->pressed[0] + '0');
  text_putc(21, 22, global->pressed[1] + '0');
  text_putc(22, 22, global->pressed[2] + '0');

  global->prev_int8();
  return;
}

void backspace_menu(bool save) {
  int i = 0;
  const int width = BS_MENU_WIDTH;

  unsigned char far* ptr = (unsigned char far*)(MK_FP(0xA000, 0));
  unsigned char far* ptr_attr = (unsigned char far*)(MK_FP(0xA200, 0));
  if (global->pressed[0]) {
    if (save) {
      for (i = 0; i <= 3; ++i) {
        _fmemcpy(global->bs_covered_tram[i], ptr + 0xa0 * i, width * 2);
        _fmemcpy(global->bs_covered_tram_attr[i], ptr_attr + 0xa0 * i,
                 width * 2);
      }
    }
    text_putnsa(0, 0, "+--------------+", width, TX_WHITE);
    text_putnsa(0, 1, "|              |", width, TX_WHITE);
    text_putnsa(0, 2, "|              |", width, TX_WHITE);
    text_putnsa(0, 3, "+--------------+", width, TX_WHITE);
    text_putnsa(1, 1, "F1: Invincible", width - 2,
                global->pressed[1] ? TX_GREEN : TX_WHITE);
    text_putnsa(1, 2, "F2: Inf. Lives", width - 2,
                global->pressed[2] ? TX_GREEN : TX_WHITE);
  } else {
    for (i = 0; i <= 3; ++i) {
      _fmemcpy(ptr + 0xa0 * i, global->bs_covered_tram[i], width * 2);
      _fmemcpy(ptr_attr + 0xa0 * i, global->bs_covered_tram_attr[i], width * 2);
    }
  }
  return;
}

void far inject_one(bool check, inject_code_t* inject_codes[]) {}

void far inject() {
  REGS in_reg, out_reg;
  in_reg.h.ah = 0x62;
  int86(0x21, &in_reg, &out_reg);
  unsigned psp_seg = out_reg.x.bx;

  unsigned env_seg = *(unsigned far*)(MK_FP(psp_seg, 0x2C));
  char far* cur = (char far*)(MK_FP(env_seg, 0));
  do {
    cur += _fstrlen(cur) + 1;
  } while (*cur != '\0');
  cur++;  // Now, the pointer `cur` contains the path of the current executable.

  cur = _fstrrchr(cur, '\\') + 1;
  // The offset of segment from the original executable is (psp_seg + 0x10).
}