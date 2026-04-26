#include "src/mainwrpr.hpp"

extern int wrapped_main(int argc, char far** argv);

int main_wrapper(char const far* program_name, int argument_size,
                 char const far* raw_argument) {
  static const char far* argv[20];
  static char argument_str[130];
  int i = 0, current_argc = 1, argument_str_len = 0;

  argv[0] = program_name;
  while (raw_argument[i] <= ' ' && i < argument_size) {
    i++;
  }
  if (i < argument_size) {
    argv[current_argc++] = argument_str;
    do {
      if (raw_argument[i] <= ' ') {
        argument_str[argument_str_len++] = '\0';
        argv[current_argc++] = argument_str + argument_str_len;
        do {
          ++i;
        } while (raw_argument[i] <= ' ');
      }
      argument_str[argument_str_len++] = raw_argument[i];
      i++;
    } while (i < argument_size);
  }
  argument_str[argument_str_len++] = '\0';
  return wrapped_main(current_argc, (char far**)(argv));
}
