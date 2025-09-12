#include <stdio.h>
#include <string.h>  // memset

#include "master.h"

#include "src/utils.hpp"
#include "src/menu.hpp"

/**
 * @brief Print a Shift-JIS-encoded string to the screen.
 * @details Invalid 1-byte Shift-JIS codes will be converted by "?" (0x3F), and
 *          2-byte ones will be converted by full-width "?" (0x8148).
 *
 * @param str the string
 * @param pause If pass with `true`, wait for a key input after printing
 *              several rows (default to 24, configurable in parameter `rows`).
 * @param kanji If pass with `true`, combine bytes of adjacent characters into a
 *              Shift-JIS 2-byte character if possible.
 *              If pass with `false`, treat every character as a Shift-JIS
 *              1-byte character.
 * @param rows The number of printed rows before a pause. Must be >0.
 *
 * @returns 0 if succeed, 1 if `rows` <= 0.
 */
int print_string(const char* str, bool pause = false, bool kanji = true,
                 int rows = 24) {
  if (rows <= 0) { return 1; }
  if (kanji) {
    kanji_mode();
  } else {
    graph_mode();
  }
  int col = 0;
  // TODO: finish it.
  return 0;
}

void print_help_message() {
  printf(
    "Usage: thprac98 [options] file...\n"
    "Options:\n"
    "  --help                 Show this help message\n"
    "  --launch               Launch the game\n"
    "  --force                Ignore any warning\n"
    "  --without-thprac       Launch the game without thprac injected\n"
    "  --links                Show \"Links\"\n"
    "  --reset                Reset configuration file\n"
    "  --roll                 Use the rolling feature\n"
    "  --scan <game version>  Scan the file location of a game\n"
    "  --export               Export the save data of a game\n"
    "  --import               Import the save data of a game\n"
    "  --license              Show license\n"
    "  --version              Show the version of thprac98\n"
  );
  return;
}

int main(int argc, char** argv) {
  // Parse the standalone arguments
  enum standalone_argument_t {
    ARGUMENT_HELP,
    ARGUMENT_LINKS,
    ARGUMENT_RESET,
    ARGUMENT_ROLL,
    ARGUMENT_LICENSE,
    ARGUMENT_VERSION
  };
  print_help_message();
  return 0;
}