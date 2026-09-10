; Exact replacement for DIVS.W #256,D1 followed by ASR.W #4,D1.
; Preserve the packed signed remainder, every other register and final CCR.
; Quotient overflow retains the original instruction behavior.
Resident_TerrainDiv:
        cmpi.l #-8388863,D1            ; smallest dividend with quotient -32768
        blt.b .overflow
        cmpi.l #8388607,D1             ; largest dividend with quotient 32767
        bgt.b .overflow
        move.l D7,-(SP)
        move.l D1,D7
        tst.l D1
        bpl.b .positive
        addi.l #255,D1                 ; DIVS truncates toward zero
.positive:
        asr.l #8,D1
        lsl.l #8,D1
        sub.l D1,D7                    ; signed remainder, -255..255
        asr.l #8,D1
        swap D7
        move.w D1,D7
        move.l D7,D1
        move.l (SP)+,D7
        asr.w #4,D1                    ; original final NZVC and X
        rts
.overflow:
        divs.w #256,D1
        asr.w #4,D1
        rts
