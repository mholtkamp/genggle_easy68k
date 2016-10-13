; ++++++ STRUCT ++++++
; Peg  
;
; size  = 32 bytes 
; 
; 0(Peg)  = x position (24.8 long)
; 4(Peg)  = y position (24.8 long)
; 8(Peg)  = width (24.8 long)
; 12(Peg) = height (24.8 long)
; 16(Peg) = type (byte)
; 17(Peg) = active (byte)
; 18(Peg) = moving (byte)
; 19(Peg) = sprite index (byte)
; 20(Peg) = left bound (word)
; 22(Peg) = right bound (word)
; ++++++++++++++++++++
M_PEG_RECT         EQU 0 
M_PEG_X            EQU 0 
M_PEG_Y            EQU 4 
M_PEG_WIDTH        EQU 8 
M_PEG_HEIGHT       EQU 12 
M_PEG_TYPE         EQU 16 
M_PEG_ACTIVE       EQU 17
M_PEG_MOVING	   EQU 18 
M_PEG_SPRITE_INDEX EQU 19
M_PEG_LEFT_BOUND   EQU 20 
M_PEG_RIGHT_BOUND  EQU 22 


; ------ SUBROUTINE ------
; Peg_Init
;
; Initializes a peg struct with standard 
; starting values. Defaults active to 0 
; 
; Input:
;   a0.l = pointer to peg struct 
; ------------------------	
Peg_Init:

    move.l #PEG_INIT_X, M_PEG_X(a0) 
    move.l #PEG_INIT_Y, M_PEG_Y(a0)
    move.l #PEG_WIDTH, M_PEG_WIDTH(a0)
    move.l #PEG_HEIGHT, M_PEG_HEIGHT(a0)
    
    move.b #PEG_TYPE_BLUE, M_PEG_TYPE(a0)
    move.b #0, M_PEG_ACTIVE(a0)
    move.b #0, M_PEG_MOVING(a0)
    move.b #PEGS_SPRITE_INDEX, M_PEG_SPRITE_INDEX(a0)
    
    move.w #0, M_PEG_LEFT_BOUND(a0)
    move.w #0, M_PEG_RIGHT_BOUND(a0)
    
    rts 

; ------ SUBROUTINE ------
; Peg_Draw
;
; Draws the peg.
; 
; Input:
;   a0.l = pointer to peg struct 
; ------------------------	    
Peg_Draw:

    ; Example usage of RenderBitmap16
    move.l #0, d0             ; param d0: chunk x coordinate
    move.l #0, d1             ; param d1: chunk y coordinate 
    move.l #8, d2            ; param d2: chunk width 
    move.l #8, d3            ; param d3: chunk height 
    move.l M_PEG_X(a0), d4  ; param d4: screen x coordinate
    asr.l #8, d4 
    move.l M_PEG_Y(a0), d5  ; param d5: screen y coordinate 
    asr.l #8, d5
    move.b M_PEG_TYPE(a0), d7
    cmpi.b #PEG_TYPE_RED, d7 
    bne .blue_peg
    lea RedPegBitmap, a0 
    jmp .render
.blue_peg
    lea BluePegBitmap, a0       ; param a0: pointer to bitmap file data
.render
    jsr RenderBitmap16 
    
    rts 

; ------ SUBROUTINE ------
; Peg_Hide
;
; Hides the peg by drawing the 
; background over the the peg 
; 
; Input:
;   a0.l = pointer to peg struct 
; ------------------------	       
Peg_Hide:

    ; Example usage of RenderBitmap16
    move.l M_PEG_X(a0), d0  ; param d0: chunk x coordinate
    asr.l #8, d0 
    move.l M_PEG_Y(a0), d1  ; param d1: chunk y coordinate 
    asr.l #8, d1 
    move.l #8, d2            ; param d2: chunk width 
    move.l #8, d3            ; param d3: chunk height 
    move.l M_PEG_X(a0), d4  ; param d4: screen x coordinate
    asr.l #8, d4 
    move.l M_PEG_Y(a0), d5  ; param d5: screen y coordinate 
    asr.l #8, d5 
    lea BGBitmap, a0          ; param a0: pointer to bitmap file data
    jsr RenderBitmap16 
    rts 

; ------ SUBROUTINE ------
; Peg_Consume
;
; Deactivates the peg and adds to the score
; based on RedPegCount
; 
; Input:
;   a0.l = pointer to peg struct 
; ------------------------	
Peg_Consume:

    ; Now mark the peg as inactive and hide the sprite 
    move.b #0, M_PEG_ACTIVE(a0)
    
    ; Draw background over where this peg was 
    move.l a0, -(sp)
    jsr Peg_Hide 
    move.l (sp)+, a0 
    
    ; Check if peg was a red peg, if so, dec the 
    ; global red peg count 
    move.b M_PEG_TYPE(a0), d1
    cmpi.b #PEG_TYPE_RED, d1 
    bne .blue_peg  
    move.l RedPegCount, d1 
    subq.l #1, d1 
    move.l d1, RedPegCount      ; reduce the number of red pegs 
    
    ; Add red peg score 
    add.l #RED_PEG_SCORE, Score 
    jmp .return 
    
.blue_peg 
    move.l RedPegCount, d0
    cmpi.l #LOW_RED, d0 
    bgt .not_low 
    
    ; Only 1 or 2 red pegs left. Add 4 points 
    addi.l #BLUE_PEG_LOW_SCORE, Score 
    jmp .return 
    
.not_low 
    cmpi.l #MID_RED, d0 
    bgt .not_mid 
    addi.l #BLUE_PEG_MID_SCORE, Score 
    jmp .return 
    
.not_mid 
    ; Okay, so there are still a lot of red pegs on the 
    ; board. Only reward 1 point.
    addi.l #BLUE_PEG_HIGH_SCORE, Score 
    
.return 
    
    jsr DrawScore 
    rts 
