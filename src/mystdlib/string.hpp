#ifndef THPRAC98_SRC_MYSTDLIB_STRING_HPP_
#define THPRAC98_SRC_MYSTDLIB_STRING_HPP_

#include "src/mystdlib/size_t.hpp"

#define strlen strlen_
#define _fstrlen _fstrlen_
size_t strlen_(const char* str);
size_t _fstrlen_(const char far* str);
#define strcmp strcmp_
#define _fstrcmp _fstrcmp_
int strcmp_(const char* lhs, const char* rhs);
int _fstrcmp_(const char far* lhs, const char far* rhs);

#define THPRAC98_MEMCPY_TRIVIAL_COPY_THRESHOLD 32
#define memset memset_
#define _fmemset _fmemset_
void* memset_(void* dest, int ch, size_t count);
void far* _fmemset_(void far* dest, int ch, size_t count);
#define THPRAC98_MEMSET_TRIVIAL_COPY_THRESHOLD 16
#define memcpy memcpy_
#define _fmemcpy _fmemcpy_
void* memcpy_(void* dest, const void* src, size_t count);
void far* _fmemcpy_(void far* dest, const void far* src, size_t count);

#endif  // #ifndef THPRAC98_SRC_MYSTDLIB_STRING_HPP_