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

; ------ SUBROUTINE ------
; UpdateButtons
;
; Grabs the state of buttons from the controller.
; This subroutine places the updated values in the ButtonsDown
; word in BSS memory. Status of an individual button can be
; checked by using btst.w #BUTTON_X, ButtonsDown
; If the bit is set, then that button is down.
; If cleared, then that button is up.
; ------------------------
UpdateButtons:

    ; Save previous button states so you can 
    ; easily tell if a button was just pressed this frame.
    move.w ButtonsDown, PrevDown 
    
	clr.l d0 
	move.l #KEY_LIST, d1 
    move.l #KEYBOARD_INPUT_TRAP_CODE, d0 
    trap #15 
    
    move.l #$ffffffff, d2
    
    btst.l #24, d1
    beq .check_right 
    bclr.l #BUTTON_LEFT, d2 
    
.check_right 
    btst.l #16, d1 
    beq .check_z
    bclr.l #BUTTON_RIGHT, d2 
    
.check_z
    btst.l #8, d1 
    beq .check_start 
    bclr.l #BUTTON_A, d2 
    
.check_start 
    btst.l #0, d1 
    beq .save_keys 
    bclr.l #BUTTON_START, d2 
    
.save_keys 

    move.w d2, ButtonsDown
    
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