KEY_LIST EQU $25275A0D
KEYBOARD_INPUT_TRAP_CODE EQU 19
DRAW_MODE_TRAP_CODE EQU 92 
SWAP_BUFFERS_TRAP_CODE EQU 94 
DRAW_MODE_DOUBLE_BUFFERED EQU 17 
PEN_COLOR_TRAP_CODE EQU 80
FILL_COLOR_TRAP_CODE EQU 81 
DRAW_RECT_TRAP_CODE EQU 87
TIME_TRAP_CODE EQU 8 
DRAW_LINE_TRAP_CODE EQU 84
FRAME_TIME EQU 1

BUTTON_UP    EQU $0 
BUTTON_DOWN  EQU $1 
BUTTON_LEFT  EQU $2 
BUTTON_RIGHT EQU $3 
BUTTON_A     EQU $C
BUTTON_B     EQU $4 
BUTTON_C     EQU $5 
BUTTON_START EQU $D

TO_FIXED EQU 256

SCREEN_WIDTH EQU 320
SCREEN_HEIGHT EQU 224

RAND_MULTIPLIER EQU 417
RAND_ADDER EQU 2345

; Game consts 
AIM_CENTER_X EQU 154*TO_FIXED
AIM_CENTER_Y EQU 5*TO_FIXED 
AIM_RADIUS EQU 30*TO_FIXED 
AIM_START_ANGLE EQU 90*TO_FIXED
AIM_ANGLE_DELTA EQU 2*TO_FIXED
AIM_ANGLE_MIN EQU 5*TO_FIXED
AIM_ANGLE_MAX EQU 175*TO_FIXED

LAUNCH_SPEED EQU 4*TO_FIXED 
GRAVITY EQU 18
FALLOUT_Y EQU 224*TO_FIXED
LEFT_BOUND EQU 0*TO_FIXED
RIGHT_BOUND SET (320*TO_FIXED)-BALL_WIDTH

BALLS_STRING_X EQU 1 
BALLS_STRING_Y EQU 0

SCORE_STRING_X EQU 29 
SCORE_STRING_Y EQU 0 

SAVE_STRING_X EQU 2 
SAVE_STRING_Y EQU 2 
 
; Game states 
STATE_START   EQU 0 
STATE_AIM     EQU 1 
STATE_RESOLVE EQU 2 
STATE_LOSE    EQU 3 
STATE_WIN     EQU 4 

; Genggle Data sizes 
PEG_DATA_SIZE    EQU 32 
BALL_DATA_SIZE   EQU 32 
SAVER_DATA_SIZE  EQU 32 

; Shift values for multiplying 
PEG_SIZE_SHIFT   EQU 5 
BALL_SIZE_SHIFT  EQU 5 
SAVER_SIZE_SHIFT EQU 5 

; Game consts 
MAX_PEGS EQU 30 
MAX_GENGGLE_SPRITES EQU 32
SPRITE_DISABLE_X EQU 20 
SPRITE_DISABLE_Y EQU 20 

BALL_WIDTH EQU 8*TO_FIXED 
BALL_HEIGHT EQU 8*TO_FIXED
BALL_PATTERN EQU 67

PEG_INIT_X EQU -108*TO_FIXED
PEG_INIT_Y EQU -108*TO_FIXED
PEG_WIDTH  EQU 8*TO_FIXED
PEG_HEIGHT EQU 8*TO_FIXED
PEG_PALETTE EQU 1

PEG_TYPE_BLUE   EQU 0 
PEG_TYPE_RED    EQU 1 
PEG_TYPE_PURPLE EQU 2 

SAVER_INIT_X EQU 20*TO_FIXED 
SAVER_INIT_Y EQU 212*TO_FIXED 
SAVER_WIDTH EQU 32*TO_FIXED 
SAVER_HEIGHT EQU 8*TO_FIXED
SAVER_XVEL EQU 2*TO_FIXED
SAVER_RECT_OFFSET_X EQU 0 
SAVER_RECT_OFFSET_Y EQU 8 
SAVER_LEFT_BOUND EQU 0*TO_FIXED
SAVER_RIGHT_BOUND EQU 288*TO_FIXED

BALL_SPRITE_INDEX  EQU 0 
SAVER_SPRITE_INDEX EQU 1 
PEGS_SPRITE_INDEX  EQU 2 

NUM_LEVELS EQU 8 

LEVEL_PEG_COUNT_OFFSET     EQU 0 
LEVEL_RED_PEG_COUNT_OFFSET EQU 4 
LEVEL_BALL_COUNT_OFFSET    EQU 8 
LEVEL_PEGS_OFFSET          EQU 12 

MAX_SQRT_INPUT EQU 128
DAMPENING_COEFFICIENT EQU $e0

RED_PEG_SCORE EQU 2 
BLUE_PEG_LOW_SCORE  EQU 4 
BLUE_PEG_MID_SCORE  EQU 2 
BLUE_PEG_HIGH_SCORE EQU 1
LOW_RED EQU 2 
MID_RED EQU 6
HIGH_RED EQU 32 
