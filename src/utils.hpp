#ifndef THPRAC98_SRC_UTILS_HPP_
#define THPRAC98_SRC_UTILS_HPP_

#pragma region Macros

// Macros to be compared with __cplusplus.
#define CPLUSPLUS97 199711L
#define CPLUSPLUS11 201103L
#define CPLUSPLUS14 201402L
#define CPLUSPLUS17 201703L
#define CPLUSPLUS20 202002L
#define CPLUSPLUS23 202302L

#if !defined(ANCIENT_CXX) && (__cplusplus < CPLUSPLUS11) && \
    !defined(__INTELLISENSE__)
#error C++97 is not supported. Please use >=C++11 if you're not using ancient \
       C++ compilers.
#endif

#pragma endregion  // #pragma region Macros
#pragma region CXX Keywords

#if (ANCIENT_CXX == 1)
#define CONSTEXPR
#else
#define CONSTEXPR constexpr
#endif

#pragma endregion  // #pragma region CXX Keywords

#if (ANCIENT_CXX == 0)
#include <cstdint>
#include <type_traits>
#endif
#include "src/master.hpp"
#include "src/mystdlib/errno.hpp"
#include "src/mystdlib/stdbool.hpp"
#include "src/mystdlib/stdio.hpp"
#include "src/tsrutils.hpp"

#pragma region Keyboard handling

/**
 * @brief The keys on a PC-98 keyboard.
 */
enum key_t {
  KEY_NULL = 0,  // not a real key, for configuration use

  // character typed:          none | +shift | +kana | +shift+kana

  KEY_1_NU,  //                1        !      ヌ
  KEY_2_FU,  //                2        "      フ
  KEY_3_A,   //                3        #      ア       ァ
  KEY_4_U,   //                4        $      ウ       ゥ
  KEY_5_E,   //                5        %      エ       ェ
  KEY_6_O,   //                6        &      オ       ォ
  KEY_7_YA,  //                7        '      ヤ       ャ
  KEY_8_YU,  //                8        (      ユ       ュ
  KEY_9_YO,  //                9        )      ヨ       ョ
  KEY_0_WA,  //                0               ワ       ヲ

  KEY_A_CHI,  //                A               チ
  KEY_B_KO,   //                B               コ
  KEY_C_SO,   //                C               ソ
  KEY_D_SHI,  //                D               シ
  KEY_E_I,    //                E               イ
  KEY_F_HA,   //                F               ハ
  KEY_G_KI,   //                G               キ
  KEY_H_KU,   //                H               ク
  KEY_I_NI,   //                I               ニ
  KEY_J_MA,   //                J               マ
  KEY_K_NO,   //                K               ノ
  KEY_L_RI,   //                L               リ
  KEY_M_MO,   //                M               モ
  KEY_N_MI,   //                N               ミ
  KEY_O_RA,   //                O               ラ
  KEY_P_SE,   //                P               セ
  KEY_Q_TA,   //                Q               タ
  KEY_R_SU,   //                R               ス
  KEY_S_TO,   //                S               ト
  KEY_T_KA,   //                T               カ
  KEY_U_NA,   //                U               ナ
  KEY_V_HI,   //                V               ヒ
  KEY_W_TE,   //                W               テ
  KEY_X_SA,   //                X               サ
  KEY_Y_N,    //                Y               ン
  KEY_Z_TSU,  //                Z               ツ       ッ

  KEY_MINUS_HO,            //   -        =      ホ
  KEY_CARET_HE,            //   ^               ヘ
  KEY_YEN_CHOONPU,         //   ￥       |      ー(長音符)
  KEY_AT_DAKUTEN,          //   @        ~      ゛(濁点)
  KEY_LEFT_BRACKET_KUTEN,  //   [        {      。(句点)   「(始め鉤括弧)
  KEY_SEMICOLON_RE,        //   ;        +      レ
  KEY_COLON_KE,            //   :        *      ケ
  KEY_RIGHT_BRACKET_MU,    //   ]        }      ム       」(終わり鉤括弧)
  KEY_COMMA_NE,            //   ,        <      ネ       、(読点)
  KEY_DOT_RU,              //   .        >      ル       ゜(半濁点)
  KEY_SLASH_NU,            //   /        ?      ヌ       ・(中黒)
  KEY_RO,                  //            _      ロ

  KEY_ESC,
  KEY_BS,  // BackSpace
  KEY_TAB,
  KEY_ENTER,
  KEY_SPACE,
  KEY_XFER,
  KEY_ROLL_UP,
  KEY_ROLL_DOWN,
  KEY_INS,
  KEY_DEL,
  KEY_UP,
  KEY_LEFT,
  KEY_RIGHT,
  KEY_DOWN,
  KEY_HOME_CLR,
  KEY_HELP,
  KEY_NFER,
  KEY_HOME,
  KEY_STOP,
  KEY_COPY,
  KEY_SHIFT,
  KEY_CAPS,
  KEY_KANA,  // 仮名
  KEY_GRPH,
  KEY_CTRL,

  KEY_NUMPAD_PLUS,
  KEY_NUMPAD_MINUS,
  KEY_NUMPAD_MULTIPLY,
  KEY_NUMPAD_DIVIDE,
  KEY_NUMPAD_EQUAL,
  KEY_NUMPAD_COMMA,
  KEY_NUMPAD_DOT,
  KEY_NUMPAD_0,
  KEY_NUMPAD_1,
  KEY_NUMPAD_2,
  KEY_NUMPAD_3,
  KEY_NUMPAD_4,
  KEY_NUMPAD_5,
  KEY_NUMPAD_6,
  KEY_NUMPAD_7,
  KEY_NUMPAD_8,
  KEY_NUMPAD_9,

  KEY_F1,
  KEY_F2,
  KEY_F3,
  KEY_F4,
  KEY_F5,
  KEY_F6,
  KEY_F7,
  KEY_F8,
  KEY_F9,
  KEY_F10,
  KEY_VF1,
  KEY_VF2,
  KEY_VF3,
  KEY_VF4,
  KEY_VF5
};

/**
 * @brief Key group used by INT 18h/04h.
 * @details When using it, one should provide a keygroup index, and get an
 * 8-bit return value representing whether each key of this keygroup is pressed,
 * from low to high.
 */
extern const key_t keygroups[16][8];

/**
 * @brief Indicates which keygroup a key belongs to and its index.
 */
extern const int keygroup_and_index_of[127][2];

bool is_pressed(key_t x);

#pragma endregion  // #pragma region Keyboard handling
#pragma region Character handling

/**
 * @brief Check whether a character is half-width or full-width when printed.
 * Reference: PC-9801 Programers' Bible, Section 4-10 ~ 4-11,
 * https://ja.wikipedia.org/wiki/JIS_X_0213%E9%9D%9E%E6%BC%A2%E5%AD%97%E4%B8%80%E8%A6%A7
 * .
 *
 * @param ch The character to be checked, should be valid.
 * @return int 1 if the character is half-width, 2 if otherwise.
 */
int char_width(unsigned ch);
template <unsigned ch>
struct char_width_c {
  enum { value = 2 - (ch <= 0x00FFu || (0x8540u <= ch && ch <= 0x869Du)) };
};

/**
 * @brief Print wide char by `putchar`-ing its first and second bit.
 *
 * @param ch The character to be printed.
 */
void wputchar(unsigned ch);

/**
 * @brief Convert a JIS code into the corresponding Shift-JIS code.
 * Returns ch if the encoding is invalid.
 */
unsigned jis_to_shiftjis(unsigned ch);
/**
 * @brief Convert a Shift-JIS code into the corresponding JIS code.
 * Returns ch if the encoding is invalid.
 */
unsigned shiftjis_to_jis(unsigned ch);
/**
 * @brief Determine whether the character is a valid Shift-JIS code.
 * Don't use this function: its table is incorrect (e.g. 0x8C49 isn't in it)
 */
// bool valid_shiftjis(unsigned ch);
/**
 * @brief Determine whether a byte is a Shift-JIS starting byte.
 */
bool shiftjis_starting_byte(unsigned ch);

#pragma endregion  // #pragma region Character handling
#pragma region Miscellaneous

#ifndef EOF
#define EOF (-1)
#endif

// Rotates first and second byte.
unsigned rot(unsigned n);

// popcount(x) for x from 0 to 15.
extern const unsigned popcount_data[16];
// The number of 1s in the binary representation of n.
unsigned popcount(unsigned n);

/**
 * @brief Switch the printing mode to "graph mode", allowing to print characters
 * in 0x0081~0x009F and 0x00E0~0x00EF.
 */
void graph_mode(void);
/**
 * @brief Switch the printing mode to "kanji mode", allowing to print characters
 * in 0x0081~0x009F and 0x00E0~0x00EF.
 */
void kanji_mode(void);

template <class T, class U>
struct pair {
  typedef T first_type;
  typedef U second_type;
  T first;
  U second;
  pair() {}
  pair(T first_, U second_) : first(first_), second(second_) {}
};
template <class T, class U>
pair<T, U> make_pair(T first, U second);

extern bool is_epson;

const int SCREEN_WIDTH = 80;
const int SCREEN_HEIGHT = 25;

void wait_for_enter_key();
void print_delimiter(char ch = '=');
/**
 * @brief Print a Shift-JIS-encoded string to the screen.
 * @details Invalid Shift-JIS codes will be converted by "?" (0x3F) (currently
 *          unusable)
 *
 * @param str the string
 * @param pause If passed with `true`, wait for a key input after printing
 *              several rows (default to 23, configurable in parameter `rows`).
 * @param kanji If passed with `true`, combine bytes of adjacent characters into
 *              a Shift-JIS 2-byte character if possible.
 *              If passed with `false`, treat every character as a Shift-JIS
 *              1-byte character.
 * @param rows The number of printed rows before a pause. Must be >0.
 *
 * @returns 0 if succeed, 1 if `rows` <= 0.
 */
int print_string(const char *str, bool pause = true, bool kanji = true,
                 int rows = 23);

inline void print_errno(void) {
  printf("Errno: 0x%04X\r\n", errno_);
  return;
}

#define THPRAC98_TO_STRING_HELPER(arg) #arg
#define THPRAC98_TO_STRING(arg) THPRAC98_TO_STRING_HELPER(arg)

#pragma endregion  // #pragma region Miscellaneous

#endif  // #ifndef THPRAC98_SRC_UTILS_HPP_