#ifndef THPRAC98_SRC_LAUNCHER_HPP_
#define THPRAC98_SRC_LAUNCHER_HPP_

#include "src/mystdlib/stdint.hpp"

struct md5_result_t {
  uint32_t data[4];
};
struct game_executables_t {
  char const far* filename;
  md5_result_t md5;
};

const int GAME_MAX_EXECUTABLES_TO_CHECK = 4;
struct game_t {
  int near (*load)(const char far* path);
  game_executables_t executables[GAME_MAX_EXECUTABLES_TO_CHECK];
};

const int GAME_COUNT = 5;
extern game_t games[GAME_COUNT];

int check_file_md5(md5_result_t& out, char const far* filename);

void launch_game(const char far* path);

#endif  // #ifndef THPRAC98_SRC_LAUNCHER_HPP_