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
PrevDown:
    ds.l 1 
PrevTime:
    ds.l 1 
CurTime:
    ds.l 1 