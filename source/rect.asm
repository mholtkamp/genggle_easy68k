; ++++++ STRUCT ++++++
; Rect  
;
; size  = 16 bytes 
; 
; 0(Rect)  = x position (24.8 long)
; 4(Rect)  = y position (24.8 long)
; 8(Rect)  = width (24.8 long)
; 12(Rect) = height (24.8 long)
; ++++++++++++++++++++
M_RECT_X            EQU 0 
M_RECT_Y            EQU 4 
M_RECT_WIDTH        EQU 8 
M_RECT_HEIGHT       EQU 12 

; ------ SUBROUTINE ------
; Rect_Init
;
; Initializes a rect struct with standard 
; starting values. 
; 
; Input:
;   a0.l = pointer to rect struct 
; ------------------------	
Rect_Init:
    move.l #$0, M_RECT_X(a0)
    move.l #$0, M_RECT_Y(a0)
    move.l #(1*TO_FIXED), M_RECT_WIDTH(a0)
    move.l #(1*TO_FIXED), M_RECT_HEIGHT(a0)
    rts 


; ------ SUBROUTINE ------
; OverlapsRect
;
; Checks if this rect struct overlaps
; another rect struct 
; 
; Input:
;   a0.l = pointer to this rect 
;   a1.l = pointer to other rect 
;
; Output:
;   d0.l = 1 if rects are overlapping 
;          0 otherwise 
; ------------------------	
Rect_OverlapsRect:

    ; check if this.right < other.left 
    move.l M_RECT_X(a0), d0 
    add.l M_RECT_WIDTH(a0), d0 
    cmp.l M_RECT_X(a1), d0 
    blt .return_false
    
    ; check if this.left > other.right 
    move.l M_RECT_X(a0), d0
    move.l M_RECT_X(a1), d1 
    add.l M_RECT_WIDTH(a1), d1 
    cmp.l d1, d0 
    bgt .return_false
    
    ; check if this.bot < other.top 
    move.l M_RECT_Y(a0), d0 
    add.l M_RECT_HEIGHT(a0), d0 
    cmp.l M_RECT_Y(a1), d0 
    blt .return_false
    
    ; check if this.top > other.bot 
    move.l M_RECT_Y(a0), d0 
    move.l M_RECT_Y(a1), d1 
    add.l M_RECT_HEIGHT(a1), d1 
    cmp.l d1, d0
    bgt .return_false
    
    ; fall-through to .return_true
    
.return_true 
    move.l #1, d0 
    rts 

.return_false 
    move.l #0, d0 
    rts