#ifndef THPRAC98_SRC_MYSTDLIB_STDIO_HPP_
#define THPRAC98_SRC_MYSTDLIB_STDIO_HPP_

#include "printf.h"
#include "src/master.hpp"

#ifndef EOF
#define EOF ((int)(-1))
#endif

#define FILE FILE_
#define FILE_HANDLER_POOL_SIZE 10
#define FOPEN_MAX FILE_HANDLER_POOL_SIZE
#define FILE_HANDLER_BUFFER_SIZE 16

struct FILE_;

#define stdin stdin_
#define stdout stdout_
#define stderr stderr_
extern const FILE_ *const stdin_;
extern const FILE_ *const stdout_;
extern const FILE_ *const stderr_;

#define fopen fopen_
FILE_ *fopen_(const char *filename, const char *mode);
#define fclose fclose_
int fclose_(FILE_ *stream);
#define fflush fflush_
int fflush_(FILE_ *stream);

#define SEEK_SET SEEK_SET_
#define SEEK_CUR SEEK_CUR_
#define SEEK_END SEEK_END_
#define SEEK_SET_ ((int)(0))
#define SEEK_CUR_ ((int)(1))
#define SEEK_END_ ((int)(2))
#define fseek fseek_
int fseek_(FILE_ *stream, long offset, int origin);
#define ftell ftell_
long ftell_(FILE_ *stream);

#define fgetc fgetc_
int fgetc_(FILE_ *stream);
#define fputc fputc_
int fputc_(int ch, FILE_ *stream);

#define fputs fputs_
int fputs_(const char *str, FILE_ *stream);

#define fprintf fprintf_
int fprintf_(FILE_ *stream, const char *format, ...);

#define getchar getchar_
int getchar_(void);
#define putchar putchar_
inline void putchar_(char character) {
  dos_putch(character);
  return;
}
#define puts puts_
inline void puts_(char const *str) {
  dos_puts(str);
  dos_putch('\n');  // The dos_puts function of master.lib doesn't print an
                    // extra CR/LF.
  return;
}
#define _fputs _fputs_
void _fputs_(char const far *str);

#endif  // #ifndef THPRAC98_SRC_MYSTDLIB_STDIO_HPP_