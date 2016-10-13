*-----------------------------------------------------------
* Title      : eGenggle
* Written by : Martin Holtkamp
* Date       : 10/14/2016
* Description: A port of the game Genggle from genesis to 
*              to Easy68k. Use left/right to aim ball and 
*              press Z to fire the ball. Hit all red pegs 
*              to clear a level. The fewer red pegs that 
*              remain, the higher the score of hitting a 
*              blue peg.
*-----------------------------------------------------------

START:                  ; first instruction of program
	ORG 0 
    jmp EntryPoint 
    
; CONSTANTS.ASM
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
    
; UTIL.ASM
BITMAP_PIXEL_ARRAY_OFF_OFFSET EQU 10
BITMAP_WIDTH_OFFSET           EQU 18 
BITMAP_HEIGHT_OFFSET          EQU 22 
BITMAP_BPP_OFFSET             EQU 28
BITMAP_HEADER_SIZE            EQU 54

REQUIRED_BITS_PER_PIXEL EQU 4 
 
IO_TASK_PEN_COLOR  EQU 80
IO_TASK_DRAW_PIXEL EQU 82

; ------ SUBROUTINE ------
; SeedRandom
;
; Seeds the random number generator with 
; a given word 
; 
; Input:
;   d0.w = seed 
; ------------------------	
SeedRandom:
    move.w d0, RandVal
    rts 
    
; ------ SUBROUTINE ------
; Random
;
; Returns a byte between
; 
; Output:
;   d0.b = random value (0-255)
; ------------------------	
Random:
    ; Multiply some magic number 
    move.w RandVal, d0 
    move.w #RAND_MULTIPLIER, d1 
    mulu d1, d0 
    
    ; Add some magic number 
    addi.w #RAND_ADDER, d0 
    
    ; Save this as the new random value
    move.w d0, RandVal
    
    ; d0.b will contain a random number 
    ; but mask away other bytes just for safety 
    andi.l #$000000ff, d0 
    
    rts 

    
;------ SUBROUTINE -------
; RenderBitmap16
; Input:
;   a0.l: pointer to bitmap file data 
;   d0.l: bitmap chunk x position
;   d1.l: bitmap chunk y position 
;   d2.l: bitmap chunk width 
;   d3.l: bitmap chunk height 
;   d4.l: render x position 
;   d5.l: render y position 
;-------------------------
RenderBitmap16:

        ; Save subroutine arguments to system memory for recall later 
        move.l a0, bitmap_addr 
        move.l d0, chunk_x 
        move.l d1, chunk_y 
        move.l d2, chunk_width 
        move.l d3, chunk_height 
        move.l d4, render_x
        move.l d5, render_y
       
        ; Examine the bitmap file header, and save important addresses/values
        move.l BITMAP_WIDTH_OFFSET(a0), d0 
        jsr EndianSwap_L
        move.l d0, bitmap_width  
        
        move.l BITMAP_HEIGHT_OFFSET(a0), d0 
        jsr EndianSwap_L
        move.l d0, bitmap_height 
        
        move.w BITMAP_BPP_OFFSET(a0), d0 
        jsr EndianSwap_W 
        move.w d0, bitmap_bpp
         
        ; Find the pixel array address based on the offset given in the header
        move.l BITMAP_PIXEL_ARRAY_OFF_OFFSET(a0), d0    ; d0 = offset in bytes from start of file to pixel array
        jsr EndianSwap_L                                ; correct endianness 
        movea.l a0, a1                                  ; a1 = address of the bitmap file 
        add.l d0, a1                                    ; a1 = address of the color table 
        move.l a1, pixel_array_addr                     ; store the address in memory 
        
        ; Find the color table address. It immediately follows the header.
        movea.l a0, a1                                  ; a1 = address of bitmap file 
        adda.l #BITMAP_HEADER_SIZE, a1                  ; a1 = address of color table 
        move.l a1, color_table_addr                     ; store the address in memory
        
        ; Examine the bits per pixel word to see if this bmp
        ; truly is a 16 color paletted bitmap (4bpp).
        move.w bitmap_bpp, d0
        cmpi.w #REQUIRED_BITS_PER_PIXEL, d0  ; is this bitmap's bitdepth 4?
        bne .return                          ; if not, return and do not attempt to render.
        
        ; Determine the number of nibbles to pad row with.
        ; In the pixel array, the end of each row must be 4-byte aligned
        move.l  bitmap_width, d0               ; d0 = bitmap width 
        lsr.l #1, d0                           ; d0 = bitmap width (bytes)
        addq.l #3, d0                          ; add 3 to offset one long if not long aligned 
        andi.l #$fffffffc, d0                  ; snap to the long word boundary
        move.l d0, bitmap_width_bytes
        
        ; Check for valid chunk_x
        move.l chunk_x, d0 
        move.l bitmap_width, d1 
        cmp.l d0, d1                    ; is the bitmap width bigger than chunk_x?
        bls .return                     ; if so, return. chunk_x is outside of image. nothing to draw. 
        
        ; Check for valid chunk_y
        move.l chunk_y, d0 
        move.l bitmap_height, d1 
        cmp.l d0, d1                    ; is the bitmap height bigger than chunk_y?
        bls .return                     ; if so, return. chunk_y is outside of image. nothing to draw.
        
        ; Check for chunk_width = 0
        move.l chunk_width, d0 
        beq .return 
        
        ; Check for chunk_height = 0 
        move.l chunk_height, d0 
        beq .return 
        
        ; Clamp chunk_width if needed.
        move.l chunk_x, d0 
        move.l chunk_width, d1 
        move.l bitmap_width, d2
        add.l d1, d0                    ; d0 = rightmost edge of chunk + 1 
        subq.l #1, d0                   ; d0 - rightmost edge of chunk
        cmp.l d0, d2                    ;  is the bitmap width bigger than the rightmost edge?
        bhi .clamp_chunk_h              ; then no need to clamp. go check the chunk height
        move.l chunk_x, d0 
        sub.l d0, d2                    ; d2 = bitmap width - chunk x 
        move.l d2, chunk_width          ; save d2 as the new chunk width 
        
.clamp_chunk_h
        move.l chunk_y, d0 
        move.l chunk_height, d1 
        move.l bitmap_height, d2 
        add.l d1, d0 
        subq.l #1, d0                   ; d0 = bottom most edge of chunk
        cmp.l d0, d2                    ; is the bitmap height bigger than the bottom (top) most edge?
        bhi .flip_chunk_y               ; do not clamp if bitmap height is bigger than bottom most edge
        move.l chunk_y, d0 
        sub.l d0, d2                    ; d2 = bitmap height - chunk_y
        move.l d2, chunk_height         ; save the new, clamped chunk height

.flip_chunk_y     
        ; Correct chunk_y because BMP pixel data starts from bottom-left, not top-left
        move.l chunk_y, d0 
        move.l bitmap_height, d1 
        sub.l d0, d1 
        subq.l #1, d1                  ; d1 = the flipped y position in bitmap
        move.l d1, chunk_y             ; save the corrected chunk_y
        
        ; Now we have all the information to perform rendering. 
        ; This loop will begin from the bottom left of the chunk data
        move.l chunk_width, d6          ; d6 = horizontal counter 
        move.l chunk_height, d7         ; d7 = vertical counter 
        move.l render_x, d4             ; d4 = x rendering position
        move.l render_y, d5             ; d5 = y rendering position
        
        move.l pixel_array_addr, a2    
        move.l chunk_x, d0 
        lsr.l #1, d0            ; divide chunk_x by two to get correct byte offset 
        add.l d0, a2            ; offset into the pixel array b chunk_x/2 bytes 
        
        move.l bitmap_width_bytes, d1   ; d1 = width of a row of pixels in bytes
        move.l chunk_y, d0      ; d0 = chunk_y
        mulu.w d1, d0           ; d0 = number of bytes to offset into pixel array, contributed from chunk_y
        add.l d0, a2            ; a2 = address to start reading pixel data from in loop
        
.loop_start 
        move.l a2, a3           ; a3 = this row's starting address (save it for later)
        move.l chunk_x, d0      ; get chunk_x
        btst.l #0, d0           ; test least significant bit 
        bne .loop_odd           ; if bit 0 is not equal to 0, start row at loop_odd
                                ; else fall through to .loop_even 
        
.loop_even
        clr.l d0                  
        move.b (a2), d0           ; d0 = byte with two pixels worth of information
        andi.b #$f0, d0           ; mask out bits to leave the first pixel's color index 
        lsr.b #2, d0              ; shift twice to the right to get offset into color table in bytes
                                  ; instead of the andi + lsr, lsr #4 + lsl #2 could be used for same effect
                                  ; essential 4*index to get the offset in bytes into the color table
        move.l color_table_addr, a0 
        add.l d0, a0              ; a0 = pointer to 4 byte color BGRX 
        
        move.l (a0), d1           ; d1 = pixel color, BGRX
        lsr.l #8, d1              ; d1 = pixel color, 0BGR
        move.l #IO_TASK_PEN_COLOR, d0 
        trap #15                  ; set system's pen color 
        
        move.l d4, d1             ; d1 = render x
        addq.l #1, d4             ; increment render x 
        move.l d5, d2             ; d2 = render y 
        move.l #IO_TASK_DRAW_PIXEL, d0 
        trap #15 
        
        subq.l #1, d6             ; subtract horizontal counter 
        beq .loop_end             ; branch if finished with row 

.loop_odd 
        clr.l d0                  
        move.b (a2)+, d0          ; d0 = byte with two pixels worth of information
        andi.b #$0f, d0           ; mask out bits to leave the second pixel's color index 
        lsl.b #2, d0              ; shift twice to the left to mult by 4 to get color table offset

        move.l color_table_addr, a0 
        add.l d0, a0              ; a0 = pointer to 4 byte color BGRX 
        
        move.l (a0), d1           ; d1 = pixel color, BGRX
        lsr.l #8, d1              ; d1 = pixel color, 0BGR
        move.l #IO_TASK_PEN_COLOR, d0 
        trap #15                  ; set system's pen color 
        
        move.l d4, d1             ; d1 = render x
        addq.l #1, d4             ; increment render x 
        move.l d5, d2             ; d2 = render y 
        move.l #IO_TASK_DRAW_PIXEL, d0 
        trap #15                  ; draw pixel on screen
        
        subq.l #1, d6             ; subtract horizontal counter 
        bne .loop_even            ; branch back to even if not finished with row 

.loop_end      
        move.l render_x, d4       ; reset x rendering position 
        move.l chunk_width, d6    ; reset horizontal counter 
        movea.l a3, a2            ; get the address of first pixel for the just-rendered row 
        suba.l bitmap_width_bytes, a2  ; point to the first pixel of the next row 
        addq.l #1, d5             ; move the y rendering position one scanline down 
        subq.l #1, d7             ; decrement the vertical counter by 1 
        bne .loop_start
        
.return 
        rts 

        ORG (*+1)&-2
bitmap_addr            ds 4 
chunk_x                ds 4
chunk_y                ds 4         
chunk_width            ds 4 
chunk_height           ds 4
render_x               ds 4 
render_y               ds 4 
bitmap_width           ds 4 
bitmap_height          ds 4 
bitmap_bpp             ds 2 
color_table_addr       ds 4 
pixel_array_addr       ds 4 
bitmap_width_bytes     ds 4 


;------ SUBROUTINE -------
; EndianSwap_L
; Input:
;   d0.l: value to be swapped
; Output:
;   d0.l: the swapped value
;------------------------- 
EndianSwap_L:
        rol.w #8, d0 
        swap.w d0 
        rol.w #8, d0 
        rts
        
        
;------ SUBROUTINE -------
; EndianSwap_W
; Input:
;   d0.w: value to be swapped
; Output:
;   d0.w: the swapped value
;------------------------- 
EndianSwap_W:
        rol.w #8, d0 
        rts

; ------ SUBROUTINE ------
; LoadStart
;
; Loads graphics data necessary for displaying the 
; start screen. 
; ------------------------		
LoadStart:

    DRAW_START_BITMAP_HERE
	
	rts 
	
; ------ SUBROUTINE ------
; UpdateStart
;
; Checks if the user has pressed start to begin 
; the game.
; ------------------------		
UpdateStart:
	
    ; Update the frame counter in preparation 
    ; for seeding the random number generator 
    move.w FrameCounter, d0 
    addq.w #1, d0 
    move.w d0, FrameCounter
    
	; Check if the start button is down.
	; If so, transition to game
	move.w ButtonsDown, d0 
	btst #BUTTON_START, d0
	bne .return 
    jsr SetRandSeed
	jsr LoadGame
	move.l #STATE_AIM, GameState
.return 
	rts 
    
SetRandSeed:

    move.w FrameCounter, d0 
    jsr SeedRandom
    rts 
    
	INCLUDE "source/game.asm"
	INCLUDE "source/tables.asm"
	INCLUDE "source/ball.asm"
    INCLUDE "source/peg.asm"
    INCLUDE "source/rect.asm"
	INCLUDE "source/saver.asm"
	
	; Level includes 
	EVEN 
	INCLUDE "levels/level0.asm"
    INCLUDE "levels/level1.asm"
	INCLUDE "levels/levels.asm"    
    

EntryPoint:
    
    ; Set up the stack pointer 
    move.l #$00000000, sp
	
	jsr LoadStart
	move.l #STATE_START, GameState
	
Main_Loop:

	;jsr WaitVblank
	jsr UpdateButtons
	
	move.l GameState, d0 
	cmpi.l #STATE_START, d0 
	bne .check_aim
	jsr UpdateStart
	jmp Main_Loop

.check_aim
	cmpi.l #STATE_AIM, d0 
	bne .check_resolve 
	jsr UpdateAim
	jmp Main_Loop
	
.check_resolve
	cmpi.l #STATE_RESOLVE, d0 
	bne .check_lose 
	jsr UpdateResolve 
	jmp Main_Loop
	
.check_lose 
	cmpi.l #STATE_LOSE, d0 
	bne .check_win 
	move.l #STATE_START, GameState
	jmp Main_Loop
	
.check_win
	
	jmp Main_Loop        ; go to next iteration of game loop
	
	
    ; BITMAP includes 
	EVEN
TitleBitmap:
	INCBIN "bitmaps/title.bmp"
RedPegBitmap:
	INCBIN "bitmaps/red_peg.bmp"
BluePegBitmap:
	INCBIN "bitmaps/blue_peg.bmp"
GreenPegBitmap:
	INCBIN "bitmaps/green_peg.bmp"
PurplePegBitmap:
	INCBIN "bitmaps/purple_peg.bmp"
SaverBitmap:
	INCBIN "bitmaps/saver.bmp"
BGBitmap:
    INCBIN "bitmaps/background.bmp"
    
    Pegs:
    ds.b MAX_PEGS*PEG_DATA_SIZE
    
Ball:
    ds.b BALL_DATA_SIZE
    
Saver:
    ds.b SAVER_DATA_SIZE 

; All global variables are assumed to be longs even if not
; used as such in the program.
ButtonsDown:
    ds.l 1  
GameState:
    ds.l 1
VblankFlag:
    ds.l 1
AimAngle:
    ds.l 1
Level:
    ds.l 1
BallCount:
    ds.l 1
LevelPegCount:
    ds.l 1
LevelRedPegCount:
    ds.l 1
LevelBallCount:
    ds.l 1
RandVal:
    ds.l 1
FrameCounter:
    ds.l 1
RedPegCount:
    ds.l 1
PegCount:
    ds.l 1
Score:
    ds.l 1
    
    
END    START        ; last line of source
	


*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
