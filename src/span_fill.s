; Select a complete generated-span loop once per polygon. Each loop embeds
; one original scanline operation,
; removing all per-row calls and
; the cache-safe return-address dispatch. A5/A6 remain valid for interrupts.
; A sparse table maps even target offsets directly; holes and invalid values
; retain the old fallback instead of searching fourteen pairs per polygon.
Resident_SpanFill:
        move.w $7C9A.l,D6
        subi.w #$7E6C,D6
        cmpi.w #$8078-$7E6C,D6
        bhi.b .fallback
        btst #0,D6
        bne.b .fallback
        lea Span_FillTargets(PC),A4
        move.w (A4,D6.w),D6
        beq.b .fallback
        lea Resident_SpanFill(PC),A4
        adda.w D6,A4
        jmp (A4)
.fallback:
        lea $796E.l,A4
        clr.w D6
        jmp $791E.l
Span_FillTargets:
        include "span_fill_targets.i"


span_loop macro
Span_Loop_\2:
        lea $796E.l,A4
        clr.w D6
Span_Row_\2:
        adda.w D6,A0
        adda.w D6,A1
        adda.w D6,A2
        adda.w D6,A3
        moveq #$28,D6
        movem.w (A4)+,D4-D5
        move.w D5,D3
        bmi.b Span_Next_\2
        move.w D4,D2
        moveq #$1F,D0
        and.w D0,D2
        and.w D0,D3
        addq.w #1,D3
        moveq #-1,D0
        moveq #-1,D1
        dc.w $E4A8,$E6A9              ; exact register-count LSR.L encodings
        move.l D0,D2
        move.l D1,D3
        not.l D2
        not.l D1
        lsr.w #5,D4
        lsr.w #5,D5
        move.w D5,D6
        lsl.w #2,D6
        neg.w D6
        addi.w #$28,D6
        sub.w D4,D5
        lsl.w #2,D4
        adda.w D4,A0
        adda.w D4,A1
        adda.w D4,A2
        adda.w D4,A3
Span_Body_\2:
        incbin \1                     ; original operation, minus its final RTS
Span_Next_\2:
        dbf D7,Span_Row_\2
        rts
Span_End_\2:
        endm
        include "span_fill_loops.i"
Span_FillEnd:
