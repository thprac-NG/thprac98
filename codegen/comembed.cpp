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

const int COM_FILE_COUNT = 2;
int com_file_size[COM_FILE_COUNT + 1];

char tmp_str[60];

int init_com_file_size(void) {
  int i = 0;
  FILE *fin = NULL;
  long tmp = 0;
  int ret = 0;
  for (i = 1; i <= COM_FILE_COUNT; ++i) {
    snprintf(tmp_str, sizeof(tmp_str), "th0%d.com", i);
    fin = fopen(tmp_str, "r");
    if (fin == NULL) {
      printf("Cannot open file %s.\r\n", (const char far *)(tmp_str));
      print_errno();
      ret = 1;
      goto safe_return;
    }
    fseek(fin, 0, SEEK_END);
    tmp = ftell(fin);
    if (tmp > INT_MAX) {
      printf(
          "th0%d.com is too large: Expecting a size <= %d, but found %ld.\r\n",
          i, INT_MAX, tmp);
      ret = 1;
      goto safe_return;
    }
    com_file_size[i] = (int)(tmp);
    fclose(fin);
    fin = NULL;
  }
  ret = 0;
safe_return:
  if (fin != NULL) {
    fclose(fin);
    fin = NULL;
  }
  return ret;
}

// TODO: Add failure detection of fprintf.
int generate_tsrdata(char far *path) {
  int i = 0, ch = 0, col = 0, j = 0, ret = 0;
  FILE *fin = NULL, *fout = NULL;

  ret = init_com_file_size();
  if (ret) {
    goto safe_return;
  }

  // Generate TSRDATA.HPP
  if (snprintf(tmp_str, sizeof(tmp_str), "%s/tsrdata.hpp",
               (const char far *)(path), i) == sizeof(tmp_str)) {
    printf("Argument too long: length of `%s/tsrdata.hpp' should be <%d.\r\n",
           (const char far *)(path), i, sizeof(tmp_str));
    ret = 1;
    goto safe_return;
  }
  fout = fopen(tmp_str, "w");
  if (fout == NULL) {
    printf("Cannot open file %s.\r\n", (const char far *)(tmp_str));
    print_errno();
    ret = 1;
    goto safe_return;
  }
  fprintf(fout, THPRAC98_AUTOGEN_WARNING_TEXT);
  fprintf(fout, "#ifndef THPRAC98_SRC_TSRDATA_HPP_" ENDL);
  fprintf(fout, "#define THPRAC98_SRC_TSRDATA_HPP_" ENDL ENDL);
  for (i = 1; i <= COM_FILE_COUNT; ++i) {
    fprintf(fout, "extern unsigned char th0%d_com_data[%d];" ENDL, i,
            com_file_size[i]);
  }
  fprintf(fout, ENDL "#endif  // #ifndef THPRAC98_SRC_TSRDATA_HPP_" ENDL);
  fclose(fout);
  fout = NULL;

  // Generate TSRDATA.CPP
  if (snprintf(tmp_str, sizeof(tmp_str), "%s/tsrdata.cpp",
               (const char far *)(path), i) == sizeof(tmp_str)) {
    printf("Argument too long: length of `%s/tsrdata.cpp' should be <%d.\r\n",
           (const char far *)(path), i, sizeof(tmp_str));
    ret = 1;
    goto safe_return;
  }
  fout = fopen(tmp_str, "w");
  if (fout == NULL) {
    printf("Cannot open file %s.\r\n", (const char far *)(tmp_str));
    goto safe_return;
  }
  fprintf(fout, THPRAC98_AUTOGEN_WARNING_TEXT);
  fprintf(fout, "#include \"src/tsrdata.hpp\"" ENDL ENDL);
  for (i = 1; i <= COM_FILE_COUNT; ++i) {
    fprintf(fout, "unsigned char th0%d_com_data[%d] = {" ENDL, i,
            com_file_size[i]);
    snprintf(tmp_str, sizeof(tmp_str), "th0%d.com", i);
    fin = fopen(tmp_str, "r");
    if (fin == NULL) {
      printf("Cannot open file %s.\r\n", (const char far *)(tmp_str));
      print_errno();
      goto safe_return;
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
    fin = NULL;
  }
  fclose(fout);
  fout = NULL;
  ret = 0;
safe_return:
  if (fin != NULL) {
    fclose(fin);
    fin = NULL;
  }
  if (fout != NULL) {
    fclose(fout);
    fout = NULL;
  }
  return ret;
}

#define BACKPATCH_LABEL_LENGTH 13  // TH01_COM_INFO

const int BUFFER_SIZE = BACKPATCH_LABEL_LENGTH + 5;
// Two sliding windows, storing the latest `BUFFER_SIZE` hexadecimal digits/
// characters read from the file.
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
  unsigned int com_info_seg = 0, com_info_off = 0, header_size = 0;
  bool found_label = false;
  FILE *fin = NULL, *fin2 = NULL, *fin3 = NULL;
  unsigned long magic_check = 0, com_data_pos = -1;
  static const unsigned long HASH_MOD = 5675237l;  // prime
  unsigned long com_hash = 0, cur_hash = 0, discard_hash_multiplicator = 0;

  ret = init_com_file_size();
  if (ret) {
    goto safe_return;
  }

  for (i = 1; i <= COM_FILE_COUNT; ++i) {
    found_label = false;
    memset(xdigit_buffer, 0x00, sizeof(xdigit_buffer));
    memset(char_buffer, 0x00, sizeof(char_buffer));

    // Calculate the hash of the .COM file
    // The hash function is: hash([a_n, ..., a1, a0]) = (a0*256^0 + a1*256^1 +
    // ... + an*256^n) % HASH_MOD.
    snprintf(tmp_str, sizeof(tmp_str), "th0%d.com", i);
    fin = fopen(tmp_str, "r");
    if (fin == NULL) {
      printf("Cannot open file %s.\r\n", (const char far *)(tmp_str));
      print_errno();
      ret = 1;
      goto safe_return;
    }
    com_hash = 0;
    discard_hash_multiplicator = 1;
    for (j = 0; j < com_file_size[i]; ++j) {
      com_hash = ((com_hash << 8) + fgetc(fin)) % HASH_MOD;
      discard_hash_multiplicator = (discard_hash_multiplicator << 8) % HASH_MOD;
    }

    // Find the first occurence of the .COM file using the pre-calculated hash.
    // We use a sliding window of length (n+1), which is the same as the length
    // of the .COM file, and we detect if the hash of the window is the same as
    // the target. We accomplish this by first calculating the hash of the
    // window at the frontmost position, and update it each time it has been
    // advanced for a character. When this happens, we have to subtract the
    // contribution of the first character from the hash value, which is its
    // ASCII value multiplied by 256^n modulo `HASH_MOD`, and then add the
    // contribution of the incoming character, which is simply its ASCII value.
    // The variable `discard_hash_multiplicator` stores (256^n mod HASH_MOD).
    fin2 = fopen("thprac98.exe", "r");
    if (fin2 == NULL) {
      puts("Cannot open file thprac98.exe.");
      print_errno();
      ret = 1;
      goto safe_return;
    }
    // fin2: opened for the pointer for the incoming character in the sliding
    //       window of THPRAC98.EXE.
    fin3 = fopen("thprac98.exe", "r");
    if (fin3 == NULL) {
      puts("Cannot open file thprac98.exe.");
      print_errno();
      ret = 1;
      goto safe_return;
    }
    // fin3: opened for the pointer for the discarding character in the sliding
    //       window of THPRAC98.EXE.
    cur_hash = 0;
    com_data_pos = -1;
    for (j2 = 0; com_data_pos == (unsigned long)(-1); ++j2) {
      // accept the incoming character
      ch = fgetc(fin2);
      if (ch == EOF) {
        break;
      }
      cur_hash = ((cur_hash << 8) + ch) % HASH_MOD;
      // discard a character if the window reached the length
      if (j2 >= com_file_size[i]) {
        ch = fgetc(fin3);
        cur_hash += HASH_MOD - ch * discard_hash_multiplicator % HASH_MOD;
        if (cur_hash >= HASH_MOD) {
          cur_hash -= HASH_MOD;
        }
      }
      if (cur_hash == com_hash) {
        // The two hash values match. We perform a string compare here, just to
        // be safe.
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
        // If the string compare failed, fin3 will be back to it's position
        // before the compare, and com_data_pos will stays at -1.
      }
    }
    fclose(fin3);
    fclose(fin2);
    fclose(fin);
    fin = fin2 = fin3 = NULL;
    if (com_data_pos == (unsigned long)(-1)) {
      printf("Cannot find occurence of th0%d.com in thprac98.exe.\r\n", i);
      print_errno();
      ret = 1;
      goto safe_return;
    }

    // Find where to backpatch the size & offset of TH0X.COM in the file
    fin = fopen("entrance.map", "r");
    if (fin == NULL) {
      puts("Cannot open file entrance.map.");
      print_errno();
      ret = 1;
      goto safe_return;
    }
    snprintf(tmp_str, sizeof(tmp_str), "TH0%d_COM_INFO", i);
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
    fin = NULL;
    if (!found_label) {
      printf("Cannot find label %s in entrance.map.\r\n",
             (const char far *)(tmp_str));
      ret = 1;
      goto safe_return;
    }
    if (com_info_seg != 0) {
      printf("Incorrect segment of label %s: Expecting 0000h, found %04Xh.\r\n",
             (const char far *)(tmp_str), com_info_seg);
      ret = 1;
      goto safe_return;
    }
    fin = fopen("thprac98.exe", "r+");
    if (fin == NULL) {
      puts("Cannot open file thprac98.exe.");
      print_errno();
      ret = 1;
      goto safe_return;
    }
    fseek(fin, 0x08, SEEK_SET);
    header_size = fgetc(fin);
    header_size |= fgetc(fin) << 16;
    com_info_off += header_size << 4;
    fseek(fin, com_info_off, SEEK_SET);
    magic_check = 0;
    for (j = 0; j < 4; ++j) {
      ch = fgetc(fin);
      if (ch == EOF) {
        puts("An error occured when modifying thprac98.exe.");
        print_errno();
        ret = 1;
        goto safe_return;
      }
      magic_check |= (unsigned long)(ch) << (j << 3);
    }
    if (magic_check != 0x99618848l) {
      printf(
          "Magic number doesn't match at offset %08lX of thprac98.exe: \r\n"
          "Expecting %08lXh, but found %08lXh.\r\n",
          (unsigned long)(com_info_off), 0x99618848l, magic_check);
      ret = 1;
      goto safe_return;
    }
    com_data_pos -= com_file_size[i] - 1;
    fseek(fin, com_info_off, SEEK_SET);
    fputc((int)(com_data_pos) & 0xFF, fin);
    fputc((int)(com_data_pos >> 8) & 0xFF, fin);
    fputc((int)(com_data_pos >> 16) & 0xFF, fin);
    fputc((int)(com_data_pos >> 24) & 0xFF, fin);
    fputc(com_file_size[i] & 0xFF, fin);
    fputc((com_file_size[i] >> 8) & 0xFF, fin);
    fclose(fin);
    fin = NULL;
    printf(
        "Patched dword %08lXh and word %04Xh into offset %08lXh in "
        "THPRAC98.EXE.\r\n",
        com_data_pos, com_file_size[i], com_info_off);
  }
  ret = 0;
safe_return:
  if (fin != NULL) {
    fclose(fin);
    fin = NULL;
  }
  if (fin2 != NULL) {
    fclose(fin2);
    fin2 = NULL;
  }
  if (fin3 != NULL) {
    fclose(fin3);
    fin3 = NULL;
  }
  return ret;
}

#undef BACKPATCH_LABEL_LENGTH

char test_str[100];

int wrapped_main(int argc, char far **argv) {
  int mode = -1, i = 0;

  if (argc != 2 && argc != 3) {
    printf("Incorrect argument count: Expecting 2 or 3, found %d.\r\n", argc);
    return 1;
  }
  if (argv[1][1] != '\0' || (argv[1][0] != '1' && argv[1][0] != '2')) {
    printf("Invalid mode: Expecting 1 or 2, found %s at %04X:%04X.\r\n",
           (const char far *)(argv[1]), FP_SEG(argv[1]), FP_OFF(argv[1]));
    printf("String content: ");
    for (i = 0; argv[1][i] != '\0'; ++i) {
      printf("%02Xh ", (unsigned)(argv[1][i]));
    }
    printf("\r\n");
    return -1;
  }
  if (argv[1][0] == '1' && argc != 3) {
    printf("Incorrect argument count: Expecting 3 for mode 1, found %d.\r\n",
           argc);
    return 1;
  }
  if (argv[1][0] == '2' && argc != 2) {
    printf("Incorrect argument count: Expecting 2 for mode 2, found %d.\r\n",
           argc);
    return 1;
  }
  mode = argv[1][0] - '0';

  if (mode == 1) {
    return generate_tsrdata(argv[2]);
  } else {
    return backpatch_com_offset();
  }
}