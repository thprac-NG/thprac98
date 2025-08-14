#include "src/test.hpp"

#include <stdio.h>

#include "src/utils.hpp"

bool test_stdint(void) {
#define test_stdint_macro(bit_length)                    \
    (sizeof(uint##bit_length) * 8 == bit_length) &&      \
    ((uint##bit_length)(-1) > (uint##bit_length)(0)) &&  \
    (sizeof(int##bit_length) * 8 == bit_length) &&       \
    ((int##bit_length)(-1) < (int##bit_length)(0))

  return test_stdint_macro(8) && test_stdint_macro(16) && test_stdint_macro(32);
#undef test_stdint_macro
}

int main() {
  printf("Testing stdint types... ");
  fflush(stdout);
  printf("%s.\n", test_stdint() == 0 ? "failed" : "OK");

  printf("test end.");
  return 0;
}