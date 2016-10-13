; ------ SUBROUTINE ------
; LoadGame
;
; Changes the scroll A map to the game map. 
; Initializes important game variables.
; Should be called before starting a new game
; from level 0.
; ------------------------	
LoadGame:
	
    ; Initialize ball 
    lea Ball, a0 
    jsr Ball_Init 
    
    ; Initialize saver 
    lea Saver, a0 
    jsr Saver_Init
    
    ;Draw background 
    jsr DrawBackground 
	
    move.l #0, Level
	jsr LoadLevel
    
    ; Reset score 
    move.l #0, Score 
    jsr DrawScore
	
	rts
	
; ------ SUBROUTINE ------
; LoadLevel
;
; Loads the level based on the value in 
; Level global variable.
; ------------------------	
LoadLevel:

	; Reset aim angle 
	move.l #AIM_START_ANGLE, AimAngle 
	
	; Reset pegs to default values 
    jsr ClearPegs
    
    ; Get the level data needed for loading
	move.l Level, d0 
    cmpi.l #(NUM_LEVELS), d0
    blo .load_pegs 
    
    ; confine level number to range [0, NUM_LEVELS)
    move.l #(NUM_LEVELS-1), d0 
    
.load_pegs
    ; d0 contains level number. 
    ; multiply it by 4 to get the long offset into level data table 
    lsl.l #2, d0 
    lea LevelData, a0 
    add.l d0, a0            ; a0 now pointing at current level data address
    move.l (a0), a1         ; a1 is not pointing to current level data 
    move.l a1, a0           ; but put this back in a0 
    
    ; Get the level properties 
    move.l LEVEL_PEG_COUNT_OFFSET(a0), LevelPegCount
    move.l LEVEL_RED_PEG_COUNT_OFFSET(a0), LevelRedPegCount 
    move.l LEVEL_BALL_COUNT_OFFSET(a0), LevelBallCount 
    move.l LevelPegCount, PegCount
    move.l LevelRedPegCount, RedPegCount    ; set the number of red pegs to get 
    move.l LevelBallCount, BallCount        ; reset ball count 
    
    adda.l #LEVEL_PEGS_OFFSET, a0       ; a0 = pointer to peg pos array in leveldata  
    lea Pegs, a1                        ; a1 = peg array 
    clr.l d0                            ; d0 = counter 
    
    ; Loop through the peg data and position pegs accordingly
.peg_loop 
    ; set x position of peg 
    clr.l d1 
    move.w (a0)+, d1            ; d1 = x pos 
    lsl.l #8, d1                ; convert from integer to fixed 
    move.l d1, M_PEG_X(a1)
    
    ; set y position of peg 
    clr.l d1 
    move.w (a0)+, d1 
    lsl.l #8, d1 
    move.l d1, M_PEG_Y(a1)
    
    ; mark the peg as active 
    move.b #1, M_PEG_ACTIVE(a1)    ; 1 = active 
    
    ; Update peg sprite 
    move.l a0, -(sp)
    move.l a1, -(sp)
    move.l d0, -(sp)            ; save reg state
    
    move.l a1, a0 
    jsr Peg_Draw
    
    move.l (sp)+, d0 
    move.l (sp)+, a1 
    move.l (sp)+, a0            ; restore reg state
    
    ; point to next peg struct in preparation for next iteration 
    adda.l #PEG_DATA_SIZE, a1 
    
    ; check if loop should be repeated 
    addq.l #1, d0 
    cmp.l LevelPegCount, d0 
    bne .peg_loop
    
.set_red_pegs 
    move.l LevelRedPegCount, d1 
    move.l LevelPegCount, d2 
    
.red_peg_loop
    ; First, get a random byte value 
    movem.l d1-d2, -(sp)    ; save regs before calling Peg_InitSprite 
    jsr Random          ; d0.b = random value 
    movem.l (sp)+, d1-d2 
    
    divu d2, d0             ; random val / num pegs 
    swap.w d0               ; get the remainder into d0.w 
    andi.l #$0000ffff, d0   ; clear the quotient portion 
    
    ; get the peg at this index 
    lsl.l #PEG_SIZE_SHIFT, d0
    lea Pegs, a0 
    add.l d0, a0 
    
    ; examine this random peg. if it's already red, then 
    ; keep looping until a blue one is found 
.find_blue_loop
    move.b M_PEG_TYPE(a0), d3 
    cmpi.b #PEG_TYPE_BLUE, d3 
    beq .found_blue                 ; is this a blue peg? Then branch past this infinite loop 
    
    adda.l #PEG_DATA_SIZE, a0       ; increment to next peg 
    cmp.l #(Pegs+PEG_DATA_SIZE*MAX_PEGS), a0 ; but check if we just overran the peg array 
    blo .find_blue_loop
    
    lea Pegs, a0                   ; we are past the last peg in the array. reset to first peg.
    jmp .find_blue_loop
    
.found_blue 
    ; A blue peg as found. Set it to red and then update the sprite 
    move.b #PEG_TYPE_RED, M_PEG_TYPE(a0)
    
    movem.l d1-d2, -(sp)    ; save regs before calling Peg_InitSprite 
    jsr Peg_Draw
    movem.l (sp)+, d1-d2 
    
    ; decrement counter 
    subq.l #1, d1 
    bne .red_peg_loop
    
    ; draw the new ball count 
    jsr DrawBallCount
    
	rts 
	
; ------ SUBROUTINE ------
; UpdateAim
;
; Updates the aim angle based on user input.
; Sets the ball based on the aim angle. 
; Will launch ball and enter the resolve state 
; if the user pressed A. 
; Should only be called in STATE_AIM
; ------------------------	
UpdateAim:

	move.w ButtonsDown, d0 
	move.l AimAngle, d1
	
	btst #BUTTON_LEFT, d0 
	bne .check_right
	addi.l #AIM_ANGLE_DELTA, d1 
	jmp .clamp_aim_angle
.check_right
	btst #BUTTON_RIGHT, d0 
	bne .clamp_aim_angle
	subi.l #AIM_ANGLE_DELTA, d1 
	
.clamp_aim_angle
	cmpi.l #AIM_ANGLE_MIN, d1 
	bgt .check_clamp_max
	move.l #AIM_ANGLE_MIN, d1 
	jmp .save_aim_angle
.check_clamp_max
	cmpi.l #AIM_ANGLE_MAX, d1 
	blt .save_aim_angle 
	move.l #AIM_ANGLE_MAX, d1 
	
.save_aim_angle
	move.l d1, AimAngle 
	
	jsr _PositionBall
	jsr _CheckLaunch
    
    lea Saver, a0  
    jsr Saver_Update 

.return 
	rts 
	
; ------ SUBROUTINE ------
; _PositionBall
;
; Private subroutine that positions the ball 
; based on the current AimAngle.
; ------------------------	
_PositionBall:
	
    lea Ball, a0 
    jsr Ball_Hide
    
	; Get delta x from center 
	move.l #(AIM_RADIUS>>8), d0 		
	move.l AimAngle, d1 			; load global var AimAngle into d1 
	lsr.l #8, d1 					; convert from fixed to int 
	
	lea CosTable, a0 
	lsl.l #1, d1 					; multiply angle by 2 to get word-offset into table 
	add.l d1, a0 					; a0 pointing at cos((int)AimAngle)
	move.w (a0), d1 				; d1 = 8.8 cos value 
	
	muls d0, d1 					; d1 = AIM_RADIUS * cos(AimAngle) = DeltaX * 256 
	
	move.l #AIM_CENTER_X, d2 
	add.l d2, d1 					; d1 = ball x pos. (x = AIM_CENTER_X + DeltaX)
	

	; Get delta y from center 
	move.l AimAngle, d2 			; load global var AimAngle into d2 
	lsr.l #8, d2 					; convert from fixed to int 
	
	lea SinTable, a0 
	lsl.l #1, d2 					; multiply angle by 2 to get word-offset into table 
	add.l d2, a0 					; a0 pointing at sin((int)AimAngle)
	move.w (a0), d2 				; d2 = 8.8 sin value 
	
	muls d0, d2 					; d2 = AIM_RADIUS * sin(AimAngle) = DeltaX * 256 
	
	move.l #AIM_CENTER_Y, d3 
	add.l d3, d2 					; d3 = ball y pos. (y = AIM_CENTER_Y + DeltaX)
	
	; Update the ball position
	lea Ball, a0 
	move.l d1, M_BALL_X(a0)
	move.l d2, M_BALL_Y(a0)
	jsr Ball_Draw

.return 

	rts 

; ------ SUBROUTINE ------
; _CheckLaunch
;
; Private subroutine that checks if the user 
; has pressed the A button to launch the ball.
; If A is pressed, the ball's x/y velocity is 
; is set and the game state is changed to 
; STATE_RESOLVE. 
; This subroutine should only be called from 
; UpdateAim
; ------------------------	
_CheckLaunch:

	move.w ButtonsDown, d0 
	btst #BUTTON_A, d0 
	bne .return 
	
	; Set the ball's x/y velocity
	; First find the x-component of velocity 
	move.l #(LAUNCH_SPEED), d0 		; d0 = LAUNCH_SPEED in fixed 24.8
	move.l AimAngle, d1 			; load global var AimAngle into d1 
	asr.l #8, d1 					; convert from fixed to int 
	lea CosTable, a0 
	asl.l #1, d1 					; mult by 2 to get word-offset into table 
	add.l d1, a0 					; find the cos value. The angle should already be in range 5-175.
	
	move.w (a0), d1 				; d1 = 8.8 value 
	muls d0, d1						; mult to get the xvel component of LAUNCH_SPEED
	
	asr.l #8, d1 					; result is in 16.16 format. shift right to get into 24.8
	move.l d1, d2					; d2 = xvel component 
	
	; Next find the y component of velocity 
	move.l AimAngle, d1 
	asr.l #8, d1 
	lea SinTable, a0 
	asl.l #1, d1 
	add.l d1, a0 
	
	move.w (a0), d1 
	muls d0, d1 
	
	asr.l #8, d1 					; convert from 16.16 to 24.8 
	move.l d1, d3					; d3 = yvel component
	
	; Update the ball struct's new xvel and yvel 
	lea Ball, a0 
	move.l d2, M_BALL_XVEL(a0)
	move.l d3, M_BALL_YVEL(a0)
	
	; Change the game state 
	move.l #STATE_RESOLVE, GameState
	
.return 
	rts 

; ------ SUBROUTINE ------
; UpdateResolve
;
; Will update the game physics, resolve collisions
; that occur between the ball and pegs. Will change 
; state to STATE_AIM if the ball falls below 
; FALLOUT_Y or if the ball collides with the saver. 
; Will change state to STATE_LOSE if the player
; has no more lives. Will change state to 
; STATE_WIN if all orange pegs are cleared on level
; NUM_LEVELS-1.
; ------------------------	
UpdateResolve:

	lea Ball, a0 
	jsr Ball_Update 
    
    lea Saver, a0  
    jsr Saver_Update 
    
    ; Check if the stage has been cleared. (no red pegs remaining)
    move.l RedPegCount, d0 
    cmpi.l #0, d0 
    bne .check_fallout
    ; increment level and call load level again
    addq.l #1, Level 
    jsr LoadLevel 
    move.l #STATE_AIM, GameState
    jmp .return 
	
.check_fallout
	; Check if the ball has passed the fallout threshold 
	lea Ball, a0 
	move.l M_BALL_Y(a0), d0 
	cmpi.l #FALLOUT_Y, d0 
	blt .return 
	
	; Ball has passed fallout_y, so decrement BallCount 
	; and if ball count is 0, then go to lose state 
	move.l BallCount, d0 
	subq.l #1, d0 
	move.l d0, BallCount
    jsr DrawBallCount
	cmpi.l #0, BallCount 
	bne .set_state_aim
	move.l #STATE_LOSE, GameState
	jsr LoadStart
	jmp .return 
.set_state_aim 
	move.l #STATE_AIM, GameState
	
.return 
	rts
    
; ------ SUBROUTINE ------
; ClearPegs
;
; This will deactive all pegs and set their 
; sprites offscreen. Will also set their 
; sprite index appropriately.
; ------------------------	
ClearPegs:

L_CUR_PEG   SET 0 
L_COUNTER   SET 4 
LVARS_SIZE  SET 8 

    ; add local vars to stack 
    sub.l #LVARS_SIZE, sp 
    lea Pegs, a0        ; a0 = pointer to cur peg 
    clr.l d0            ; d0 = counter 
    move.l a0, L_CUR_PEG(sp)
    move.l d0, L_COUNTER(sp)
    
.loop 
    
    ; Initialize the peg 
    jsr Peg_Init
    
    ; Set the approriate sprite index 
    move.l L_CUR_PEG(sp), a0        ; restore local vars to registers
    move.l L_COUNTER(sp), d0 
    move.l d0, d1 
    addq.l #PEGS_SPRITE_INDEX, d1   ; d1 = sprite index 
    move.b d1, M_PEG_SPRITE_INDEX(a0)

    move.l L_COUNTER(sp), d0 
    addq.l #1, d0 
    move.l d0, L_COUNTER(sp)
    cmpi.l #MAX_PEGS, d0 
    beq .return 
    
    ; move pointer to next peg 
    move.l L_CUR_PEG(sp), a0 
    add.l #PEG_DATA_SIZE, a0 
    move.l a0, L_CUR_PEG(sp)
    jmp .loop 
    
.return 

    ; remove local vars from stack 
    add.l #LVARS_SIZE, sp 
    rts
    
; ------ SUBROUTINE ------
; DrawScore
;
; Uses the current score in the Score 
; global bss variable to draw digits 
; on Plane A in decimal.
; ------------------------	
DrawScore:
L_DIGIT3 SET 0
L_DIGIT2 SET 2
L_DIGIT1 SET 4
LVARS_SIZE SET 6 

    ; allocate local vars
    sub.l #LVARS_SIZE, sp 
    
    ; Get first digit of score 
    move.l Score, d0 
    divu #10, d0 
    move.l d0, d1 
    swap.w d1
    move.w d1, L_DIGIT1(sp)
    andi.l #$0000ffff, d0 

    ; second digit 
    divu #10, d0 
    move.l d0, d1 
    swap.w d1
    move.w d1, L_DIGIT2(sp)    
    andi.l #$0000ffff, d0 
    
    ; third digit 
    divu #10, d0 
    move.l d0, d1 
    swap.w d1
    move.w d1, L_DIGIT3(sp)
    andi.l #$0000ffff, d0 
    
    ; E68 TODO
    ;PRINT_THE_SCORE_HERE 
    
    ; destroy local vars
    add.l #LVARS_SIZE, sp 

    rts 
    
; ------ SUBROUTINE ------
; DrawBallCount
;
; Draws the ball count number on the 
; screen (MAX BALLS = 9) by placing the 
; proper glyphs into plane a's name table.
; ------------------------	
DrawBallCount:
    
    ; Assume that MAX_BALL_COUNT is being 
    ; used elsewhere to properly clamp the maximum balls
    ; the player can have 
    
    ; E68 TODO
    ;PRINT_THE_TEXT_HERE
    
    rts
    
    
DrawBackground:

    move.l #0, d0             ; param d0: chunk x coordinate
    move.l #0, d1             ; param d1: chunk y coordinate 
    move.l #320, d2            ; param d2: chunk width 
    move.l #224, d3            ; param d3: chunk height 
    move.l #0, d4             ; param d4: screen x coordinate
    move.l #0, d5             ; param d5: screen y coordinate 
    lea BGBitmap, a0       ; param a0: pointer to bitmap file data
    jsr RenderBitmap16 
    rts 
    
    rts 