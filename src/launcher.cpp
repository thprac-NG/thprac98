#include "src/launcher.hpp"

#include "src/entrance.hpp"
#include "src/mystdlib/ctype.hpp"
#include "src/mystdlib/stdio.hpp"

void launch_th01(const char far* path) {
  static char tmp_str[66];
  int i = 0;
  char ch = 0;

  tmp_str[0] = '\0';
  if (!isalpha(path[0]) || path[1] != ':') {
    printf(
        "Error: the path specified (%s) doesn't begin with a drive letter.\n",
        path);
    return;
  }
  while (i < 64 && (ch = path[i]) != '\0') {
    tmp_str[i] = toupper(ch);
    ++i;
  }
  if (i == 64) {
    printf(
        "Error: the path specified (%s) is too long. The maximum length "
        "accepted is 64.",
        path);
    return;
  }
  tmp_str[i] = '\0';
  load_th01(tmp_str);
  return;
}