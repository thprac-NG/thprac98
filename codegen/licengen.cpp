// LICENse .(hpp/cpp) GENerator .cpp
#include "codegen/common.hpp"
#include "src/mystdlib/stdio.hpp"
#include "src/utils.hpp"

#define THPRAC98_LICENSE_WARNING_TEXT                                      \
  "// WARNING: THIS FILE IS AUTO-GENERATED" ENDL                           \
  "// To modify this file, edit files under codegen/licenses and use" ENDL \
  "// codegen/licengen.cpp to regenerate this file." ENDL ENDL

const int LICENSE_COUNT = 5;
const char* license_name[LICENSE_COUNT] = {
    "thprac98", "lohmann_json", "master_lib", "takeda_msdos", "mpaland_printf"};
const char* license_filename[LICENSE_COUNT] = {"thprac.txt", "lohmjson.txt",
                                               "masterlb.txt", "tkdmsdos.txt",
                                               "mpprintf.txt"};
FILE* handler[LICENSE_COUNT];
char buffer[100];

void close_all_handler() {
  int i = 0;
  for (i = 0; i < LICENSE_COUNT; ++i) {
    if (handler[i]) {
      fclose(handler[i]);
    }
  }
  return;
}

int wrapped_main(int argc, char far** argv) {
  int i = 0;
  if (argc != 2) {
    printf("Incorrect argument count: Expecting 2, found %d.\r\n", argc);
    return 1;
  }
  for (i = 0; i < LICENSE_COUNT; ++i) {
    if (snprintf(buffer, sizeof(buffer), "%s/codegen/licenses/%s", argv[1],
                 (const char far*)(license_filename[i])) == sizeof(buffer)) {
      printf(
          "Argument too long: length of `%s/codegen/licenses/%s' should be "
          "<%d.\r\n",
          argv[1], (const char far*)(license_filename[i]));
      return 1;
    }
    handler[i] = fopen(buffer, "rb");
    if (handler[i] == NULL) {
      printf("Cannot open file %s.\r\n", (const char far*)(buffer));
      close_all_handler();
      return 1;
    }
  }

  if (snprintf(buffer, sizeof(buffer), "%s/src/license.hpp", argv[1]) ==
      sizeof(buffer)) {
    printf(
        "Argument too long: length of `%s/src/license.hpp' should be <%d.\r\n",
        argv[1]);
    return 1;
  }
  FILE* fout = fopen(buffer, "w");
  if (fout == NULL) {
    printf("Cannot open file %s.\r\n", (const char far*)(buffer));
    close_all_handler();
    return 1;
  }
  fprintf(fout, THPRAC98_LICENSE_WARNING_TEXT
          "#ifndef THPRAC98_SRC_LICENSE_HPP_" ENDL
          "#define THPRAC98_SRC_LICENSE_HPP_" ENDL "" ENDL);
  for (i = 0; i < LICENSE_COUNT; ++i) {
    fprintf(fout, "extern const char* const license_%s;" ENDL,
            (const char far*)(license_name[i]));
  }
  fprintf(fout, ENDL "#endif  // #ifndef THPRAC98_SRC_LICENSE_HPP_");
  fclose(fout);

  int input = 0, col = 0;
  unsigned ch = 0;

  if (snprintf(buffer, sizeof(buffer), "%s/src/license.cpp", argv[1]) ==
      sizeof(buffer)) {
    printf(
        "Argument too long: length of `%s/src/license.cpp' should be <%d.\r\n",
        argv[1]);
    return 1;
  }
  fout = fopen(buffer, "w");
  if (fout == NULL) {
    printf("Cannot open file %s.\r\n", (const char far*)(buffer));
    close_all_handler();
    return 1;
  }
  fprintf(fout, THPRAC98_LICENSE_WARNING_TEXT
          "#include \"src/license.hpp\"" ENDL ENDL);
  for (i = 0; i < LICENSE_COUNT; ++i) {
    fprintf(fout, "const char* const license_%s =\r\n",
            (const char far*)(license_name[i]));
    fprintf(fout, INDENT INDENT "\"");
    input = fgetc(handler[i]);
    col = 5;
    while (input != EOF) {
      if (!ch) {
        ch = (ch << 8) | input;
      } else if (shiftjis_starting_byte(input)) {
        ch = input;
        input = fgetc(handler[i]);
        continue;
      }
      if (ch == '\n') {
        fprintf(fout, "\\r\\n");
        col += 2;
      } else if (ch == '\r') {
      } else if (ch == '\t') {
        fprintf(fout, "        ");
        col += 8;
      } else if (ch < 0x20) {
        ch = 0;
      } else if (ch == '\\') {
        fprintf(fout, "\\\\");
        col += 2;
      } else if (ch == '\"') {
        fprintf(fout, "\\\"");
        col += 2;
      } else if (ch == '?') {
        fprintf(fout, "\\?");
        col += 2;
      } else if (0x20 <= ch && ch <= 0x7E) {
        fprintf(fout, "%c", ch);
        col++;
      } else if (ch <= 0xFF) {
        fprintf(fout, "\\%03o", ch);
        col += 4;
      } else {
        fprintf(fout, "\\%03o\\%03o", ch >> 8, ch & 0xFF);
        col += 8;
      }
      // <=69 characters from previous pass + <=8 characters from current pass
      // + "\" \\" of size 3, equals <=80 characters per line
      if (col >= 70) {
        fprintf(fout, "\" \\" ENDL INDENT INDENT "\"");
        col = 5;
      }
      input = fgetc(handler[i]);
      ch = 0;
    }
    fprintf(fout, "\\r\\n\";" ENDL ENDL);
  }
  for (i = 0; i < LICENSE_COUNT; ++i) {
    fclose(handler[i]);
  }
  return 0;
}