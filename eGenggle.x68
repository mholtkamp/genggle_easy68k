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
	jmp Main_Loop
	
.check_resolve
	cmpi.l #STATE_RESOLVE, d0 
	bne .check_lose 
	jsr UpdateResolve 
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
    
    END    START        ; last line of source
	






*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
