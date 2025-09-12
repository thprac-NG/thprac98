// make STUB HeaDeR .cpp
#include <stdio.h>

#include "src/utils.hpp"

// Reference:
// https://www.tavi.co.uk/phobos/exeformat.html ,
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

struct checksum_t {
  uint16 checksum, current_word;
  bool at_odd_byte;
  checksum_t() {
    checksum = current_word = 0;
    at_odd_byte = false;
  }
  void pushback(uint8 byte) {
    if (at_odd_byte) {
      current_word = (current_word << 8) | byte;
    } else {
      checksum += current_word;
      current_word = 0;
    }
    at_odd_byte ^= 1;
    return;
  }
};

int main(int argc, char** argv) {
  // TODO: add a correct checksum
  // TODO: use only one input argument and modify it using another temp file
  if (argc != 3) {
    printf("stub_hdr: Incorrect argument. "
           "Expecting stub_hdr [input_exe] [output_exe].\n");
    return 1;
  }
  FILE *fin = fopen(argv[1], "rb");
  if (fin == NULL) {
    printf("stub_hdr: Cannot open input file %s.\n", argv[1]);
    return 6;
  }

  // Read the file header
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
  while (i < exe_header->header_paragraphs * 0x10) {
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

  // Generate the new header
  int old_header_paragraphs = exe_header->header_paragraphs;
  exe_header->header_paragraphs = 4;
  // The two following loops can't be merged, since the memory region can
  // overlap to each other.
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
  exe_header->checksum = 0;
  checksum_t checksum;
  for (i = 0; i < exe_header->header_paragraphs * 0x10; ++i) {
    checksum.pushback(header[i]);
  }
  ch = fgetc(fin);
  while (ch != EOF) {
    checksum.pushback(ch);
    ch = fgetc(fin);
  }
  if (checksum.at_odd_byte) {
    checksum.pushback(0);
  }
  exe_header->checksum = ~checksum.checksum;
  fclose(fin);

  fin = fopen(argv[1], "rb");
  if (fin == NULL) {
    printf("stub_hdr: Cannot open input file %s.\n", argv[1]);
    return 6;
  }
  FILE *fout = fopen(argv[2], "wb");
  if (fout == NULL) {
    printf("stub_hdr: Cannot open output file %s.\n", argv[1]);
    return 7;
  }
  for (i = 0; i < old_header_paragraphs * 0x10; ++i) {
    fgetc(fin);
  }
  for (i = 0; i < exe_header->header_paragraphs * 0x10; ++i) {
    fputc(header[i], fout);
  }
  ch = fgetc(fin);
  while (ch != EOF) {
    fputc(ch, fout);
    printf("%X ", ch);
    ch = fgetc(fin);
  }
  fclose(fin);
  fclose(fout);
  return 0;
}