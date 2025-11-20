#ifndef THPRAC98_SRC_TEXTS_HPP_
#define THPRAC98_SRC_TEXTS_HPP_

#include "src/textsdef.hpp"

enum language_t { LANGUAGE_CHINESE = 0, LANGUAGE_ENGLISH, LANGUAGE_JAPANESE };
extern language_t language;

#define S(identifier) \
  (th_glossary_str[static_cast<size_t>(language)][identifier])

#endif  // #ifndef THPRAC98_SRC_TEXTS_HPP_