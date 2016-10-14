; ------ SUBROUTINE ------
; LoadStart
;
; Loads graphics data necessary for displaying the 
; start screen. 
; ------------------------		
LoadStart:

    move.l #0, d0             ; param d0: chunk x coordinate
    move.l #0, d1             ; param d1: chunk y coordinate 
    move.l #320, d2           ; param d2: chunk width 
    move.l #224, d3           ; param d3: chunk height 
    move.l #0, d4             ; param d4: screen x coordinate
    move.l #0, d5             ; param d5: screen y coordinate 
    lea TitleBitmap, a0       ; param a0: pointer to bitmap file data
    jsr RenderBitmap16 
	
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
    move.w PrevDown, d1 
    not.w d1 
    or.w d1, d0 
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