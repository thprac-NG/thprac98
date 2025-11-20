#ifndef THPRAC98_SRC_CHARANGE_HPP_
#define THPRAC98_SRC_CHARANGE_HPP_ 1

/**
 * @brief The "width" of a character. For example, latin characters are
 * half-width, and kanjis are full-width.
 *
 * @param ch The character, in Shift-JIS format.
 * @return int The width of the character, 1 for half-width, 2 for full-width.
 */
int width(unsigned int ch);
struct char_chunk_mask_t {
  const int UNUSED = 0x0100;

  /** @brief When the flag set, the chunk range is
   *       [starting_sjis, ending_sjis] - {0x7F + 0x100 * a | 0 <= a < 0x100}
   *  instead of [starting_sjis, ending_sjis].
   */
  const int SKIP_XX7F = 0x0010;

  const int PC98_ONLY = 0x0001;
  const int EPSON_98_ONLY = 0x0003;
};
/**
 * @brief Character type. Categorization based on Section 4.9 ~ 4.10 of PC-9801
 * Programmer's Bible. All encodings labelled here are in Shift-JIS.
 * For more details, see definition of array char_chunks.
 */
struct char_chunk_t {
  /**
   * @brief Char type. Each type represents an interval  [starting_sjis,
   * ending_sjis] subset to [0x0000, 0xffff], with optionally all 0x??7F
   * values removed.
   */
  enum chunk_type_t {
    ASCII_CONTROL,
    ASCII_PRINTABLE,
    BYTE_007F,
    SHIFTJIS_LEADING_BYTE,
    HALFWIDTH_KATAKANA,
    HALFWIDTH_KANJI,
    SYMBOL,
    EPSON_98_SPECIFIC_SYMBOL,
    ENGLISH_AND_NUMBER,
    HIRAGANA,
    KATAKANA,
    GREEK,
    RUSSIAN,
    EPSON_BOX_DRAWING,
    HALFWIDTH_JIS_ASCII,
    JIS_HALFWIDTH_KATAKANA,
    HALFWIDTH_BOXDRAWING,
    HALFWIDTH_SYMBOL,
    FULLWIDTH_BOXDRAWING,
    PC98_SPECIFIC_SYMBOL,
    KANJI,
    EXTENDED_KANJI
  };
  chunk_type_t chunk_type;
  unsigned starting_sjis;
  unsigned ending_sjis;

  char_chunk_mask_t properties;
};

#define THPRAC_CHAR_CHUNKS_SIZE 100

extern const char_chunk_t char_chunks[THPRAC_CHAR_CHUNKS_SIZE];

/**
 * @brief Identify the type of a Shift-JIS character on PC-98.
 *
 * @param ch The character, in Shift-JIS format.
 * @return chtype_t The type of character.
 */
char_chunk_t chtype(unsigned int ch);

#endif  // #ifndef THPRAC98_SRC_CHARANGE_HPP_