#include "src/mystdlib/stdio.hpp"

#include "3rdparty/printf/cmntypes.h"
#include "3rdparty/printf/printf.h"
#include "src/master.hpp"
#include "src/mystdlib/dos.hpp"
#include "src/mystdlib/errno.hpp"
#include "src/mystdlib/stdarg.hpp"
#include "src/mystdlib/stdbool.hpp"
#include "src/mystdlib/stdint.hpp"

struct FILE_ {
  int file_handle;
  char *in_buffer, *out_buffer;
  unsigned char in_pos;   // index of the character to be read next
  unsigned char in_tail;  // length of the valid characters in the input buffer
  unsigned char out_pos;  // index of the slot to store the next output
                          // character
};

FILE_ file_handler_pool[FILE_HANDLER_POOL_SIZE];
char file_handler_in_buffers[FILE_HANDLER_POOL_SIZE][FILE_HANDLER_BUFFER_SIZE];
char file_handler_out_buffers[FILE_HANDLER_POOL_SIZE][FILE_HANDLER_BUFFER_SIZE];

FILE_ stdin_content, stdout_content, stderr_content;
const FILE_* const stdin_ = &stdin_content;
const FILE_* const stdout_ = &stdout_content;
const FILE_* const stderr_ = &stderr_content;

extern "C" void stdio_init(void);
void stdio_init(void) {
  int i = 0;
  for (i = 0; i < FILE_HANDLER_POOL_SIZE; ++i) {
    file_handler_pool[i].file_handle = -1;
    file_handler_pool[i].in_buffer = file_handler_in_buffers[i];
    file_handler_pool[i].out_buffer = file_handler_out_buffers[i];
  }
  stdout_content.file_handle = 1;
  stderr_content.file_handle = 2;
  return;
}

FILE_* fopen_(const char* filename, const char* mode) {
  int i = 0;
  unsigned char access_mode = 0;
  REGS in_reg, out_reg;
  SREGS in_sreg;
  FILE_* ret = NULL;

  for (i = 0; i < FILE_HANDLER_POOL_SIZE; ++i) {
    if (file_handler_pool[i].file_handle == -1) {
      ret = file_handler_pool + i;
      break;
    }
  }
  if (ret == NULL) {
    errno_ = E_FILE_HANDLER_POOL_FULL;
    return NULL;
  }

  if (mode[0] == '\0') {
    errno_ = E_INVALID_ARGUMENT;
    return NULL;
  }
  if (mode[1] == '+') {
    access_mode = 0x02;  // read/write
  } else if (mode[0] == 'r') {
    access_mode = 0x00;  // read
  } else {
    access_mode = 0x01;  // write
  }

  // Setting the DS:DX parameter of the DOS file functions, since they all
  // accept filenames via DS:DX.
  in_sreg.ds = FP_SEG(filename);
  in_reg.x.dx = FP_OFF(filename);
  if (mode[0] == 'w') {    // Truncate the file if using "w"/"w+" mode
    in_reg.x.ax = 0x4300;  // Get file attribute
    intdosx(&in_reg, &out_reg, &in_sreg);
    if (out_reg.x.cflag) {
      errno_ = out_reg.x.ax;
      return NULL;
    }
    in_reg.h.ah = 0x3C;  // Create/Truncate file
    in_reg.x.cx = out_reg.x.ax;
    intdosx(&in_reg, &out_reg, &in_sreg);
    if (out_reg.x.cflag) {
      errno_ = out_reg.x.ax;
      return NULL;
    }
  } else {               // Try to open the file first otherwise
    in_reg.h.ah = 0x3D;  // open existing file
    in_reg.h.al = access_mode;
    intdosx(&in_reg, &out_reg, &in_sreg);
    if (out_reg.x.cflag) {
      if (out_reg.x.ax == 0x02 && mode[0] != 'r') {  // file not found
        in_reg.x.cx = 0x00;                          // file attribute: default
        in_reg.h.ah = 0x3C;                          // create file
        intdosx(&in_reg, &out_reg, &in_sreg);
        if (out_reg.x.cflag) {
          errno_ = out_reg.x.ax;
          return NULL;
        }
      } else {
        errno_ = out_reg.x.ax;
        return NULL;
      }
    }
  }
  ret->file_handle = out_reg.x.ax;

  if (mode[0] == 'a') {
    in_reg.x.ax = 0x4202;  // Set current file position (relative to the end of
                           // the file)
    in_reg.x.bx = ret->file_handle;
    in_reg.x.cx = in_reg.x.dx = 0;
    intdos(&in_reg, &out_reg);
  }
  ret->in_pos = ret->in_tail = ret->out_pos = 0;
  return ret;
}

int fclose_(FILE_* stream) {
  REGS in_reg, out_reg;
  if (fflush_(stream) == EOF) {
    return EOF;
  }
  in_reg.h.ah = 0x3E;
  in_reg.x.bx = stream->file_handle;
  intdos(&in_reg, &out_reg);
  if (out_reg.x.cflag) {
    errno_ = out_reg.x.ax;
    return EOF;
  }
  return 0;
}

int fgetc_(FILE_* stream) {
  REGS in_reg, out_reg;
  SREGS in_sreg;
  if (stream->in_pos == stream->in_tail) {
    in_reg.h.ah = 0x3F;
    in_reg.x.bx = stream->file_handle;
    in_reg.x.cx = FILE_HANDLER_BUFFER_SIZE;
    in_sreg.ds = FP_SEG(stream->in_buffer);
    in_reg.x.dx = FP_OFF(stream->in_buffer);
    intdosx(&in_reg, &out_reg, &in_sreg);
    stream->in_pos = 0;
    stream->in_tail = out_reg.x.ax;
    if (out_reg.x.cflag || out_reg.x.ax == 0) {
      errno_ = out_reg.x.ax;
      return EOF;
    }
  }
  return (unsigned int)(unsigned char)(stream->in_buffer[stream->in_pos++]);
}

int fputc_(int ch, FILE_* stream) {
  REGS in_reg, out_reg;
  SREGS in_sreg;
  if (stream->out_pos == FILE_HANDLER_BUFFER_SIZE) {
    in_reg.h.ah = 0x40;
    in_reg.x.bx = stream->file_handle;
    in_reg.x.cx = FILE_HANDLER_BUFFER_SIZE;
    in_sreg.ds = FP_SEG(stream->out_buffer);
    in_reg.x.dx = FP_OFF(stream->out_buffer);
    intdosx(&in_reg, &out_reg, &in_sreg);
    if (out_reg.x.cflag) {
      errno_ = out_reg.x.ax;
      return EOF;
    }
    stream->out_pos = 0;
  }
  stream->out_buffer[stream->out_pos++] = ch;
  return (unsigned int)(unsigned char)(ch);
}

int fputs_(const char* str, FILE_* stream) {
  int i = 0;
  for (i = 0; str[i]; ++i) {
    if (fputc_(str[i], stream) == EOF) {
      return EOF;
    }
  }
  if (fputc_('\n', stream) == EOF) {
    return EOF;
  }
  return 0;
}

int fflush_(FILE_* stream) {
  int i = 0;
  REGS in_reg, out_reg;
  SREGS in_sreg;
  if (stream == NULL) {
    for (i = 0; i < FILE_HANDLER_POOL_SIZE; ++i) {
      if (file_handler_pool[i].file_handle == -1) {
        continue;
      }
      if (fflush_(file_handler_pool + i) == EOF) {
        return EOF;
      }
    }
    return 0;
  }
  if (stream->out_pos != 0) {
    in_reg.h.ah = 0x40;  // write to file
    in_reg.x.bx = stream->file_handle;
    in_reg.x.cx = stream->out_pos;
    in_sreg.ds = FP_SEG(stream->out_buffer);
    in_reg.x.dx = FP_OFF(stream->out_buffer);
    intdosx(&in_reg, &out_reg, &in_sreg);
    if (out_reg.x.cflag) {
      errno_ = out_reg.x.ax;
      return EOF;
    }
    stream->out_pos = 0;
  }
  return 0;
}

int fseek_(FILE_* stream, long offset, int origin) {
  REGS in_reg, out_reg;
  fflush_(stream);
  in_reg.h.ah = 0x42;  // set file position
  in_reg.h.al = origin;
  in_reg.x.bx = stream->file_handle;
  in_reg.x.cx = (offset >> 16);
  in_reg.x.dx = offset & 0xFFFF;
  intdos(&in_reg, &out_reg);
  if (out_reg.x.cflag) {
    errno_ = out_reg.x.ax;
    return 1;
  }
  stream->in_pos = stream->in_tail = 0;
  return 0;
}

long ftell_(FILE_* stream) {
  REGS in_reg, out_reg;
  in_reg.x.ax = 0x4201;  // set file position (with offset 0, and then get the
                         // file position relative to the begin of the file)
  in_reg.x.bx = stream->file_handle;
  in_reg.x.cx = in_reg.x.dx = 0;
  intdos(&in_reg, &out_reg);
  if (out_reg.x.cflag) {
    errno_ = out_reg.x.ax;
    return -1;
  }
  return ((long)(out_reg.x.dx) << 16) | out_reg.x.ax;
}

extern int _vsnprintf(out_fct_type out, char PRINTF_PTR* buffer,
                      const size_t maxlen, const char PRINTF_PTR* format,
                      va_list va);
extern void _out_fct(char character, void PRINTF_PTR* buffer, size_t idx,
                     size_t maxlen);
struct fprintf_helper_t {
  FILE_* stream;
};
void fprintf_print_one(char character, void PRINTF_PTR* arg) {
  fputc_(character, ((fprintf_helper_t*)(arg))->stream);
  return;
}

int fprintf_(FILE_* stream, const char* format, ...) {
  va_list va;
  int ret;
  out_fct_wrap_type out_fct_wrap;
  fprintf_helper_t argument;

  va_start(va, format);
  argument.stream = stream;
  out_fct_wrap.fct = fprintf_print_one;
  out_fct_wrap.arg = (void PRINTF_PTR*)(&argument);
  ret = _vsnprintf(_out_fct, (char PRINTF_PTR*)(uintptr_t)&out_fct_wrap,
                   (size_t)-1, format, va);
  va_end(va);
  return ret;
}

int getchar_(void) {
  REGS in_reg, out_reg;
  in_reg.h.ah = 0x01;
  intdos(&in_reg, &out_reg);
  return out_reg.h.al;
}

// for M.Paland's printf.h
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
