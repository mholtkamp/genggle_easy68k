; ++++++ STRUCT ++++++
; Ball 
;
; size  = 32 bytes 
; 
; 0(Ball)  = x position (24.8)
; 4(Ball)  = y position (24.8)
; 8(Ball)  = width (24.8)
; 12(Ball) = height (24.8)
; 16(Ball) = x velocity (24.8)
; 20(Ball) = y velocity (24.8)
; ++++++++++++++++++++
M_BALL_RECT   EQU 0 
M_BALL_X      EQU 0 
M_BALL_Y      EQU 4 
M_BALL_WIDTH  EQU 8 
M_BALL_HEIGHT EQU 12 
M_BALL_XVEL   EQU 16 
M_BALL_YVEL   EQU 20 

; ------ SUBROUTINE ------
; Ball_Init
;
; Initializes a ball struct with standard 
; starting values
; 
; Input:
;   a0.l = pointer to ball struct 
; ------------------------	
Ball_Init:
	move.l #0, M_BALL_X(a0)
	move.l #0, M_BALL_Y(a0)
	move.l #BALL_WIDTH, M_BALL_WIDTH(a0)
	move.l #BALL_HEIGHT, M_BALL_HEIGHT(a0)
	move.l #0, M_BALL_XVEL(a0)
	move.l #0, M_BALL_YVEL(a0)
	rts 

; ------ SUBROUTINE ------
; Ball_Update
;
; Applies gravity to the ball. Updates the position
; of the ball. And handles conflicts with any pegs.
; 
; Input:
;   a0.l = pointer to ball struct 
; ------------------------	
Ball_Update:

    move.l a0, -(sp)
    jsr Ball_Hide
    move.l (sp)+, a0

	; Apply gravity 
	move.l M_BALL_YVEL(a0), d0 
	move.l #GRAVITY, d1 
	add.l d1, d0 
	move.l d0, M_BALL_YVEL(a0)
	
	; Update the position of ball
	move.l M_BALL_XVEL(a0), d0 
	move.l M_BALL_X(a0), d1 
	add.l d0, d1 
	move.l d1, M_BALL_X(a0)
	
	move.l M_BALL_YVEL(a0), d0 
	move.l M_BALL_Y(a0), d1 
	add.l d0, d1 
	move.l d1, M_BALL_Y(a0)
	
	; Check if ball goes past left or right bounds 
	move.l M_BALL_X(a0), d0 
	cmpi.l #LEFT_BOUND, d0 
	blt .bounce_left
	cmpi.l #RIGHT_BOUND, d0 
	bgt .bounce_right
	jmp .check_collisions 
	
.bounce_left
	move.l #LEFT_BOUND, M_BALL_X(a0)
	jmp .reverse_xvel
	
.bounce_right 
	move.l #RIGHT_BOUND, M_BALL_X(a0)
	; jmp .reverse_xvel

.reverse_xvel
	move.l M_BALL_XVEL(a0), d0 
	neg.l d0 
	move.l d0, M_BALL_XVEL(a0)
    
.check_collisions
    ; Lastly, check for any peg collisions 
    move.l a0, -(sp)            ; save a0
    jsr _Ball_CheckPegCollisions
    move.l (sp)+, a0              ; restore a0 
    
.update_sprite
	; Update sprite 
    ; don't worry about a0 getting trashed
    ; as this will be the last step of Update
	jsr Ball_Draw
	
	rts 

; ------ SUBROUTINE ------
; Ball_Draw
;
; Draws the ball at location x/y.
; 
; Input:
;   a0.l = pointer to ball struct 
; ------------------------	
Ball_Draw:
    move.l #0, d0             ; param d0: chunk x coordinate
    move.l #0, d1             ; param d1: chunk y coordinate 
    move.l #8, d2            ; param d2: chunk width 
    move.l #8, d3            ; param d3: chunk height 
    move.l M_BALL_X(a0), d4  ; param d4: screen x coordinate
    asr.l #8, d4              ; convert from fixed to int 
    move.l M_BALL_Y(a0), d5  ; param d5: screen y coordinate 
    asr.l #8, d5              ; convert from fixed to int 
    lea BallBitmap, a0       ; param a0: pointer to bitmap file data
    jsr RenderBitmap16 
	rts 
    
Ball_Hide:
    move.l M_BALL_X(a0), d0  ; param d0: chunk x coordinate
    asr.l #8, d0              ; convert from fixed to int 
    move.l M_BALL_Y(a0), d1  ; param d1: chunk y coordinate
    asr.l #8, d1              ; convert from fixed to int     
    move.l #8, d2            ; param d2: chunk width 
    move.l #8, d3            ; param d3: chunk height 
    move.l M_BALL_X(a0), d4  ; param d4: screen x coordinate
    asr.l #8, d4              ; convert from fixed to int 
    move.l M_BALL_Y(a0), d5  ; param d5: screen y coordinate 
    asr.l #8, d5              ; convert from fixed to int 
    lea BGBitmap, a0          ; param a0: pointer to bitmap file data
    jsr RenderBitmap16 
    rts 

; ------ SUBROUTINE ------
; _Ball_CheckPegCollisions
;
; Private subroutine that iterates through 
; the peg list and checks if the ball is
; overlapping any pegs. Handles collision 
; when ball is overlapping a peg.
;
; Input:
;   a0.l = pointer to ball struct 
; ------------------------		
_Ball_CheckPegCollisions:
    
REGS REG a0/a1/d0 

    lea Pegs, a1            ; get the peg array 
    clr.l d0                ; d0 = loop counter 
    
.loop
    
    move.b M_PEG_ACTIVE(a1), d1 
    tst.b d1
    beq .continue           ; continue if peg is inactive 
    
    ; Otherwise, peg is active. So check if the ball 
    ; is hitting it. 
    ; save regs 
    movem.l REGS, -(sp) 
    jsr Rect_OverlapsRect
    move.l d0, d1           ; save result in d1 
    ; restore regs 
    movem.l (sp)+, REGS
    
    tst.l d1 
    beq .continue 
    
    ; So after a bunch of testing and experimenting, I've decided to 
    ; use a very basic collision model where the ball bounces in the 
    ; exact same direct as the vector between the ball's position 
    ; and the peg's position. 
    
    ; Calculate the displacement vector (dispVec)
    ; The dispVec is the vector difference of the 
    ; positions of the ball and peg. The dispVec is 
    ; important because it shows what direction the ball 
    ; is from the peg.
    move.l M_BALL_X(a0), d1 
    move.l M_BALL_Y(a0), d2
    move.l M_PEG_X(a1), d3 
    move.l M_PEG_Y(a1), d4 
    
    ; subtract peg pos from ball pos 
    sub.l d3, d1
    sub.l d4, d2                ; <d1, d2> is the displacement vector now
    
    move.l M_BALL_XVEL(a0), d3 
    move.l M_BALL_YVEL(a0), d4  ; <d3, d4> is the velocity vector 
    
    ; Get the magnitude of the velocity 
    move.l d3, d5 
    muls d5, d3     ; square the xvel
    asr.l #8, d3    ; return to 24.8 format 
    move.l d4, d5 
    muls d5, d4     ; square the yvel 
    asr.l #8, d4    ; return to 24.8 format 
    add.l d4, d3    ; add the squares of the x/y components 
    
    ; clamp the magnitude so it stays within sqrt table 
    asr.l #8, d3             ; convert to int 
    cmpi.l #MAX_SQRT_INPUT,d3 
    blo .no_vel_clamp
    move.l #MAX_SQRT_INPUT, d3 
.no_vel_clamp
    asl.l #1, d3 
    lea SqrtTable, a3 
    add.l d3, a3 
    clr.l d3 
    move.w (a3), d3   ; d3 = magnitude of velocity 
    
    ; Dampen the velocity a tiny bit for some realistic collision 
    move.l #DAMPENING_COEFFICIENT, d4 
    muls d4, d3       
    asr.l #8, d3        ; d3 = the new speed of the ball
    
    ; Normalize the displacement vector for performing projection 
    ; first step is to get magnitude squared 
    move.l d1, d5 
    muls d1, d5
    asr.l #8, d5 
    move.l d2, d6
    muls d2, d6 
    asr.l #8, d6
    add.l d6, d5        ; d5 = magnitude squared 
    
    ; Next step to normalizing is to find the magnitude (sqrt of magnitude squared)
    asr.l #8, d5        ; convert mag squared from 24.8 to int 
    cmpi.l #MAX_SQRT_INPUT, d5 
    blo .skip_mag_clamp
    move.l #MAX_SQRT_INPUT, d5  ; clamp if outside of table index range 
.skip_mag_clamp
    lsl.l #1, d5                ; get the index into the sqrt table in bytes 
    lea SqrtTable, a3 
    add.l d5, a3 
    clr.l d5                    ; clear the long because we are about to store a positive word in this reg 
    move.w (a3), d5             ; d5 = magnitude 
    
    ; Last step of normalizing is to divide dispVec by the magnitude 
    asl.l #8, d1        ; the divors can be in 16.16 format 
    asl.l #8, d2 
    divs d5, d1 
    divs d5, d2 
    ext.l d1            ; now d1 should be in 24.8
    ext.l d2            ; and d2 should be in 24.8
    
    ; <d1, d2> = the normalized displacement vector 
    ; Now (for basic collision) we can just multiply the dampened velocity 
    ; with the normalized displacement vector and then set that as the new 
    ; xvel/yvel of the ball. 
    muls d3, d1
    asr.l #8, d1 
    muls d3, d2
    asr.l #8, d2 
    
    move.l d1, M_BALL_XVEL(a0)
    move.l d2, M_BALL_YVEL(a0)
    
    ; Consume the peg! omnom (deactivate it and add to score)
    movem.l REGS, -(sp) 
    move.l a1, a0         ; put peg into a0 for param 
    jsr Peg_Consume 
    movem.l (sp)+, REGS 
    
.continue
    adda.l #PEG_DATA_SIZE, a1 
    addq.l #1, d0 
    cmp.l LevelPegCount, d0 
    bne .loop 
    
    rts 
