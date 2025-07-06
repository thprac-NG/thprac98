#include "src/utils.hpp"

#include "master.h"

bool is_pressed(key_t key) {
  int result = key_sense(keygroup_and_index_of[key][0]);
  return result & (0x01 << keygroup_and_index_of[key][1]);
}

unsigned rot(unsigned n) {
  return (n >> 8) | ((n & 0xff) << 8);
}