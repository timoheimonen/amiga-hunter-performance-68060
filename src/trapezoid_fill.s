; Specialize the two observed trapezoid operations once per edge record.
; The original entry and clipping remain unchanged. Unknown selectors retain
; the original scanline loop. No extra live stack frame or SMC is introduced.
Resident_TrapezoidFill:
        movem.w $7C8E.l,A0-A3
        adda.l D0,A0
        adda.l D0,A1
        adda.l D0,A2
        adda.l D0,A3
        move.w $7C9A.l,D6
        cmpi.w #$7EC8,D6
        beq.b .set2
        cmpi.w #$7EF8,D6
        beq.b .set3
        clr.w D6
        jmp $7C10.l
.set2:
        clr.w D6
        bra.w Trap_scanline_2
.set3:
        clr.w D6
        bra.w Trap_scanline_3

trapezoid_loop macro
Trap_scanline_\1:
	move.l	D7,D4			; retain x(y) as one trapezoid endpoint
	add.l	A4,D7			; advance to x(y+1), the other endpoint
	addq.w	#1,($15F2,A5)		; advance the signed source scanline
	ble.b	Trap_scanline_\1 ; top-clipped edges step until x(0)/x(1) is ready for row zero
	adda.w	D6,A0			; advance plane 0 from the preceding filled span
	adda.w	D6,A1			; advance plane 1 from the preceding filled span
	adda.w	D6,A2			; advance plane 2 from the preceding filled span
	adda.w	D6,A3			; advance plane 3 from the preceding filled span
	moveq	#$28,D6		; default to one complete row after a clipped span
	move.l	D7,D5			; copy x(y+1) before integer conversion
	asr.l	#5,D4			; floor x(y)/32; later tests use signed low words
	asr.l	#5,D5			; convert x(y+1) to an integer pixel
	cmp.w	D4,D5			; order the endpoints from left to right
	bge.b	Trap_order_ready_\1
	exg	D4,D5

Trap_order_ready_\1:
	tst.w	D5			; an entirely left-clipped span draws nothing
	bmi.b	Trap_next_scanline_\1
	cmp.w	#$13F,D4		; an entirely right-clipped span draws nothing
	bgt.b	Trap_next_scanline_\1
	tst.w	D4
	bpl.b	Trap_left_ready_\1
	clr.w	D4			; clamp the left endpoint to pixel zero

Trap_left_ready_\1:
	cmp.w	#$140,D5
	blt.b	Trap_right_ready_\1
	move.w	#$13F,D5		; clamp the right endpoint to pixel 319

Trap_right_ready_\1:
	move.w	D4,D2			; retain the left endpoint's bit position
	move.w	D5,D3			; retain the right endpoint's bit position
	moveq	#$1F,D0		; isolate positions within 32-bit bitmap words
	and.w	D0,D2
	and.w	D0,D3
	addq.w	#1,D3			; make the right-end mask inclusive
	moveq	#-1,D0			; seed the left-side suffix mask
	moveq	#-1,D1			; seed the right-side prefix mask
	dc.w	$E4A8			; LSR.L D2,D0; vasm misencodes register-count shifts
	dc.w	$E6A9			; LSR.L D3,D1; vasm misencodes register-count shifts
	move.l	D0,D2			; preserve the left suffix before complementing it
	move.l	D1,D3			; preserve the right suffix before complementing it
	not.l	D2			; form the complementary left prefix mask
	not.l	D1			; form the inclusive right endpoint mask
	lsr.w	#5,D4			; convert the left pixel to its longword index
	lsr.w	#5,D5			; convert the right pixel to its longword index
	move.w	D5,D6			; derive the next-row carry from the right longword
	lsl.w	#2,D6			; convert its index to a byte offset
	neg.w	D6
	addi.w	#$28,D6		; next row begins 40 bytes after the bitmap row base
	sub.w	D4,D5			; pass last-longword minus first-longword to the fill operation
	lsl.w	#2,D4			; convert the left longword index to a byte offset
	adda.w	D4,A0			; position plane 0 at the first affected longword
	adda.w	D4,A1			; position plane 1 at the first affected longword
	adda.w	D4,A2			; position plane 2 at the first affected longword
	adda.w	D4,A3			; position plane 3 at the first affected longword
Trap_Body_\1:
        incbin \2
Trap_next_scanline_\1:
        subq.w #1,(SP)
        bgt.w Trap_scanline_\1
        addq.w #2,SP
        rts
Trap_End_\1:
        endm
        trapezoid_loop 2,"trapezoid_fill_2.bin"
        trapezoid_loop 3,"trapezoid_fill_3.bin"
Trapezoid_FillEnd:
