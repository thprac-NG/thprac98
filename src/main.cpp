#include "src/entrance.hpp"
#include "src/launcher.hpp"
#include "src/license.hpp"
#include "src/master.hpp"
#include "src/menu.hpp"
#include "src/mystdlib/dos.hpp"
#include "src/mystdlib/stdbool.hpp"
#include "src/mystdlib/stdio.hpp"
#include "src/mystdlib/string.hpp"
#include "src/utils.hpp"
#include "src/version.hpp"

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
      "  --no-pause             No pause after printing several lines\n");
  return;
}
void print_links(bool pause = true) {
  print_string("(There's currently no links)\n", pause);
  return;
}
void print_version() {
  print_string(
#ifndef THPRAC98_DEV
      "thprac98 ver." THPRAC98_VERSION
      "\n"
#else
      "thprac98 ver." THPRAC98_VERSION " (Build: " __DATE__ " " __TIME__
      ")\n"
#endif
      "Website: https://github.com/thprac-NG/thprac98"
      "\n"
      "Website (main project thprac): https://github.com/touhouworldcup/thprac"
      "\n"
      "Special Thanks: \n"
      "* nmlgc, for their ReC98 project, which provides tremendous help;\n"
      "* Ethy1ene, hicode002, and Mr_Alert, for their various help on PC-98 "
      "hardware\n"
      "  and software;\n"
      "* ...and you!\n");
  return;
}
void print_one_license(const char* name, const char* license_str,
                       bool pause = true) {
  print_delimiter();
  printf("The license of %s:\n", (const char far*)name);
  if (pause) {
    wait_for_enter_key();
  }
  print_string(license_str, pause);
  if (pause) {
    wait_for_enter_key();
  }
  return;
}
void print_license(bool pause = true) {
  print_one_license("thprac98", license_thprac98, pause);
  print_one_license("Lohmann's JSON", license_lohmann_json, pause);
  print_one_license("master.lib", license_master_lib, pause);
  print_one_license("Takeda Toshiya's MS-DOS Player", license_takeda_msdos,
                    pause);
  print_one_license("Marco Paland's printf", license_mpaland_printf, pause);
  return;
}

struct command_param_t {
  enum type {
    // Arguments that can be attached to any combination
    NO_PAUSE,
    FORCE,
    // Standalone commands
    HELP,
    LINKS,
    RESET,
    ROLL,
    LICENSE,
    VERSION,
    EXPORT,
    IMPORT,
    // Special commands
    LAUNCH,
    WITHOUT_THPRAC,
    SCAN,
    LAST_ENUM
  };
};
const char* param_str[command_param_t::LAST_ENUM] = {
    "--no-pause", "--force",          "--help",    "--links",  "--reset",
    "--roll",     "--license",        "--version", "--export", "--import",
    "--launch",   "--without-thprac", "--scan"};
bool param_set[command_param_t::LAST_ENUM];

void print_conflict_parameter_message(const char* str1, const char* str2) {
  printf("Conflicting parameters found: '%s' and '%s'.\n",
         (const char far*)str1, (const char far*)str2);
  return;
}

void print_int(unsigned);

int wrapped_main(int argc, char far** argv) {
  int i = 0, j = 0;
  int last_argument = -1, file_argument_start = -1;
  bool found_param = false, has_at_least_one_param = false;
  bool pause = true;

  memset(param_set, 0x00, sizeof(param_set));

  // Check the command-line argument strings first
  for (i = 1; i < argc; ++i) {
    found_param = false;
    last_argument = -1;
    for (j = 0; j < command_param_t::LAST_ENUM; ++j) {
      if (_fstrcmp(argv[i], param_str[j]) == 0) {
        if (j == command_param_t::NO_PAUSE) {
          pause = false;
        }
        if (param_set[j]) {
          printf("Multiple command: %s\n", (const char far*)param_str[j]);
          print_help_message();
          return 0;
        }
        param_set[j] = true;
        last_argument = j;
        found_param = has_at_least_one_param = true;
        continue;
      }
    }
    if (!found_param) {
      if (_fstrcmp(argv[i], "--") == 0) {
        break;
      }
      if (_fstrlen(argv[i]) >= 2u && argv[i][0] == '-' && argv[i][1] == '-') {
        printf("Unknown parameter: '%s'\n", (const char far*)argv[i]);
        print_help_message();
        return 0;
      }
      break;
    }
  }
  if (!has_at_least_one_param) {
    print_help_message();
    return 0;
  }

  // Some additional arguments
  // Note that 'thprac98 --scan 1 --force' isn't supported, so maybe the format
  // --scan=1 should be preferred?
  int scan_game_version = -1;
  if (last_argument == command_param_t::SCAN) {
    if (i == argc) {
      puts("Missing game version after --scan.");
      print_help_message();
      return 0;
    }
    if (_fstrlen(argv[i]) != 1 || argv[i][0] < '1' || argv[i][0] > '5') {
      puts("The game version should be a number between 1 and 5.");
      printf("However, `%s' is found.", (const char far*)argv[i]);
      print_help_message();
      return 0;
    }
    scan_game_version = argv[i][0] - '0';
    i++;
  }
  file_argument_start = i;

  // Standalone commands
  // These arguments can be attached with only --force and/or --no-pause.
  static const command_param_t::type standalone_commands[] = {
      command_param_t::HELP,    command_param_t::LINKS,
      command_param_t::RESET,   command_param_t::ROLL,
      command_param_t::LICENSE, command_param_t::VERSION,
      command_param_t::EXPORT,  command_param_t::IMPORT};
  for (i = 0; i < sizeof(standalone_commands) / sizeof(standalone_commands[0]);
       ++i) {
    if (param_set[standalone_commands[i]]) {
      for (j = 0; j < command_param_t::LAST_ENUM; ++j) {
        if (param_set[j] && j != command_param_t::FORCE &&
            j != command_param_t::NO_PAUSE && j != standalone_commands[i]) {
          print_conflict_parameter_message(param_str[standalone_commands[i]],
                                           param_str[j]);
          print_help_message();
          return 0;
        }
      }
      switch (standalone_commands[i]) {
        case command_param_t::HELP:
          print_help_message();
          break;
        case command_param_t::LINKS:
          print_links(pause);
          break;
        case command_param_t::RESET:
          puts("(The reset feature isn't ready yet)");
          break;
        case command_param_t::ROLL:
          puts("(The roll feature isn't ready yet)");
          break;
        case command_param_t::LICENSE:
          print_license(pause);
          break;
        case command_param_t::VERSION:
          print_version();
          break;
        case command_param_t::EXPORT:
          puts("(The export feature isn't ready yet)");
          break;
        case command_param_t::IMPORT:
          puts("(The import feature isn't ready yet)");
          break;
      }
    }
  }

  // Special arguments
  if (param_set[command_param_t::SCAN]) {
    if (param_set[command_param_t::LAUNCH]) {
      print_conflict_parameter_message(param_str[command_param_t::SCAN],
                                       param_str[command_param_t::LAUNCH]);
      print_help_message();
      return 0;
    }
    if (param_set[command_param_t::WITHOUT_THPRAC]) {
      print_conflict_parameter_message(
          param_str[command_param_t::SCAN],
          param_str[command_param_t::WITHOUT_THPRAC]);
      print_help_message();
      return 0;
    }
    puts("(The scan feature isn't ready yet)");
    scan_game_version;  // To disable the warning
  }
  if (param_set[command_param_t::LAUNCH]) {
    launch_th01(argv[file_argument_start]);
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