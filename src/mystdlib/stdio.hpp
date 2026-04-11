#ifndef THPRAC98_SRC_MYSTDLIB_STDIO_HPP_
#define THPRAC98_SRC_MYSTDLIB_STDIO_HPP_

#include "printf.h"
#include "src/master.hpp"

#define stdin stdin_
#define stdout stdout_
#define stderr stderr_
#define fflush fflush_
#define stdin_ 0
#define stdout_ 0
#define stderr_ 0
#define fflush_(argument)  // we don't have any buffer currently

#define getchar getchar_
int getchar_(void);
#define putchar putchar_
inline void putchar_(char character) {
  dos_putch(character);
  return;
}
#define puts puts_
inline void puts_(char const* str) {
  dos_puts(str);
  dos_putch('\n');  // The dos_puts function of master.lib doesn't print an
                    // extra CR/LF.
  return;
}

#endif  // #ifndef THPRAC98_SRC_MYSTDLIB_STDIO_HPP_