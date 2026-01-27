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

/*
  The Traditional Chinese translation of Touhou PC-98 can only be run on an
  emulator, since it modifies the kanji ROM with the following slot (in JIS):

    0x7921, 0x6e24, 0x6e25, 0x6e26, 0x6e28, 0x7346, 0x7348, 0x7349, 0x734b,
    0x734c, 0x734d, 0x724f, 0x734f, 0x7350, 0x7351, 0x7352, 0x7354, 0x7255,
    0x7357, 0x7258, 0x7358, 0x7259, 0x7359, 0x725a, 0x6e5b, 0x735b, 0x735c,
    0x735d, 0x6e5e, 0x6e5f, 0x725f, 0x7260, 0x7360, 0x7361, 0x7162, 0x7362,
    0x7163, 0x7363, 0x7164, 0x7364, 0x7165, 0x7365, 0x7166, 0x7266, 0x7366,
    0x7167, 0x7367, 0x7168, 0x7268, 0x7368, 0x7169, 0x7369, 0x716a, 0x736a,
    0x716b, 0x736b, 0x726c, 0x736c, 0x726d, 0x736d, 0x726e, 0x736e, 0x726f,
    0x736f, 0x7270, 0x7370, 0x7371, 0x6f72, 0x7272, 0x7372, 0x6f73, 0x7373,
    0x7174, 0x7374, 0x7175, 0x7375, 0x7176, 0x7376, 0x7277, 0x7377, 0x7178,
    0x7378, 0x7279, 0x7379, 0x6e7a, 0x6f7a, 0x717a, 0x727a, 0x737a, 0x6e7b,
    0x727b, 0x737b, 0x717c, 0x727c, 0x737c, 0x717d, 0x737d, 0x6f7e, 0x717e,
    0x727e, 0x737e.
*/