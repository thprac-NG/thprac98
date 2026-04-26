// .COM file EMBEDder .cpp
#include "codegen/common.hpp"
#include "src/mystdlib/ctype.hpp"
#include "src/mystdlib/limits.hpp"
#include "src/mystdlib/stdio.hpp"
#include "src/mystdlib/string.hpp"
#include "src/utils.hpp"

#define THPRAC98_AUTOGEN_WARNING_TEXT                            \
  "// WARNING: THIS FILE IS AUTO-GENERATED" ENDL                 \
  "// To modify this file, rebuild the TH0X.COM files and " ENDL \
  "// use codegen/comembed.cpp to regenerate this file." ENDL    \
  "// clang-format off" ENDL ENDL

const int COM_FILE_COUNT = 1;
int com_file_size[COM_FILE_COUNT + 1];

char tmp_str[30];

int init_com_file_size(void) {
  int i = 0;
  FILE *fin = NULL;
  long tmp = 0;
  for (i = 1; i <= COM_FILE_COUNT; ++i) {
    sprintf((char PRINTF_PTR *)(tmp_str), "th0%d.com", i);
    fin = fopen(tmp_str, "r");
    if (fin == NULL) {
      printf("Cannot open file th0%d.com.\n", i);
      print_errno();
      return 1;
    }
    fseek(fin, 0, SEEK_END);
    tmp = ftell(fin);
    if (tmp > INT_MAX) {
      printf("th0%d.com is too large: Expecting a size <= %d, but found %ld.\n",
             i, INT_MAX, tmp);
      return 1;
    }
    com_file_size[i] = tmp;
    fclose(fin);
  }
  return 0;
}

// TODO: Add failure detection of fprintf.
int generate_tsrdata(void) {
  int i = 0, ch = 0, col = 0, j = 0, ret = 0;
  FILE *fin = NULL, *fout = NULL;

  ret = init_com_file_size();
  if (ret) {
    return ret;
  }

  // Generate tsrdata.hpp
  fout = fopen("src/tsrdata.hpp", "w");
  if (fout == NULL) {
    puts("Cannot open file src/tsrdata.hpp.");
    print_errno();
    return 1;
  }
  fprintf(fout, THPRAC98_AUTOGEN_WARNING_TEXT);
  for (i = 1; i <= COM_FILE_COUNT; ++i) {
    fprintf(fout, "extern unsigned char th0%d_com_data[%d];\n", i,
            com_file_size[i]);
  }
  fclose(fout);

  // Generate tsrdata.cpp
  fout = fopen("src/tsrdata.cpp", "w");
  if (fout == NULL) {
    puts("Cannot open file src/tsrdata.cpp.");
    print_errno();
    return 1;
  }
  fprintf(fout, THPRAC98_AUTOGEN_WARNING_TEXT);
  fputs("#include \"src/tsrdata.hpp\"\n", fout);
  for (i = 1; i <= COM_FILE_COUNT; ++i) {
    fprintf(fout, "unsigned char th0%d_com_data[%d] = {\n", i,
            com_file_size[i]);
    sprintf(tmp_str, "th0%d.com", i);
    fin = fopen(tmp_str, "r");
    if (fin == NULL) {
      printf("Cannot open file th0%d.com.\n", i);
      print_errno();
      fclose(fout);
      return 1;
    }
    col = 3;
    fprintf(fout, INDENT);
    for (j = 0; j < com_file_size[i]; ++j) {
      ch = fgetc(fin);
      fprintf(fout, "0x%02X%c ", ch, j == com_file_size[i] - 1 ? ' ' : ',');
      col += 6;  // "0x??, "
      if (col > 80) {
        col = 3;
        fprintf(fout, ENDL INDENT);
      }
    }
    fprintf(fout, ENDL "};" ENDL ENDL);
    fclose(fin);
  }
  fclose(fout);
  return 0;
}

#define BACKPATCH_LABEL_LENGTH 13  // TH01_COM_INFO

const int BUFFER_SIZE = BACKPATCH_LABEL_LENGTH + 5;
char xdigit_buffer[BUFFER_SIZE], char_buffer[BUFFER_SIZE];
void buffer_push(char *const buffer, const char ch) {
  int i = 0;
  for (i = 0; i < BUFFER_SIZE - 1; ++i) {
    buffer[i] = buffer[i + 1];
  }
  buffer[BUFFER_SIZE - 1] = ch;
  return;
}
unsigned int from_xdigit(char ch) {
  if (isdigit(ch)) {
    return ch - '0';
  }
  if (isupper(ch)) {
    return ch - 'A' + 10;
  }
  return ch - 'a' + 10;
}
unsigned int get_hex(char *const str) {
  unsigned int ret = from_xdigit(str[0]);
  ret = (ret << 4) | from_xdigit(str[1]);
  ret = (ret << 4) | from_xdigit(str[2]);
  ret = (ret << 4) | from_xdigit(str[3]);
  return ret;
}

int backpatch_com_offset(void) {
  int i = 0, j = 0, k = 0, ret = 0, ch = 0;
  long j2 = 0;
  unsigned int com_info_seg = 0, com_info_off = 0;
  bool found_label = false;
  FILE *fin = NULL, *fin2 = NULL, *fin3 = NULL;
  unsigned long magic_check = 0, com_data_pos = -1;
  static const unsigned long HASH_MOD = 5675237l;  // prime
  unsigned long com_hash = 0, cur_hash = 0, discard_hash_multiplicator = 0;

  ret = init_com_file_size();
  if (ret) {
    return ret;
  }

  for (i = 1; i <= COM_FILE_COUNT; ++i) {
    found_label = false;
    memset(xdigit_buffer, 0x00, sizeof(xdigit_buffer));
    memset(char_buffer, 0x00, sizeof(char_buffer));

    // Calculate the hash of the .COM file
    // The hash function is: hash([a_n, ..., a1, a0]) = (a0*256^0 + a1*256^1 +
    // ... + an*256^n) % HASH_MOD.
    sprintf(tmp_str, "th0%d.com", i);
    fin = fopen(tmp_str, "r");
    if (fin == NULL) {
      printf("Cannot open file %s.\n", tmp_str);
      print_errno();
      return 1;
    }
    com_hash = 0;
    discard_hash_multiplicator = 1;
    for (j = 0; j < com_file_size[i]; ++j) {
      com_hash = ((com_hash << 8) + fgetc(fin)) % HASH_MOD;
      discard_hash_multiplicator = (discard_hash_multiplicator << 8) % HASH_MOD;
    }

    // Find the first occurence of the .COM file using the pre-calculated hash
    fin2 = fopen("thprac98.exe", "r");
    if (fin2 == NULL) {
      puts("Cannot open file thprac98.exe.");
      print_errno();
      fclose(fin);
      return 1;
    }
    fin3 = fopen("thprac98.exe", "r");
    if (fin3 == NULL) {
      puts("Cannot open file thprac98.exe.");
      print_errno();
      fclose(fin);
      fclose(fin2);
      return 1;
    }
    cur_hash = 0;
    com_data_pos = -1;
    for (j2 = 0; com_data_pos == (unsigned long)(-1); ++j2) {
      ch = fgetc(fin2);
      if (ch == EOF) {
        break;
      }
      cur_hash = ((cur_hash << 8) + ch) % HASH_MOD;
      if (j2 >= com_file_size[i]) {
        ch = fgetc(fin3);
        cur_hash += HASH_MOD - ch * discard_hash_multiplicator % HASH_MOD;
        if (cur_hash >= HASH_MOD) {
          cur_hash -= HASH_MOD;
        }
      }
      if (cur_hash == com_hash) {
        com_data_pos = j2;
        fseek(fin, 0, SEEK_SET);
        for (k = 0; k < com_file_size[i]; ++k) {
          ch = fgetc(fin);
          if (ch != fgetc(fin3)) {
            com_data_pos = -1;
            break;
          }
        }
        fseek(fin3, ftell(fin2) - com_file_size[i], SEEK_SET);
      }
    }
    fclose(fin);
    fclose(fin2);
    fclose(fin3);
    if (com_data_pos == (unsigned long)(-1)) {
      printf("Cannot find occurence of th0%d.com in thprac98.exe.\n", i);
      print_errno();
      return 1;
    }

    // Find where to backpatch the size & offset of th0x.com in the file
    fin = fopen("entrance.map", "r");
    if (fin == NULL) {
      printf("Cannot open file entrance.map.\n");
      print_errno();
      return 1;
    }
    sprintf(tmp_str, "TH0%d_COM_INFO", i);
    while ((ch = fgetc(fin)) != EOF) {
      if (isxdigit(ch)) {
        buffer_push(xdigit_buffer, ch);
      }
      buffer_push(char_buffer, ch);
      // " TH0?_COM_INFO "
      //  ^             ^
      //  |             ch (char_buffer[BUFFER_SIZE - 1])
      //  char_buffer[BUFFER_SIZE - 1 - BACKPATCH_LABEL_LENGTH - 1]
      if (isspace(ch) && !isspace(char_buffer[BUFFER_SIZE - 2]) &&
          isspace(char_buffer[BUFFER_SIZE - BACKPATCH_LABEL_LENGTH - 2])) {
        char_buffer[BUFFER_SIZE - 1] = '\0';
        if (strcmp(char_buffer + (BUFFER_SIZE - BACKPATCH_LABEL_LENGTH - 1),
                   tmp_str) == 0) {
          found_label = true;
          // A very cursed solution...
          // ????:????    TH0?_COM_INFO
          // ^    ^         -- -     ^
          // |    |                  xdigit_buffer[BUFFER_SIZE - 1]
          // |    xdigit_buffer[BUFFER_SIZE - 8]
          // xdigit_buffer[BUFFER_SIZE - 12]
          com_info_seg = get_hex(xdigit_buffer + (BUFFER_SIZE - 12));
          com_info_off = get_hex(xdigit_buffer + (BUFFER_SIZE - 8));
          break;
        }
        char_buffer[BUFFER_SIZE - 1] = ch;
      }
    }
    fclose(fin);
    if (!found_label) {
      printf("Cannot find label %s in entrance.map.\n", tmp_str);
      return 1;
    }
    if (com_info_seg != 0) {
      printf("Incorrect segment of label %s: Expecting 0000h, found %04Xh.\n",
             tmp_str, com_info_seg);
      return 1;
    }
    fin = fopen("thprac98.exe", "r+");
    if (fin == NULL) {
      puts("Cannot open file thprac98.exe.");
      print_errno();
      return 1;
    }
    com_info_off += 0x200;
    fseek(fin, com_info_off, SEEK_SET);
    magic_check = 0;
    for (j = 0; j < 4; ++j) {
      ch = fgetc(fin);
      if (ch == EOF) {
        puts("An error occured when modifying thprac98.exe.");
        print_errno();
        return 1;
      }
      magic_check |= (unsigned long)(ch) << (j << 3);
    }
    if (magic_check != 0x99618848l) {
      printf(
          "Magic number doesn't match at offset %08lX of thprac98.exe: "
          "Expected %08lX, but found %08lX.\n",
          (unsigned long)(com_info_off), 0x99618848l, magic_check);
      fclose(fin);
      return 1;
    }
    com_data_pos -= com_file_size[i] - 1;
    fseek(fin, com_info_off, SEEK_SET);
    fputc(com_data_pos & 0xFF, fin);
    fputc((com_data_pos >> 8) & 0xFF, fin);
    fputc((com_data_pos >> 16) & 0xFF, fin);
    fputc((com_data_pos >> 24) & 0xFF, fin);
    fputc(com_file_size[i] & 0xFF, fin);
    fputc((com_file_size[i] >> 8) & 0xFF, fin);
    fclose(fin);
    printf(
        "Patched dword %08lX and word %04X into offset %08lX in "
        "THPRAC98.EXE.\n",
        com_data_pos, com_file_size[i], com_info_off);
  }
  return 0;
}

#undef BACKPATCH_LABEL_LENGTH

char test_str[100];

int wrapped_main(int argc, char far **argv) {
  int mode = -1, i = 0;

  if (argc != 2) {
    printf("Incorrect argument count: Expecting 2, found %d.\n", argc);
    return -1;
  }
  if (argv[1][1] != '\0' || (argv[1][0] != '1' && argv[1][0] != '2')) {
    printf("Invalid mode: Expecting 1 or 2, found %s at %04X:%04X.\n", argv[1],
           FP_SEG(argv[1]), FP_OFF(argv[1]));
    printf("String content: ");
    for (i = 0; argv[1][i] != '\0'; ++i) {
      printf("%02Xh ", (unsigned)(argv[1][i]));
    }
    printf("\n");
    return -1;
  }
  mode = argv[1][0] - '0';

  if (mode == 1) {
    return generate_tsrdata();
  } else {
    return backpatch_com_offset();
  }
}