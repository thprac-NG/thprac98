
  // ---------------------------- 0x0000 ~ 0x007F --------------------------

  // From 0x0000 (NIL) to 0x001F (*marked as a downward arrow in "bible"*).
  // For some reason DOSBox-X treats 0x1F as printable, prints a downward arrow.
  {char_chunk_t::ASCII_CONTROL, 0x0000, 0x001F, 0},
  // From 0x0020 (halfwidth space) to 0x007E (upper ~).
  // Note that there're two differences from modern ASCII: 0x005C is
  // (half-width Åè) instead of (\\), 0x007E is (upper ~) instead of (~).
  // See JIS X 0201 standard.
  {char_chunk_t::ASCII_PRINTABLE, 0x0020, 0x007E, 0},

  // ---------------------------- 0x0080 ~ 0x00FF --------------------------
  // 0x0080 ~ 0x009F and 0x00E0 ~ 0x00EF are the leading bytes in Shift-JIS,
  // containing some partially filled blocks, triangles, and circles. Some
  // box-drawing characters and the four playing card suits are in here, too.
  //
  // To print these characters correctly, you can't simply use C library
  // functions like `putchar`.
  // e.g. `putchar(0x8b); putchar(0x8c);` will print ãå (0x8b8c) instead.
  // To correctly print these character, one need to shift from the "kanji mode"
  // (default) to "graph mode", by printing "\x1B)3". Shifting back to kanji
  // mode can be realized by printing "\x1B)0".
  // See https://github.com/nmlgc/dosbox-x/blob/2d40b705937b7536717f8322147b921c0ed6bd25/pc98-testme-1/contents/CHARMODE.C#L28
  // for more details.

  // From 0x0080 (lower 1/8 filled) to 0x008E (left 7/8 filled).
  {char_chunk_t::BYTE_PARTIALLY_FILLED_SQUARES, 0x0080, 0x008E, 0},
  // From 0x008F (box-drawing +) to 0x009F (1/4 arc connecting top and left).
  {char_chunk_t::BYTE_BOX_DRAWING, 0x008F, 0x009F, 0},
  // From 0x00A0 (space) to 0x00A5(íÜçï, nakakuro).
  {char_chunk_t::BYTE_JAPANESE_PUNCTUATION, 0x00A0, 0x00A5, 0},
  // From 0x00A6 (Éí, wo) to 0x00DF (îºë˜ì_, handakuten).
  {char_chunk_t::BYTE_KATAKANA, 0x00A6, 0x00DF, 0},
  // From 0x00E0 (===) to 0x00E4 (=| ).
  {char_chunk_t::BYTE_BOX_DRAWING_2, 0x00E0, 0x00E3, 0},
  // From 0x00E4 (bottom right 1/2) to 0x00E7 (top left 1/2).
  // Triangles that have 1/2 area of a square.
  {char_chunk_t::BYTE_HALF_TRIANGLES, 0x00E4, 0x00E7, 0},
  // From 0x00E8 (spades) to 0x00EB (clover).
  {char_chunk_t::BYTE_PLAYING_CARDS_SUITS, 0x00E8, 0x00EB, 0},
  // From 0x00EC (filled circle) to 0x00ED (unfilled circle).
  {char_chunk_t::BYTE_FILLED_CIRCLE, 0x00EC, 0x00ED, 0},
  // From 0x00EE (box-drawing /) to 0x00EB (box-drawing X).
  {char_chunk_t::BYTE_BOX_DRAWING_2, 0x00EE, 0x00F0, 0},
  // From 0x00EE (â~, yen) to 0x00EB (ïb, byou).
  {char_chunk_t::BYTE_KANJI, 0x00F1, 0x00F7, 0},
  // From 0x00FC (backslash) to 0x00FC (backslash)
  {char_chunk_t::BYTE_BACKSLASH, 0x00FC, 0x00FC, 0},

  // ---------------------------- 0x0100 ~ 0xFFFF --------------------------

  // 0x8140(òaéöä‘äu, wajikankaku) ~ 0x81AC(â∫ë ãLçÜ, kedakigou). 0x817F skipped.
  // See https://ja.wikipedia.org/wiki/JIS_X_0213%E9%9D%9E%E6%BC%A2%E5%AD%97%E4%B8%80%E8%A6%A7
  // , Section 1ñ 1ãÊ and Section 1ñ 2ãÊ (column ñ ãÊì_ ranging from 1-2-1 to
  // 1-2-14).
  {char_chunk_t::SYMBOL, 0x8140, 0x81AC, char_chunk_mask.SKIP_XX7F},

  // 0x81B8(\in in LaTeX) ~ 0x81BF(\cap in LaTeX).
  // Only exists in EPSON's PC98 compatables.
  {char_chunk_t::EPSON_98_SET_SYMBOL, 0x81B8, 0x81BF,
   char_chunk_mask.EPSON_98_ONLY},
  // 0x81C8(\wedge in LaTeX) ~ 0x81CE(\exists in LaTeX). EPSON only.
  {char_chunk_t::EPSON_98_LOGIC_SYMBOL, 0x81C8, 0x81CE,
   char_chunk_mask.EPSON_98_ONLY},
  // 0x81DA(\angle in LaTeX) ~ 0x81E8(\iint in LaTeX). EPSON only.
  {char_chunk_t::EPSON_98_OTHER_MATH_SYMBOL, 0x81DA, 0x81E8,
   char_chunk_mask.EPSON_98_ONLY},
  // 0x81F0(Angstrom) ~ 0x81F7(\textparagraph in LaTeX). EPSON only.
  {char_chunk_t::EPSON_98_OTHER_SYMBOL, 0x81F0, 0x81F7,
   char_chunk_mask.EPSON_98_ONLY},
  // 0x81FC(big circle) ~ 0x81FC(big circle). EPSON only.
  {char_chunk_t::EPSON_98_OTHER_SYMBOL, 0x81FC, 0x81FC,
   char_chunk_mask.EPSON_98_ONLY},

  // 0x824F(fullwidth 0) ~ 0x8258(fullwidth 9).
  {char_chunk_t::FULLWIDTH_NUMERICS, 0x824F, 0x8258, 0},
  // 0x8260(fullwidth A) ~ 0x8279(fullwidth Z).
  {char_chunk_t::FULLWIDTH_UPPERCASE_ENGLISH_ALPHABET, 0x8260, 0x8279, 0},
  // 0x8280(fullwidth a) ~ 0x8299(fullwidth z).
  {char_chunk_t::FULLWIDTH_LOWERCASE_ENGLISH_ALPHABET, 0x8280, 0x8299, 0},

  // 0x829F(Çü, the smaller one) ~ 0x82F1(ÇÒ)
  {char_chunk_t::HIRAGANA, 0x829F, 0x82F1, true, true},
  // 0x8340(É@, the smaller one) ~ 0x8396(Éñ, the smaller one)
  {char_chunk_t::KATAKANA, 0x8340, 0x8396, true, true},
  // 0x839F(Alpha Éü) ~ 0x83D6(Omega É∂)
  {char_chunk_t::UPPERCASE_GREEK, 0x0000, 0x0000, true, true},
  // 0x83A0(alpha Éø) ~ 0x83D6(omega É÷)
  {char_chunk_t::LOWERCASE_GREEK, 0x0000, 0x0000, true, true},
  // 0x8440(Cyrillic Ñ@) ~ 0x8491(Uppercase Ñ`)
  {char_chunk_t::UPPERCASE_RUSSIAN, 0x0000, 0x0000, true, true},
  // 0x8440(Cyrillic Ñp) ~ 0x8491(lowercase Ñë)
  {char_chunk_t::LOWERCASE_RUSSIAN, 0x0000, 0x0000, true, true},
  // 0x849F(box-drawing Ñü) ~ 0x84BE(Ñæ).
  // Only exists in EPSON's PC98 compatables.
  {char_chunk_t::EPSON_BOX_DRAWING, 0x0000, 0x0000, true, true},
  // 0x8540(!) ~ 0x859E(overline). JIS X 0201 implementation.
  // Note that it's different from the bible, where it ends with 0x859F
  // (half-width ÅB). This character is ãÂì_(kuten), a Japanese punctuation mark,
  // so it should belong to the next field.
  {char_chunk_t::HALFWIDTH_JIS_ASCII, 0x0000, 0x0000, true, true},
  // 0x859F(half-width ãÂì_(kuten) ÅB) ~ 0x85FC(halfwidth É|, po).
  {char_chunk_t::JIS_HALFWIDTH_KATAKANA, 0x0000, 0x0000, true, true},
  // 0x8641(corner quote ") ~ 0x868F(half-width Ñ¥)
  // Note that 0x8641 and 0x8642 are corner quotes.
  {char_chunk_t::HALFWIDTH_BOXDRAWING, 0x0000, 0x0000, true, true},
  // 0x869E(Åf) ~ 0x2B7F()
  {char_chunk_t::HALFWIDTH_SYMBOL, 0x0000, 0x0000, true, true},
  // 0x86A2(full-width box-drawing Ñü) ~ 0x86ED(full-width Ñ¥)
  {char_chunk_t::FULLWIDTH_BOXDRAWING, 0x0000, 0x0000, true, true},
  //  ~ 0x2D7F in JIS.
  // Only exists in PC98s (including EPSON compatables).
  {char_chunk_t::PC98_SPECIFIC_SYMBOL, 0x0000, 0x0000, true, true},
  // 0x879F(àü, pronouced as Ç†) ~ 0x9872(òr, pronouced as ÇÌÇÒ) in Shift-JIS.
  {char_chunk_t::KANJI_1, 0x0000, 0x0000, true, true},
  // 0x879F(àü, pronouced as Ç†) ~ 0x9872(òr, pronouced as ÇÌÇÒ) in Shift-JIS.
  {char_chunk_t::KANJI_2, 0x0000, 0x0000, true, true},
  {char_chunk_t::EXTENDED_KANJI 0x0000, 0x0000, true, true},