// A small utils file (#include-d by utils.hpp), since the utils.hpp consumes
// too much space for a TSR.
#ifndef THPRAC98_SRC_TSRUTILS_HPP_
#define THPRAC98_SRC_TSRUTILS_HPP_

#if (ANCIENT_CXX == 1)
#define bool unsigned char
#define false ((bool)(0))
#define true ((bool)(1))
#endif

#if (ANCIENT_CXX == 1) || (__cplusplus < CPLUSPLUS20)
#if (ANCIENT_CXX == 0)
static_assert(sizeof(signed char) == 1 &&
                  std::is_signed<signed char>::value == true,
              "Type 'signed char' should have a size of 1, and be signed.");
static_assert(sizeof(unsigned char) == 1 &&
                  std::is_signed<unsigned char>::value == false,
              "Type 'unsigned char' should have a size of 1, and be unsigned.");
#endif
typedef signed char int8;
typedef unsigned char uint8;
#else
typedef int8_t int8;
typedef uint8_t int uint8;
#endif

#if (ANCIENT_CXX == 1)
typedef signed short int16;
typedef unsigned short uint16;
typedef signed long int32;
typedef unsigned long uint32;
#else
typedef int16_t int16;
typedef uint16_t uint16;
typedef int32_t int32;
typedef uint32_t uint32;
#endif

#ifdef __INTELLISENSE__
#undef MK_FP
#define MK_FP(seg, off) ((void*)(seg * 16 + off))
#endif

// Converts a hexadecimal digit into an `int` type. Can be in uppercase or
// lowercase.
// If failed, returns -1.
int hex_digit(char ch) {
  if ('0' <= ch && ch <= '9') {
    return ch - '0';
  }
  if ('a' <= ch && ch <= 'f') {
    return ch - 'a' + 10;
  }
  if ('A' <= ch && ch <= 'F') {
    return ch - 'A' + 10;
  }
  return -1;
}

struct inject_code_t {
  char filename[13];

  enum { MAX_LENGTH = 10 };
  unsigned segment;
  unsigned offset;
  size_t length;
  unsigned char original_memory[MAX_LENGTH];
  unsigned char patched_memory[MAX_LENGTH];
  // The replacement only happens when the actually memory pattern matches the
  // pattern in `original_memory`, ignoring the index of value 0 in the
  // following array.
  bool variable_memory_position[MAX_LENGTH];

  // I know the naming is in reverse to the suggestion in the Google Style,
  // but the thing is TCC doesn't support shadowing, and the method of using
  // member functions to access member variables seems to be too bloated here...
  //
  // The strings `original_memory_` and `patched_memory_` should be in
  // hexadecimal (both uppercase and lowercase letters are accepted), the
  // digits beyond the (2 * `length_`)-th position are ignored, and the string
  // is 0-padded to have a size of (2 * `length_`) if having a smaller size.
  // For example, if `length_` == 5 and `original_memory_` == "ABCDE",
  // then it will be treated as "ABCDE00000".
  //
  // The string `variable_memory_position_` should be a 01-string, and the
  // method of changing its length is same as above, except that its target
  // length is `length_`.
  inject_code_t(const char* filename_, unsigned segment_, unsigned offset_,
                size_t length_, const char* original_memory_,
                const char* patched_memory_,
                const char* variable_memory_position_) {
    strcpy(filename, filename_);
    segment = segment_;
    offset = offset_;
    length = length_;
    int i = 0;
    for (i = 0; i < MAX_LENGTH; ++i) {
      if (i >= length_) {
        original_memory[i] = patched_memory[i] = 0;
        variable_memory_position[i] = false;
      } else {
        original_memory[i] =
            *original_memory_ ? hex_digit(*original_memory_) : 0;
        if (*original_memory_) {
          original_memory_++;
        }
        original_memory[i] =
            (original_memory[i] << 4) |
            (*original_memory_ ? hex_digit(*original_memory_) : 0);
        if (*original_memory_) {
          original_memory_++;
        }
        patched_memory[i] = *patched_memory_ ? hex_digit(*patched_memory_) : 0;
        if (*patched_memory_) {
          patched_memory_++;
        }
        patched_memory[i] =
            (patched_memory[i] << 4) |
            (*patched_memory_ ? hex_digit(*patched_memory_) : 0);
        if (*patched_memory_) {
          patched_memory_++;
        }
        variable_memory_position[i] =
            *variable_memory_position_ ? (*variable_memory_position_ - '0') : 0;
        if (*variable_memory_position_) {
          variable_memory_position_++;
        }
      }
    }
  }
};

#endif  // #ifndef THPRAC98_SRC_TSRUTILS_HPP_