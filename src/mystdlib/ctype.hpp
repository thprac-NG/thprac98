#ifndef THPRAC98_SRC_MYSTDLIB_CTYPE_HPP_
#define THPRAC98_SRC_MYSTDLIB_CTYPE_HPP_

#define isupper isupper_
inline int isupper_(int ch) { return (unsigned char)(ch - 'A') <= ('Z' - 'A'); }
#define islower islower_
inline int islower_(int ch) { return (unsigned char)(ch - 'a') <= ('z' - 'a'); }

#define isalpha isalpha_
inline int isalpha_(int ch) { return isupper(ch) || islower(ch); }

#define isdigit isdigit_
inline int isdigit_(int ch) { return (unsigned char)(ch - '0') <= ('9' - '0'); }
#define isxdigit isxdigit_
inline int isxdigit_(int ch) {
  return isdigit_(ch) || (unsigned char)(ch - 'A') <= ('F' - 'A') ||
         (unsigned char)(ch - 'a') <= ('f' - 'a');
}
#define isalnum isalnum_
inline int isalnum_(int ch) { return isalpha(ch) || isdigit(ch); }

#define isspace isspace_
inline int isspace_(int ch) { return ch == ' ' || (0x09 <= ch && ch <= 0x0D); }

#define toupper toupper_
inline int toupper_(int ch) { return islower(ch) ? ch & 0xDF : ch; }
#define tolower tolower_
inline int tolower_(int ch) { return isupper(ch) ? ch | 0x20 : ch; }

#endif  // #ifndef THPRAC98_SRC_MYSTDLIB_CTYPE_HPP_