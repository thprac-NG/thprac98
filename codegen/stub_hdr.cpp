// make STUB HeaDeR .cpp
#include <stdio.h>

#include "src/utils.hpp"

// Reference:
// https://www.tavi.co.uk/phobos/exeformat.html#reloctable ,
// https://alon-alush.github.io/pe%20file%20format/dosheader/ .
// Page: typically of a size of 512 bytes; Paragraph: a size of 16 bytes.
struct exe_header_t {
  uint16 magic_number;  // 0x5A4D, the famous "MZ" header
  uint16 last_page_size;  // in bytes; if set to 0, the real size is 512
  uint16 file_pages;
  uint16 relocation_items;
  uint16 header_paragraphs;  // must be even
  uint16 min_alloc;
  uint16 max_alloc;
  uint16 initial_ss;
  uint16 initial_sp;
  uint16 checksum;
  uint16 initial_ip;
  uint16 pre_relocated_initial_cs;
  uint16 relocation_table_offset;
  uint16 overlay_number;
  uint16 reserved1[4];  // the higher byte of reserved1[1] stands for the
                          // version of Turbo Linker (0x61 for 6.1x), source:
                          // https://cosmodoc.org/topics/exe-file-format/
  uint16 oem_identifier;
  uint16 oem_information;
  uint16 reserved2[10];  // we use this field to store the relocation table
  uint32 new_exe_header_offset;
};

uint8 header[0x10 * 100];
uint16 relocated_table[10][2];

int main(int argc, char** argv) {
  if (argc != 3) { return 1; }
  FILE *fin = fopen(argv[1], "rb");
  int ch = 0, i = 0;
  while (i < 0x20) {
    ch = fgetc(fin);
    if (ch == EOF) { break; }
    header[i] = ch;
    i++;
  }
  exe_header_t *exe_header = (exe_header_t*)(header);
  if (exe_header->header_paragraphs >= 100) {
    printf("stub_hdr: Too many (%d) header paragraphs, should be < 100.\n",
           exe_header->header_paragraphs);
    fclose(fin);
    return 5;
  }
  while (i < exe_header->header_paragraphs * 0x20) {
    ch = fgetc(fin);
    if (ch == EOF) { break; }
    header[i] = ch;
    i++;
  }
  if (ch == EOF) {
    printf("stub_hdr: %s has an incomplete header.\n", argv[1]);
    fclose(fin);
    return 2;
  }
  if (exe_header->relocation_items > 5) {
    printf("stub_hdr: Too many (%d) relocation items, should be <= 5.\n",
           exe_header->relocation_items);
    fclose(fin);
    return 3;
  }
  if (exe_header->relocation_items > 0 &&
      (exe_header->relocation_table_offset + exe_header->relocation_items * 4 >
       exe_header->header_paragraphs * 0x20)) {
    printf("stub_hdr: Relocation table is not completely inside the header.\n");
    return 4;
  }
  exe_header->header_paragraphs = 4;
  // These two for loops cannot be merged, since the memory region can overlap.
  for (i = 0; i < exe_header->relocation_items; ++i) {
    relocated_table[i][0] = *(uint16*)(
      (uint8*)header + exe_header->relocation_table_offset + i * 4
    );
    relocated_table[i][1] = *(uint16*)(
      (uint8*)header + exe_header->relocation_table_offset + i * 4 + 2
    );
  }
  for (i = 0; i < exe_header->relocation_items; ++i) {
    exe_header->reserved2[i * 2] = relocated_table[i][0];
    exe_header->reserved2[i * 2 + 1] = relocated_table[i][1];
  }
  exe_header->relocation_table_offset =
      (uint8*)exe_header->reserved2 - header;
  exe_header->new_exe_header_offset = 0;
  FILE *fout = fopen(argv[2], "wb");
  for (i = 0; i < exe_header->header_paragraphs * 0x10; ++i) {
    fputc(header[i], fout);
  }
  ch = fgetc(fin);
  while (ch != EOF) {
    fputc(ch, fout);
    ch = fgetc(fin);
  }
  fclose(fin);
  fclose(fout);
  return 0;
}