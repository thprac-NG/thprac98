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
int hex_digit(char ch);

#endif  // #ifndef THPRAC98_SRC_TSRUTILS_HPP_