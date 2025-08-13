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
#include "master.h"

#pragma region "Fundamental" Types

#if (ANCIENT_CXX == 1)
#define bool unsigned char
#define false ((bool)(0))
#define true ((bool)(1))
#endif

#if (ANCIENT_CXX == 1) || (__cplusplus < CPLUSPLUS20)
#if (ANCIENT_CXX == 0)
static_assert(
  sizeof(signed char) == 1 && std::is_signed<signed char>::value == true,
  "Type 'signed char' should have a size of 1, and be signed."
);
static_assert(
  sizeof(unsigned char) == 1 && std::is_signed<unsigned char>::value == false,
  "Type 'unsigned char' should have a size of 1, and be unsigned."
);
#endif
typedef signed char int8;
typedef unsigned char uint8;
#else
typedef int8_t int8;
typedef uint8_t int uint8;
#endif

#if (ANCIENT_CXX == 1)
typedef signed short int16;
typedef unsigned short uint16;
typedef signed long int32;
typedef unsigned long uint32;
#else
typedef int16_t int16;
typedef uint16_t uint16;
typedef int32_t int32;
typedef uint32_t uint32;
#endif

#ifdef DEBUG
/**
 * @brief Designed for ancient C++.
 * Test if type int8, uint16, uint32, ... works as intended.
 * @details Both sizes and signedness will be tested.
 *
 * @return true If they work as intended.
 */
bool test_stdint(void);
#endif

#pragma endregion  // #pragma region "Fundamental" Types
#pragma region Keyboard handling

/**
 * @brief The keys on a PC-98 keyboard.
 */
enum key_t {
  KEY_NULL = 0,  // not a real key, for configuration use

  // character typed:          none | +shift | +kana | +shift+kana

  KEY_1_NU,   //                1        !      �k
  KEY_2_FU,   //                2        "      �t
  KEY_3_A,    //                3        #      �A       �@
  KEY_4_U,    //                4        $      �E       �D
  KEY_5_E,    //                5        %      �G       �F
  KEY_6_O,    //                6        &      �I       �H
  KEY_7_YA,   //                7        '      ��       ��
  KEY_8_YU,   //                8        (      ��       ��
  KEY_9_YO,   //                9        )      ��       ��
  KEY_0_WA,   //                0               ��       ��

  KEY_A_CHI,  //                A               �`
  KEY_B_KO,   //                B               �R
  KEY_C_SO,   //                C               �\
  KEY_D_SHI,  //                D               �V
  KEY_E_I,    //                E               �C
  KEY_F_HA,   //                F               �n
  KEY_G_KI,   //                G               �L
  KEY_H_KU,   //                H               �N
  KEY_I_NI,   //                I               �j
  KEY_J_MA,   //                J               �}
  KEY_K_NO,   //                K               �m
  KEY_L_RI,   //                L               ��
  KEY_M_MO,   //                M               ��
  KEY_N_MI,   //                N               �~
  KEY_O_RA,   //                O               ��
  KEY_P_SE,   //                P               �Z
  KEY_Q_TA,   //                Q               �^
  KEY_R_SU,   //                R               �X
  KEY_S_TO,   //                S               �g
  KEY_T_KA,   //                T               �J
  KEY_U_NA,   //                U               �i
  KEY_V_HI,   //                V               �q
  KEY_W_TE,   //                W               �e
  KEY_X_SA,   //                X               �T
  KEY_Y_N,    //                Y               ��
  KEY_Z_TSU,  //                Z               �c       �b

  KEY_MINUS_HO,            //   -        =      �z
  KEY_CARET_HE,            //   ^               �w
  KEY_YEN_CHOONPU,         //   ��       |      �[(������)
  KEY_AT_DAKUTEN,          //   @        ~      �J(���_)
  KEY_LEFT_BRACKET_KUTEN,  //   [        {      �B(��_)   �u(�n���ꊇ��)
  KEY_SEMICOLON_RE,        //   ;        +      ��
  KEY_COLON_KE,            //   :        *      �P
  KEY_RIGHT_BRACKET_MU,    //   ]        }      ��       �v(�I����ꊇ��)
  KEY_COMMA_NE,            //   ,        <      �l       �A(�Ǔ_)
  KEY_DOT_RU,              //   .        >      ��       �K(�����_)
  KEY_SLASH_NU,            //   /        ?      �k       �E(����)
  KEY_RO,                  //            _      ��

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
  KEY_KANA,  // ����
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
  KEY_VF5,
};

/**
 * @brief Key group used by INT 18h/04h. When using it, one should provide a
 * keygroup index, and get an 8-bit return value representing whether each key
 * of this keygroup is pressed, from low to high.
 */
const key_t keygroups[16][8] = {
  {
    KEY_ESC, KEY_1_NU, KEY_2_FU, KEY_3_A,
    KEY_4_U, KEY_5_E, KEY_6_O, KEY_7_YA
  },
  {
    KEY_8_YU, KEY_9_YO, KEY_0_WA, KEY_MINUS_HO,
    KEY_CARET_HE, KEY_YEN_CHOONPU, KEY_BS, KEY_TAB
  },
  {
    KEY_Q_TA, KEY_W_TE, KEY_E_I, KEY_R_SU,
    KEY_T_KA, KEY_Y_N, KEY_U_NA, KEY_I_NI
  },
  {
    KEY_O_RA, KEY_P_SE, KEY_AT_DAKUTEN, KEY_LEFT_BRACKET_KUTEN,
    KEY_ENTER, KEY_A_CHI, KEY_S_TO, KEY_D_SHI
  },
  {
    KEY_F_HA, KEY_G_KI, KEY_H_KU, KEY_J_MA,
    KEY_K_NO, KEY_L_RI, KEY_SEMICOLON_RE, KEY_COLON_KE
  },
  {
    KEY_RIGHT_BRACKET_MU, KEY_Z_TSU, KEY_X_SA, KEY_C_SO,
    KEY_V_HI, KEY_B_KO, KEY_N_MI, KEY_M_MO
  },
  {
    KEY_COMMA_NE, KEY_DOT_RU, KEY_SLASH_NU, KEY_RO,
    KEY_SPACE, KEY_XFER, KEY_ROLL_UP, KEY_ROLL_DOWN
  },
  {
    KEY_INS, KEY_DEL, KEY_UP, KEY_LEFT,
    KEY_RIGHT, KEY_DOWN, KEY_HOME_CLR, KEY_HELP
  },
  {
    KEY_NUMPAD_MINUS, KEY_NUMPAD_DIVIDE, KEY_NUMPAD_7, KEY_NUMPAD_8,
    KEY_NUMPAD_9, KEY_NUMPAD_MULTIPLY, KEY_NUMPAD_4, KEY_NUMPAD_5
  },
  {
    KEY_NUMPAD_6, KEY_NUMPAD_PLUS, KEY_NUMPAD_1, KEY_NUMPAD_2,
    KEY_NUMPAD_3, KEY_NUMPAD_EQUAL, KEY_NUMPAD_0, KEY_NUMPAD_DOT
  },
  {
    KEY_NUMPAD_DOT, KEY_NFER, KEY_VF1, KEY_VF2,
    KEY_VF3, KEY_VF4, KEY_VF5, KEY_NULL
  },
  {
    KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL,
    KEY_NULL, KEY_NULL, KEY_HOME, KEY_NULL
  },
  {
    KEY_STOP, KEY_COPY, KEY_F1, KEY_F2,
    KEY_F3, KEY_F4, KEY_F5, KEY_F6
  },
  {
    KEY_F7, KEY_F8, KEY_F9, KEY_F10,
    KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL
  },
  {
    KEY_SHIFT, KEY_CAPS, KEY_KANA, KEY_GRPH,
    KEY_CTRL, KEY_NULL, KEY_NULL, KEY_NULL
  },
  {
    KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL,
    KEY_NULL, KEY_NULL, KEY_NULL, KEY_NULL
  }
};

/**
 * @brief Indicates which keygroup a key belongs to and its index.
 */
const int keygroup_and_index_of[127][2] = {
  {15, 0},  // KEY_NULL
  {0, 1}, {0, 2}, {0, 3}, {0, 4}, {0, 5}, {0, 6}, {0, 7}, {1, 0}, {1, 1},
  {1, 2}, {3, 5}, {5, 5}, {5, 3}, {3, 7}, {2, 2}, {4, 0}, {4, 1}, {4, 2},
  {2, 7}, {4, 3}, {4, 4}, {4, 5}, {5, 7}, {5, 6}, {3, 0}, {3, 1}, {2, 0},
  {2, 3}, {3, 6}, {2, 4}, {2, 6}, {5, 4}, {2, 1}, {5, 2}, {2, 5}, {5, 1},
  {1, 3}, {1, 4}, {1, 5}, {3, 2}, {3, 3}, {4, 6}, {4, 7}, {5, 0}, {6, 0},
  {6, 1}, {6, 2}, {6, 3}, {0, 0}, {1, 6}, {1, 7}, {3, 4}, {6, 4}, {6, 5},
  {6, 6}, {6, 7}, {7, 0}, {7, 1}, {7, 2}, {7, 3}, {7, 4}, {7, 5}, {7, 6},
  {7, 7}, {10, 1}, {11, 6}, {12, 0}, {12, 1}, {14, 0}, {14, 1}, {14, 2},
  {14, 3}, {14, 4}, {9, 1}, {8, 0}, {8, 5}, {8, 1}, {9, 5}, {9, 7}, {9, 6},
  {9, 2}, {9, 3}, {9, 4}, {8, 6}, {8, 7}, {9, 0}, {8, 2}, {8, 3}, {8, 4},
  {12, 2}, {12, 3}, {12, 4}, {12, 5}, {12, 6}, {12, 7}, {13, 0}, {13, 1},
  {13, 2}, {13, 3}, {10, 2}, {10, 3}, {10, 4}, {10, 5}, {10, 6}
};

bool is_pressed(key_t x);

#pragma endregion  // #pragma region Keyboard handling
#pragma region Character handling

/**
 * @brief Check whether a character is half-width or full-width when printed.
 * Reference: PC-9801 Programers' Bible, Section 4-10 ~ 4-11,
 * https://ja.wikipedia.org/wiki/JIS_X_0213%E9%9D%9E%E6%BC%A2%E5%AD%97%E4%B8%80%E8%A6%A7 .
 *
 * @param ch The character to be checked, should be valid.
 * @return int 1 if the character is half-width, 2 if otherwise.
 */
int char_width(unsigned ch);

/**
 * @brief Print wide char by `putchar`-ing its first and second bit.
 *
 * @param ch The character to be printed.
 */
void wputchar(unsigned ch);

#pragma endregion  // #pragma region Character handling
#pragma region Miscellaneous

// Rotates first and second byte.
unsigned rot(unsigned n);

extern bool is_epson;

const int SCREEN_WIDTH = 80;
const int SCREEN_HEIGHT = 25;

#pragma endregion  // #pragma region Miscellaneous

#endif  // #ifndef THPRAC98_SRC_UTILS_HPP_