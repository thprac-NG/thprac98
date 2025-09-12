// LICENse .(hpp/cpp) GENerator .cpp
#include <stdio.h>

#include "codegen/common.hpp"
#include "src/utils.hpp"

#define THPRAC98_LICENSE_WARNING_TEXT \
    "// WARNING: THIS FILE IS AUTO-GENERATED" ENDL                  \
    "// To modify this file, edit files under codegen/licenses and use" ENDL  \
    "// codegen/licengen.cpp to regenerate this file." ENDL ENDL

const int LICENSE_COUNT = 4;
const char* license_name[LICENSE_COUNT] = {
  "thprac98", "lohmann_json", "master_lib", "takeda_msdos"
};
const char* license_filename[LICENSE_COUNT] = {
  "thprac.txt", "lohmjson.txt", "masterlb.txt", "tkdmsdos.txt"
};
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

int main() {
  int i = 0;
  for (i = 0; i < LICENSE_COUNT; ++i) {
    sprintf(buffer, "codegen/licenses/%s", license_filename[i]);
    handler[i] = fopen(buffer, "rb");
    if (handler[i] == NULL) {
      printf("Cannot open file codegen/licenses/%s.\n", license_filename[i]);
      close_all_handler();
      return 1;
    }
  }

  FILE* fout = fopen("src/license.hpp", "w");
  if (fout == NULL) {
    printf("Cannot open file src/license.hpp.\n");
    close_all_handler();
    return 1;
  }
  fprintf(fout,
    THPRAC98_LICENSE_WARNING_TEXT
    "#ifndef THPRAC98_SRC_LICENSE_HPP_" ENDL
    "#define THPRAC98_SRC_LICENSE_HPP_" ENDL
    "" ENDL
  );
  for (i = 0; i < LICENSE_COUNT; ++i) {
    fprintf(fout, "extern const char* const license_%s;" ENDL, license_name[i]);
  }
  fprintf(fout, ENDL "#endif  // #ifndef THPRAC98_SRC_LICENSE_HPP_");
  fclose(fout);

  int input = 0, col = 0;
  unsigned ch = 0;
  fout = fopen("src/license.cpp", "w");
  if (fout == NULL) {
    printf("Cannot open file src/license.cpp.\n");
    close_all_handler();
    return 1;
  }
  fprintf(fout, "#include \"src/license.hpp\"" ENDL ENDL);
  for (i = 0; i < LICENSE_COUNT; ++i) {
    fprintf(fout, "const char* const license_%s =\n", license_name[i]);
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
        fprintf(fout, "\\n");
        col += 2;
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
    fprintf(fout, "\\n\";" ENDL ENDL);
  }
  for (i = 0; i < LICENSE_COUNT; ++i) {
    fclose(handler[i]);
  }
  return 0;
}