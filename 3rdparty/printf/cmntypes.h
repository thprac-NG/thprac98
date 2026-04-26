// CoMmoN TYPES .H
// Type definitions that printf.c shares with stdio.cpp.
#ifndef THPRAC98_3RDPARTY_PRINTF_OUTFCTWP_H_
#define THPRAC98_3RDPARTY_PRINTF_OUTFCTWP_H_

#include "3rdparty/printf/printf.h"

// output function type
typedef void (*out_fct_type)(char character, void PRINTF_PTR* buffer,
                             size_t idx, size_t maxlen);

// wrapper (used as buffer) for output function type
typedef struct {
  void (*fct)(char character, void PRINTF_PTR* arg);
  void PRINTF_PTR* arg;
} out_fct_wrap_type;

#endif  // #ifndef THPRAC98_3RDPARTY_PRINTF_OUTFCTWP_H_