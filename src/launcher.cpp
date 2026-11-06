#include "src/launcher.hpp"

#include "src/entrance.hpp"
#include "src/mystdlib/ctype.hpp"
#include "src/mystdlib/stdbool.hpp"
#include "src/mystdlib/stdint.hpp"
#include "src/mystdlib/stdio.hpp"
#include "src/utils.hpp"

// clang-format off
game_t games[GAME_COUNT] = {
  {
    load_th01,
    {
      {
        "ZUNSOFT.COM",
        {{0x975454delu, 0xd9eb9135lu, 0x5214b137lu, 0x2d88b4a8lu}}
      },
      {
        "OP.EXE",
        {{0xe1534eadlu, 0xfb42a0f1lu, 0x6bf882dalu, 0x8c72d69blu}}
      },
      {
        "FUUIN.EXE",
        {{0xf7d6aa2clu, 0x912be398lu, 0x32da082alu, 0xb4dd977alu}}
      },
      {
        "REIIDEN.EXE",
        {{0xa1d59ff3lu, 0xf26c4246lu, 0xd707f261lu, 0x758687fclu}}
      }
    }
  },
  {
    load_th02,
    {
      {
        "ZUN.COM",
        {{0xd3ddd984lu, 0xc6c8be2elu, 0xba3b704blu, 0xdf9cecc4lu}}
      },
      {
        "OP.EXE",
        {{0x9d83b29flu, 0x11380fb5lu, 0xd4980b9dlu, 0x0ecd70fblu}}
      },
      {
        "MAIN.EXE",
        {{0x77e0ce96lu, 0x46e6a813lu, 0x7622e70alu, 0x09f9a9f3lu}}
      },
      {
        "MAINE.EXE",
        {{0xb371f9e6lu, 0xf9c03673lu, 0x893fe5fclu, 0x1e038057lu}}
      }
    }
  }
};
// clang-format on

const md5_result_t INITIAL_MD5_VALUE = {
    {0x67452301lu, 0xefcdab89lu, 0x98badcfelu, 0x10325476lu}};

void append_md5(md5_result_t& out, const uint32_t message[16]) {
  static uint32_t k[64] = {
      0xd76aa478lu, 0xe8c7b756lu, 0x242070dblu, 0xc1bdceeelu, 0xf57c0faflu,
      0x4787c62alu, 0xa8304613lu, 0xfd469501lu, 0x698098d8lu, 0x8b44f7aflu,
      0xffff5bb1lu, 0x895cd7belu, 0x6b901122lu, 0xfd987193lu, 0xa679438elu,
      0x49b40821lu, 0xf61e2562lu, 0xc040b340lu, 0x265e5a51lu, 0xe9b6c7aalu,
      0xd62f105dlu, 0x02441453lu, 0xd8a1e681lu, 0xe7d3fbc8lu, 0x21e1cde6lu,
      0xc33707d6lu, 0xf4d50d87lu, 0x455a14edlu, 0xa9e3e905lu, 0xfcefa3f8lu,
      0x676f02d9lu, 0x8d2a4c8alu, 0xfffa3942lu, 0x8771f681lu, 0x6d9d6122lu,
      0xfde5380clu, 0xa4beea44lu, 0x4bdecfa9lu, 0xf6bb4b60lu, 0xbebfbc70lu,
      0x289b7ec6lu, 0xeaa127falu, 0xd4ef3085lu, 0x04881d05lu, 0xd9d4d039lu,
      0xe6db99e5lu, 0x1fa27cf8lu, 0xc4ac5665lu, 0xf4292244lu, 0x432aff97lu,
      0xab9423a7lu, 0xfc93a039lu, 0x655b59c3lu, 0x8f0ccc92lu, 0xffeff47dlu,
      0x85845dd1lu, 0x6fa87e4flu, 0xfe2ce6e0lu, 0xa3014314lu, 0x4e0811a1lu,
      0xf7537e82lu, 0xbd3af235lu, 0x2ad7d2bblu, 0xeb86d391lu};
  static uint8_t shift_ammount[64] = {
      7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
      5, 9,  14, 20, 5, 9,  14, 20, 5, 9,  14, 20, 5, 9,  14, 20,
      4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
      6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21};

  uint32_t a = out.data[0], b = out.data[1], c = out.data[2], d = out.data[3];
  int i;
  uint32_t f;
  unsigned int g;
  for (i = 0; i < 64; ++i) {
    switch (i >> 4) {
      case 0: {
        f = (b & c) | (~b & d);
        g = i;
        break;
      }
      case 1: {
        f = (d & b) | (~d & c);
        g = (5 * i + 1) & 0x0F;
        break;
      }
      case 2: {
        f = b ^ c ^ d;
        g = (3 * i + 5) & 0x0F;
        break;
      }
      case 3: {
        f = c ^ (b | ~d);
        g = (7 * i) & 0x0F;
        break;
      }
    }
    f += a + k[i] + message[g];
    a = d;
    d = c;
    c = b;
    b += (f << shift_ammount[i]) | (f >> (32 - shift_ammount[i]));
  }

  out.data[0] += a;
  out.data[1] += b;
  out.data[2] += c;
  out.data[3] += d;
  return;
}

int check_file_md5(md5_result_t& out, char const far* filename) {
  static uint8_t buffer[64];
  int buffer_len = 0;

  FILE* fin = fopen(filename, "rb");
  if (fin == NULL) {
    return -1;
  }
  memcpy((void*)(&out), (const void*)(&INITIAL_MD5_VALUE), sizeof(out));
  uint32_t file_size = 0;
  int ch;
  while ((ch = fgetc(fin)) != EOF) {
    buffer[buffer_len++] = ch;
    file_size++;
    if (buffer_len == 64) {
      append_md5(out, (uint32_t const*)(buffer));
      buffer_len = 0;
    }
  }
  buffer[buffer_len++] = 0x80;
  if (buffer_len == 64) {
    append_md5(out, (uint32_t const*)(buffer));
    buffer_len = 0;
  }
  while (buffer_len != 56) {
    buffer[buffer_len++] = 0x00;
    if (buffer_len == 64) {
      append_md5(out, (uint32_t const*)(buffer));
      buffer_len = 0;
    }
  }
  *(uint32_t*)(&buffer[buffer_len]) = file_size << 3;
  buffer_len += 4;
  *(uint32_t*)(&buffer[buffer_len]) = 0;
  buffer_len += 4;
  append_md5(out, (uint32_t const*)(buffer));
  fclose(fin);
  return 0;
}

void launch_game(const char far* path) {
  // TODO: Check the file size of OP.EXE to narrow down the possible game title
  // count to <=1. Checking the file size using file handles can be done using
  // LSEEK.
  static char new_path[70];
  static char tmp_str[85];
  int i = 0, j = 0, k = 0;
  int path_len = 0;
  char ch = 0;
  md5_result_t md5;
  bool game_match = true, game_found = false;

  new_path[0] = '\0';
  if (!isalpha(path[0]) || path[1] != ':') {
    printf(
        "Error: the path specified (%s) doesn't begin with a drive letter.\r\n",
        path);
    return;
  }
  while (path_len < 64 && (ch = path[path_len]) != '\0') {
    new_path[path_len++] = toupper(ch);
  }
  if (path_len == 64) {
    printf(
        "Error: the path specified (%s) is too long. The maximum length "
        "accepted is 64.\r\n",
        path);
    return;
  }
  new_path[path_len] = '\0';
  if (new_path[path_len - 1] == '\\') {
    new_path[--path_len] = '\0';
  }
  printf("New_path: `%s`\n", (const char far*)(new_path));

  for (i = 0; i < GAME_COUNT; ++i) {
    if (games[i].load == NULL) {
      continue;
    }
    game_match = true;
    for (j = 0; j < GAME_MAX_EXECUTABLES_TO_CHECK; ++j) {
      if (games[i].executables[j].filename == NULL) {
        continue;
      }
      snprintf(tmp_str, sizeof(tmp_str), "%s\\%s", (const char far*)(new_path),
               (const char far*)(games[i].executables[j].filename));
      printf("Checking file %s...\r\n", (const char far*)(tmp_str));
      if (check_file_md5(md5, tmp_str)) {
        game_match = false;
        break;
      }
      printf("MD5: %08lx, %08lx, %08lx, %08lx\r\n", md5.data[0], md5.data[1],
             md5.data[2], md5.data[3]);
      for (k = 0; k < 4; ++k) {
        if (md5.data[k] != games[i].executables[j].md5.data[k]) {
          game_match = false;
          break;
        }
      }
      if (!game_match) {
        break;
      }
    }
    if (game_match) {
      (games[i].load)(new_path);
      game_found = true;
      break;
    }
  }
  if (!game_found) {
    printf("Error: Cannot found any supported game.\r\n");
    return;
  }
  return;
}