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

popstate
