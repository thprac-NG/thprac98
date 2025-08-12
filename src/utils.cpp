#include "src/utils.hpp"

#include "master.h"

#ifdef DEBUG
bool test_stdint(void) {
#define test_stdint_macro(bit_length)                           \
  if (!((sizeof(uint##bit_length) * 8 == bit_length) &&         \
        ((uint##bit_length)(-1) > (uint##bit_length)(0)))) {    \
    return false;                                               \
  }                                                             \
  if (!((sizeof(int##bit_length) * 8 == bit_length) &&          \
        ((int##bit_length)(-1) < (int##bit_length)(0)))) {      \
    return false;                                               \
  }

  test_stdint_macro(8);
  test_stdint_macro(16);
  test_stdint_macro(32);
  return true;
#undef test_stdint_macro
}
#endif

bool is_pressed(key_t key) {
  int result = key_sense(keygroup_and_index_of[key][0]);
  return result & (0x01 << keygroup_and_index_of[key][1]);
}

unsigned rot(unsigned n) {
  return (n >> 8) | ((n & 0xff) << 8);
}