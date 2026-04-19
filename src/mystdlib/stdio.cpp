#include "src/mystdlib/stdio.hpp"

#include "src/master.hpp"
#include "src/mystdlib/dos.hpp"

int getchar_(void) {
  REGS in_reg, out_reg;
  in_reg.h.ah = 0x01;
  intdos(&in_reg, &out_reg);
  return out_reg.h.al;
}

void _putchar(char character) {
  dos_putch(character);
  return;
}

void print_int(unsigned x) {
  unsigned tmp = 0;
  for (int i = 3; i >= 0; --i) {
    tmp = (x >> (i << 2)) & 0x0F;
    dos_putch(tmp < 10 ? '0' + tmp : tmp - 10 + 'A');
  }
  dos_putch(' ');
  return;
}

void _fputs_(const char far* str) {
  char ch = *str;
  while (ch) {
    putchar(ch);
    ch = *++str;
  }
  putchar('\n');
  return;
}