#ifndef THPRAC98_SRC_ASMUTILS_ASMUTILS_HPP_
#define THPRAC98_SRC_ASMUTILS_ASMUTILS_HPP_

// defined in sprnthex.asm
extern "C" unsigned near to_hex_digit(unsigned);
extern "C" void near sprint_byte(char near*, unsigned);
extern "C" void near sprint_word(char near*, unsigned);
extern "C" void near sprint_dword(char near*, unsigned long);

// defined in strcmpnc.asm
extern "C" int near strcmp_ignore_case(const char far*, const char far*);

// defined in tramprnt.asm
extern "C" int near print_ch(int code, int x, int y, int attr);
extern "C" int near print_str(char const far* str, int x, int y, int attr);

// defined in memcpy.asm
extern "C" void near memory_copy(void far* dest, void far* src, unsigned size);

// defined in prntfrme.asm
extern "C" void near print_frame(unsigned x0, unsigned y0, unsigned width,
                                 unsigned height, unsigned attr);

#endif  // #ifndef THPRAC98_SRC_ASMUTILS_ASMUTILS_HPP_