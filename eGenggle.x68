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
    
    ; Consts include 
    INCLUDE "source/constants.asm"
    
    ; BSS data  
	INCLUDE "source/bss.asm"
    
    ; CODE includes 
	INCLUDE "source/util.asm"
	INCLUDE "source/start.asm"
	INCLUDE "source/game.asm"
	INCLUDE "source/tables.asm"
	INCLUDE "source/ball.asm"
    INCLUDE "source/peg.asm"
    INCLUDE "source/rect.asm"
	INCLUDE "source/saver.asm"
    
	; TILE includes 
	ORG (*+1)&-2
TitleBitmap:
	INCBIN "bitmaps/title.bmp"
RedPegBitmap:
	INCBIN "bitmaps/red_peg.bmp"
BluePegBitmap:
	INCBIN "bitmaps/blue_peg.bmp"
BallBitmap:
	INCBIN "bitmaps/green_peg.bmp"
SaverBitmap:
	INCBIN "bitmaps/saver.bmp"
BGBitmap:
    INCBIN "bitmaps/background.bmp"
LoseBitmap:
    INCBIN "bitmaps/lose.bmp"
WinBitmap:
    INCBIN "bitmaps/win.bmp"
	
	; Level includes 
	ORG (*+1)&-2 
	INCLUDE "levels/level0.asm"
    INCLUDE "levels/level1.asm"
	INCLUDE "levels/levels.asm"    
	
SegmentsLitTable:
    dc.b $3f
    dc.b $03 
    dc.b $6D
    dc.b $67
    dc.b $53 
    dc.b $76
    dc.b $7E
    dc.b $23 
    dc.b $7F 
    dc.b $73 
    
SegmentsPosTable:
    ; seg a 
    dc.w 400
    dc.w 100
    dc.w 400
    dc.w 150

    ; seg b 
    dc.w 400
    dc.w 150 
    dc.w 400
    dc.w 200 

    ; seg c 
    dc.w 400 
    dc.w 200
    dc.w 360 
    dc.w 200

    ; seg d 
    dc.w 360
    dc.w 200
    dc.w 360 
    dc.w 150 

    ; seg e 
    dc.w 360
    dc.w 150 
    dc.w 360 
    dc.w 100 

    ; seg f 
    dc.w 360
    dc.w 100
    dc.w 400
    dc.w 100 

    ; seg g 
    dc.w 360
    dc.w 150
    dc.w 400
    dc.w 150

    

EntryPoint:
    
    ; Set up the stack pointer 
    move.l #$00000000, sp
    
    ; Enable the double buffered draw mode 
    move.l #DRAW_MODE_DOUBLE_BUFFERED, d1 
    move.l #DRAW_MODE_TRAP_CODE, d0 
    trap #15
    
    ; Initialize the starting time
    move.l #TIME_TRAP_CODE, d0 
    trap #15 
    move.l d1, CurTime
	
	jsr LoadStart
	move.l #STATE_START, GameState
	
Main_Loop:

    jsr WaitForFrame

	; Swap buffers 
	move.l #SWAP_BUFFERS_TRAP_CODE, d0 
	trap #15 
	
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
	jsr DrawSevenSeg
	jmp Main_Loop
	
.check_resolve
	cmpi.l #STATE_RESOLVE, d0 
	bne .check_lose 
	jsr UpdateResolve 
	jsr DrawSevenSeg
	jmp Main_Loop
	
.check_lose 
	cmpi.l #STATE_LOSE, d0 
	bne .check_win 
	jsr UpdateLoseWin
	jmp Main_Loop
	
.check_win
    cmpi.l #STATE_WIN, d0 
    bne .error_state 
    jsr UpdateLoseWin 
    jmp Main_Loop
    
.error_state 
	
	jmp Main_Loop      ; Hopefully never get to this point 
	
	
	
WaitForFrame:
    
    move.l CurTime, d1 
    add.l #FRAME_TIME, d1 
    move.l d1, d2 
    
.wait_loop
    
    ; Get the current time 
    move.l #TIME_TRAP_CODE, d0 
    trap #15 
    
    cmp.l d1, d2 
    bge .wait_loop 
    
    ; Reco
    move.l d1, CurTime 

    rts 
    


    
DrawSevenSeg:

    ; Clear prev display 
    ;move.l #$000000, d1 
    ;move.l #PEN_COLOR_TRAP_CODE, d0 
    ;trap #15
    ;move.l #$000000, d1 
    ;move.l #FILL_COLOR_TRAP_CODE, d0 
    ;trap #15
    

    ; Set pen color to white 
    move.l #$ffffff, d1 
    move.l #PEN_COLOR_TRAP_CODE, d0 
    trap #15 
    
    move.l BallCount, d7
    move.l #7, d6               ; d6 = 7 = times to loop
    clr.l d5                    ; d5 holds the offset into seg pos table 
    lea SegmentsPosTable, a0 
    
    ; Which leds are being used?
    lea SegmentsLitTable, a1 
    adda.l d7, a1               ; add the ball count to table to get addr of index we want to render
    clr.l d2 
    move.b (a1), d7             ; d7 holds the lit bitfield. We dont need ball count any more.
    
.loop 
    btst.l #0, d7
    beq .continue 
    
    ; This bit was 1. So draw a line!
    lea SegmentsPosTable, a0 
    adda.l d5, a0 
    move.w (a0)+, d1 
    move.w (a0)+, d2 
    move.w (a0)+, d3 
    move.w (a0)+, d4 
    
    move.l #DRAW_LINE_TRAP_CODE, d0 
    trap #15 
    
.continue

    ; shift lit bitfield 1 
    lsr.l #1, d7 
    addi.l #8, d5       ; move offset into pos table by 8 bytes (4 words)
    subq.l #1, d6
    bne .loop 
    
    rts 
    
 
    
    END    START        ; last line of source
	








*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
