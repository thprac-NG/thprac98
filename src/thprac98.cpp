#include <stdio.h>
#include <string.h>  // memset, strcmp

#include "master.h"
#include "src/license.hpp"
#include "src/menu.hpp"
#include "src/utils.hpp"
#include "src/version.hpp"

bool pause = true;

void print_help_message() {
  print_string(
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
      "  --no-pause             No pause after printing several lines\n",
      pause);
  return;
}
void print_links() {
  print_string("(There's currently no links)\n", pause);
  return;
}
void print_version() {
  print_string("thprac98 ver." THPRAC98_VERSION
               "\n"
               "Website: https://github.com/thprac-NG/thprac98\n"
               "Website (main project thprac): "
               "https://github.com/touhouworldcup/thprac\n"
               "Special Thanks: \n"
               "You!\n",
               pause);
  return;
}
void print_license() {
  print_delimiter();
  puts("The license of thprac:");
  wait_for_enter_key();
  print_string(license_thprac98);
  wait_for_enter_key();

  print_delimiter();
  puts("The license of Lohmann's JSON:");
  wait_for_enter_key();
  print_string(license_lohmann_json);
  wait_for_enter_key();

  print_delimiter();
  puts("The license of master.lib:");
  wait_for_enter_key();
  print_string(license_master_lib);
  wait_for_enter_key();

  print_delimiter();
  puts("The license of Takeda Toshiya's MS-DOS Player:");
  wait_for_enter_key();
  print_string(license_takeda_msdos);
  wait_for_enter_key();
  return;
}

int main(int argc, char **argv) {
  int i = 0;
  for (i = 0; i < argc; ++i) {
    if (strcmp(argv[i], "--no-pause")) {
      pause = false;
    }
  }
  if (argc == 1) {
    print_help_message();
    return 0;
  }
  // Parse the standalone arguments
  if (argc == 2 || (argc == 3 && !pause)) {
    for (i = 1; i <= 2; ++i) {
      if (strcmp(argv[i], "--help") == 0) {
        print_help_message();
        return 0;
      }
      if (strcmp(argv[i], "--links") == 0) {
        print_links();
        return 0;
      }
      if (strcmp(argv[i], "--version") == 0) {
        print_version();
        return 0;
      }
      if (strcmp(argv[i], "--license") == 0) {
        print_license();
        return 0;
      }
    }
  }
  return 0;
}