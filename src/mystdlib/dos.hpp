#ifndef THPRAC98_SRC_MYSTDLIB_DOS_HPP_
#define THPRAC98_SRC_MYSTDLIB_DOS_HPP_

// Copied from dos.h of Turbo C++4.0J, modified.
// ----------------------------------------------
#define MK_FP MK_FP_
#define FP_SEG FP_SEG_
#define FP_OFF FP_OFF_
#define MK_FP_(seg, ofs) ((void __seg*)(seg) + (void __near*)(ofs))
#define FP_SEG_(fp) ((unsigned)(void __seg*)(void __far*)(fp))
#define FP_OFF_(fp) ((unsigned)(fp))

#define WORDREGS WORDREGS_
struct WORDREGS_ {
  unsigned short ax;
  unsigned short bx;
  unsigned short cx;
  unsigned short dx;
  unsigned short si;
  unsigned short di;
  unsigned short cflag;
  unsigned short flags;
};

#define BYTEREGS BYTEREGS_
struct BYTEREGS_ {
  unsigned char al;
  unsigned char ah;
  unsigned char bl;
  unsigned char bh;
  unsigned char cl;
  unsigned char ch;
  unsigned char dl;
  unsigned char dh;
};

#define REGS REGS_
union REGS_ {
  struct WORDREGS x;
  struct WORDREGS w;
  struct BYTEREGS h;
};

#define SREGS SREGS_
struct SREGS {
  unsigned short es;
  unsigned short cs;
  unsigned short ss;
  unsigned short ds;
};

#define REGPACK REGPACK_
struct REGPACK_ {
  unsigned r_ax, r_bx, r_cx, r_dx;
  unsigned r_bp, r_si, r_di, r_ds, r_es, r_flags;
};

// ----------------------------------------------

#define int86 int86_
#define int86x int86x_
extern "C" int int86_(int int_no, REGS far* in_regs, REGS far* out_regs);
extern "C" int int86x_(int int_no, REGS far* in_regs, REGS far* out_regs,
                       SREGS far* seg_regs);

#define intdos intdos_
#define intdosx intdosx_
inline int intdos_(REGS far* in_regs, REGS far* out_regs) {
  return int86(0x21, in_regs, out_regs);
}
inline int intdosx_(REGS far* in_regs, REGS far* out_regs,
                    SREGS far* seg_regs) {
  return int86x(0x21, in_regs, out_regs, seg_regs);
}

#endif  // #ifndef THPRAC98_SRC_MYSTDLIB_DOS_HPP_