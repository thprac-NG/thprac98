#include "src/mystdlib/string.hpp"

#include "src/mystdlib/dos.hpp"
#include "src/mystdlib/stdint.hpp"

#define THPRAC98_STRLEN_IMPLEMENTATION(func_name, ptr_type) \
  size_t func_name(const char ptr_type* str) {              \
    size_t ret = 0;                                         \
    while (str[ret] != '\0') {                              \
      ++ret;                                                \
    }                                                       \
    return ret;                                             \
  }
THPRAC98_STRLEN_IMPLEMENTATION(strlen_, )
THPRAC98_STRLEN_IMPLEMENTATION(_fstrlen_, far)

#define THPRAC98_STRCMP_IMPLEMENTATION(func_name, ptr_type)           \
  int func_name(const char ptr_type* lhs, const char ptr_type* rhs) { \
    int i = 0;                                                        \
    while (lhs[i] != '\0' && rhs[i] != '\0' && lhs[i] == rhs[i]) {    \
      ++i;                                                            \
    }                                                                 \
    if (lhs[i] == rhs[i]) { /* lhs[i] == rhs[i] == '\0' */            \
      return 0;                                                       \
    }                                                                 \
    return lhs[i] < rhs[i] ? -1 : 1;                                  \
  }
THPRAC98_STRCMP_IMPLEMENTATION(strcmp_, )
THPRAC98_STRCMP_IMPLEMENTATION(_fstrcmp_, far)

extern "C" void memset_helper(uint16_t stosd_seg, uint16_t stosd_off,
                              uint16_t stosd_count, uint16_t val);

#define THPRAC98_MEMSET_IMPLEMENTATION(func_name, ptr_type, dest_seg,   \
                                       dest_off)                        \
  void ptr_type* func_name(void ptr_type* dest, int ch, size_t count) { \
    int i = 0;                                                          \
    uint8_t val = (unsigned)(ch);                                       \
    if (count > THPRAC98_MEMCPY_TRIVIAL_COPY_THRESHOLD) {               \
      while (i < count && (dest_off + i) & 0x03 != 0) {                 \
        *((uint8_t ptr_type*)(dest) + i) = val;                         \
        ++i;                                                            \
      }                                                                 \
      memset_helper(dest_seg, dest_off + i, (uint16_t)(count - i) >> 2, \
                    ((uint16_t)(val) << 8) | val);                      \
      i += (count - i) & ~0x03;                                         \
    }                                                                   \
    while (i < count) {                                                 \
      *((uint8_t ptr_type*)(dest) + i) = val;                           \
      ++i;                                                              \
    }                                                                   \
    return dest;                                                        \
  }
THPRAC98_MEMSET_IMPLEMENTATION(memset_, , _DS, ((uint16_t)(dest)))
THPRAC98_MEMSET_IMPLEMENTATION(_fmemset_, far, FP_SEG(dest), FP_OFF(dest))

extern "C" void near memcpy_helper(uint16_t dest_seg, uint16_t dest_off,
                                   uint16_t src_seg, uint16_t src_off,
                                   uint16_t movsb_count);

#define THPRAC98_MEMCPY_IMPLEMENTATION(func_name, ptr_type, dest_seg,       \
                                       dest_off, src_seg, src_off)          \
  void ptr_type* func_name(void ptr_type* dest, const void ptr_type* src,   \
                           size_t count) {                                  \
    int i = 0;                                                              \
    if (count <= THPRAC98_MEMSET_TRIVIAL_COPY_THRESHOLD) {                  \
      while (i < count) {                                                   \
        *((uint8_t ptr_type*)(dest) + i) = *((uint8_t ptr_type*)(src) + i); \
        ++i;                                                                \
      }                                                                     \
    } else {                                                                \
      memcpy_helper(dest_seg, dest_off, src_seg, src_off, count);           \
    }                                                                       \
    return dest;                                                            \
  }
THPRAC98_MEMCPY_IMPLEMENTATION(memcpy_, , _DS, ((uint16_t)(dest)), _DS,
                               ((uint16_t)(src)))
THPRAC98_MEMCPY_IMPLEMENTATION(_fmemcpy_, far, FP_SEG(dest), FP_OFF(dest),
                               FP_SEG(src), FP_SEG(src))