; Structures and enums in TH01.
; This is a snippet file and should be `include`d in the assembly source file
; instead of being linked with the other .OBJ files.

pushstate
ideal
radix 10
locals
p386

struc rgb_t
        red     db ?
        green   db ?
        blue    db ?
ends rgb_t

; For the C version of these structures, see
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/resident.hpp#L8-L72 .

enum bgm_mode_t \
        BGM_MODE_OFF, BGM_MODE_MDRV2, BGM_MODE_COUNT
enum route_t                                    \
        ROUTE_MAKAI, ROUTE_JIGOKU, ROUTE_COUNT, \
        route_t_FORCE_INT16 = 7FFFh
enum end_sequence_t \
        ES_NONE, ES_MAKAI, ES_JIGOKU
enum debug_mode_t                               \
        DM_OFF = 0, DM_TEST = 1, DM_FULL = 3,   \
        debug_mode_t_FORCE_INT16 = 7FFFh

SCENE_COUNT             = 4
STAGES_PER_SCENE        = 5
struc resident_t
        id                      db 14 dup (?)   ; sizeof(RES_ID)
                                                ; (i.e. "ReiidenConfig")
        rank                    db ?
        bgm_mode                bgm_mode_t ?
        rem_bombs               db ?
        credit_lives_extra      db ?            ; Add 2 for the actual
                                                ; number of lives
        end_flag                end_sequence_t ?
        unused_1                db ?
        route                   db ?            ; actual type: route_t
        rem_lives               db ?
        snd_need_init           db ?            ; actual type: bool
        unused_2                db ?
        debug_mode              db ?            ; actual type: debug_mode_t
        pellet_speed            dw ?            ; pre-multiplied by 40
        rand                    dd ?
        score                   dd ?
        continues_total         dd ?
        continues_per_scene     dw SCENE_COUNT dup (?)
        bonus_per_stage         dd (STAGES_PER_SCENE - 1) dup (?)
                                                ; of the current scene, without
                                                ; the boss stage
        stage_id                dw ?
        hiscore                 dd ?
        score_highest           dd ?            ; among all continues
        point_value             dw ?
ends resident_t

; For the C version of the structure, see
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/formats/cfg.hpp#L7-L12 .
struc cfg_options_t
        rank                    db ?
        bgm_mode                bgm_mode_t ?
        credit_bombs            db ?
        credit_lives_extra      db ?    ; Add 2 for the actual number of lives
ends cfg_options_t

; For the C version of these enums, see
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/main/boss/b15m.cpp#L71-L100 .

enum elis_form_t                        \
        F_GIRL, F_BAT,                  \
        elis_form_t_FORCE_INT16 = 7FFFh
BAT_CELLS                               = 3
enum elis_entity_cel_t                                          \
        C_STILL = 0, C_HAND = 1, C_WAVE_1 = 2, C_WAVE_2 = 3,    \
        C_WAVE_3 = 4, C_WAVE_4 = 5,                             \
        C_PREPARE = 0, C_ATTACK_1 = 1, C_ATTACK_2 = 2,          \
        C_BAT = 0, C_BAT_LAST = C_BAT + BAT_CELLS - 1

; For the C version of the structure, see
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/game/coords.hpp#L26-L29 .
struc lrtb_word_word
        left    dw ?
        right   dw ?
        top     dw ?
        bottom  dw ?
ends lrtb_word_word

; For the C version of the structure, see
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/main/boss/entity_a.hpp#L15-L364 .
struc cbossentity
        cur_left        dw ?
        cur_top         dw ?
        prev_left       dw ?
        prev_top        dw ?
        vram_w          dw ?
        h               dw ?
        move_clamp      lrtb_word_word ?  ; relative to VRAM
        hitbox_orb      lrtb_word_word ?  ; relative to [cur_left] and [cur_top]

        ; Never actually read outside of the functions that set them...
        prev_delta_y    dw ?
        prev_delta_x    dw ?

        bos_image_count dw ?

        zero_1          dw ?
        bos_image       dw ?
        unknown         dw ?

        hitbox_orb_inactive     dw ?
        loading                 dw 0

        ; Locks both movement and rendering via the locked_*() methods if
        ; nonzero.
        lock_frame      dw ?

        zero_2          dw ?
        zero_3          db 0
        bos_slot        db ?
ends cbossentity
ERRIFE size cbossentity eq 32h

; For the C version of these enums, see
; https://github.com/H-J-Granger/ReC98/blob/b6ba5b0a529edbb31efdf8c0e939263804f8ee47/th01/sprites/main_ptn.h#L32-L150 .

ORB_CELS                = 4
PORTAL_ANIM_CELS        = 2
LIVES_MAX               = 6
BOMBS_MAX		= 5
PTN_W                   = 32
PTN_H                   = 32
DASH_CELS		= 2
MISS_EFFECT_CELS	= 2
SCORE_DIGITS		= 7
TIMER_DIGITS		= 4
HP_MAX			= 96
HP_H                    = 15
HP_POINT_W		= 8

enum main_ptn_slot_t {
        PTN_SLOT_STG = 0, ; stg(_b).ptn
        PTN_SLOT_MIKO = 1, ; miko.ptn

        ; .PTN slots that can be freely used by bosses. Randomly assigned to the
        ; backgrounds behind animated boss entities, as well as the missile
        ; sprites from boss3_m.ptn and Kikuri's ripple sprites from tamayen.ptn.
        PTN_SLOT_BOSS_1 = 2,
        PTN_SLOT_BOSS_2 = 3,

        PTN_SLOT_BG_HUD = 5,
        PTN_SLOT_NUMB = 7, ; numb.ptn
        PTN_SLOT_COUNT,

        _main_ptn_slot_t_FORCE_INT16 = 7FFFh
}

enum main_ptn_id_t {
        ;; stg(_b).ptn
        ;; -----------
        PTN_HUD = PTN_SLOT_STG * 64 + 0,
        PTN_SHOT,
        PTN_BLAST, ; ???
        PTN_ORB,
        PTN_ORB_last = PTN_ORB + ORB_CELS - 1,

        ; stg.ptn exclusives
        ; ------------------
        PTN_CARD_UNUSED,
        PTN_CARD_3HP, PTN_CARD_3HP_HALF, PTN_CARD_3HP_EDGE,
        PTN_CARD_2HP, PTN_CARD_2HP_HALF, PTN_CARD_2HP_EDGE,
        PTN_CARD_1HP, PTN_CARD_1HP_HALF, PTN_CARD_1HP_EDGE,
        PTN_CARD_0HP, PTN_CARD_0HP_HALF, PTN_CARD_0HP_EDGE,
        PTN_CARD_REMOVED_HALF,
        PTN_CARD_REMOVED,

        PTN_BUMPER,
        PTN_TURRET,
        PTN_TURRET_FIRING,
        PTN_BAR_TOP,
        PTN_BAR_LEFT,
        PTN_BAR_BOTTOM,
        PTN_BAR_RIGHT,
        PTN_PORTAL,
        PTN_PORTAL_ANIM,
        PTN_PORTAL_ANIM_last = (PTN_PORTAL_ANIM + (PORTAL_ANIM_CELS - 1)),

        PTN_ITEM_BOMB,
        PTN_ITEM_POINT,
        ; ------------------
        ;; -----------


        ; miko.ptn
        ; --------
        ; Facing left
        PTN_MIKO_L = PTN_SLOT_MIKO * 64 + 0,
        PTN_MIKO_L_DASH,
        PTN_MIKO_L_DASH_last = (PTN_MIKO_L_DASH + DASH_CELS - 1),
        PTN_MIKO_L_CAST,
        PTN_MIKO_L_DASH_SHOOT,
        PTN_MIKO_L_DASH_SHOOT_last = (PTN_MIKO_L_DASH_SHOOT + DASH_CELS - 1),
        ; Facing right
        PTN_MIKO_R = PTN_SLOT_MIKO * 64 + 10,
        PTN_MIKO_R_DASH,
        PTN_MIKO_R_DASH_last = (PTN_MIKO_R_DASH + DASH_CELS - 1),
        PTN_MIKO_R_CAST,
        PTN_MIKO_R_DASH_SHOOT,
        PTN_MIKO_R_DASH_SHOOT_last = (PTN_MIKO_R_DASH_SHOOT + DASH_CELS - 1),

        PTN_MISS_EFFECT = PTN_SLOT_MIKO * 64 + 20,
        PTN_MISS_EFFECT_last = (PTN_MISS_EFFECT + MISS_EFFECT_CELS - 1),

        PTN_MIKO_MISS,
        PTN_MIKO_MISS_ALTERNATE,
        ; --------


        ; HUD (snapped backgrounds)
        ; -------------------------
        ; The usage code doesn't really cap either of these, though...
        PTN_BG_first = PTN_SLOT_BG_HUD * 64 + 0,
        PTN_BG_LIVES = PTN_BG_first,
        PTN_BG_LIVES_last = PTN_BG_LIVES + (LIVES_MAX + 3) / 4 - 1,
        PTN_BG_STAGE,
        PTN_BG_STAGE_last, ; But the original game only need a single quarter?
        PTN_BG_BOMBS,
        PTN_BG_BOMBS_last = PTN_BG_BOMBS + (BOMBS_MAX + 3) / 4 - 1,

        PTN_BG_CUR_SCORE,
        PTN_BG_CUR_SCORE_last = PTN_BG_CUR_SCORE + (SCORE_DIGITS + 3) / 4 - 1,
        PTN_BG_CUR_CARDCOMBO,

        PTN_BG_MAX_SCORE = PTN_SLOT_BG_HUD * 64 + 10,
        PTN_BG_MAX_SCORE_last = PTN_BG_MAX_SCORE + (SCORE_DIGITS + 3) / 4 - 1,
        PTN_BG_MAX_CARDCOMBO,

        PTN_BG_TIMER,
        PTN_BG_TIMER_last = PTN_BG_TIMER + (TIMER_DIGITS / 2 + 3) / 4 - 1,

        ; Copying the declaration from `ptn.hpp`... Thankfully, even Turbo C++
        ; 4.0J warns on a mismatch.
        PTN_BG_HP,
        PTN_BG_HP_last = (PTN_BG_HP + ( \
                (HP_MAX / ((PTN_W * PTN_H) / (HP_POINT_W * HP_H))) \
        ) - 1),

        PTN_BG_last = PTN_BG_HP_last,
        ; -------------------------

        ; Numerals on the TOTLE screen
        ; -----------------------------
        PTN_TOTLE_NUMERAL_32 = PTN_SLOT_NUMB * 64 + 0,
        PTN_TOTLE_NUMERAL_32_last = (PTN_TOTLE_NUMERAL_32 + 9),
        PTN_TOTLE_NUMERAL_16,
        PTN_TOTLE_NUMERAL_16_last = PTN_TOTLE_NUMERAL_16 + (10 + 3) / 4 - 1
        ; -----------------------------
}
ERRIFE PTN_ORB    eq 3
ERRIFE PTN_MIKO_L eq 64

PLAYER_W                = 32
PLAYER_H                = 32
PLAYFIELD_BOTTOM        = 400
PLAYER_TOP              = (PLAYFIELD_BOTTOM - PLAYER_H)

popstate
