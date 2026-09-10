; Seven-column, nine-row view. Copied into the extra Fast arena.
; Internal addresses are PC-relative; game calls use original absolute entries.
; A5/A6 remain game/custom bases. The original source arithmetic is retained.
View9_Start:
View9_DrawWindow:
	bsr.w	View9_ProjectGrid	; project the 8x10 terrain-vertex grid
	jsr	$AC3A.l
	movea.l	($1550,A5),A4		; far-corner terrain record
	dc.w	$98FC,$0100		; suba.w #$100,A4 (preserve immediate encoding)
	subq.w	#1,A4			; select its descriptor byte
	lea	View9_Grid(PC),A3
	lea	View9_Mask(PC),A2
	lea	View9_Queues(PC),A1	; deferred shape parts, one 64-byte list per row
	move.w	#8,($C0,A5)		; nine terrain rows
.draw_row:
	move.l	A1,-(SP)
	moveq	#6,D6			; seven terrain cells per row
.draw_cell:
	tst.b	(A2)+
	beq.b	.next_cell
	move.b	(A4),D4		; color in bits 0-3, polygon class in bits 4-6
	beq.b	.next_cell
	move.l	(4,A3),D0		; top left (the grid runs toward decreasing terrain x)
	move.l	(A3),D1			; top right
	move.l	($20,A3),D2		; bottom right
	move.l	($24,A3),D3		; bottom left
	lea	$3912.l,A1
	movem.l	D0-D3,(A1)
	sub.w	D0,D3			; projected left-edge screen-y delta
	sub.w	D1,D2			; projected right-edge screen-y delta
	move.w	D3,D0
	and.w	D2,D0
	bmi.b	.next_cell		; reject when both side edges run toward decreasing screen y
	cmp.b	#$20,D4
	bge.b	.draw_selected
	eor.w	D2,D3
	bpl.b	.draw_selected		; matching side-edge y directions keep the descriptor class
	andi.b	#$0F,D4			; opposite y directions: split along edge 4 into classes 2 and 4
	movem.l	D4/A1,-(SP)
	ori.b	#$20,D4
	jsr	$3A46.l
	movem.l	(SP)+,D4/A1
	ori.b	#$40,D4
.draw_selected:
	jsr	$3A46.l
.next_cell:
	subq.w	#2,A4			; previous terrain record in the row
	addq.w	#4,A3			; next projected grid vertex
	dbf	D6,.draw_cell
	movea.l	(SP)+,A1
	move.w	(A1),D7			; draw deferred scene parts for this depth row
	ble.b	.no_shape_parts
	jsr	$4E82.l
.no_shape_parts:
	dc.w	$D2FC,$0040		; adda.w #$40,A1 (preserve immediate encoding)
	dc.w	$98FC,$00F2		; suba.w #$F2,A4: seven records, then previous row
	addq.w	#4,A3			; skip the eighth vertex at the row edge
	subq.w	#1,($C0,A5)
	bpl.b	.draw_row
	rts

View9_ProjectGrid:
	bsr.w	View9_PrepareTerrain
	lea	View9_Grid(PC),A1
	lea	View9_Heights+174(PC),A4		; terrain record at the far/right window corner
	move.w	#$2100,D5		; fixed far clipping depth
	move.w	($1538,A5),D6
	ext.l	D6
	lsl.l	#8,D6			; fixed-point horizontal camera offset
	move.w	($153A,A5),D4
	not.w	D4
	andi.l	#$3FE,D4		; far-edge z interpolation fraction
	move.l	#$400,D3		; one doubled terrain-cell step
	moveq	#7,D7			; eight points, decreasing terrain x
.far_point:
	move.l	D3,D0
	move.l	D4,D1
	move.b	(A4),D2
	sub.b	(-$10,A4),D2		; height delta across the far z edge
	ifne TERRAIN_DELTA
	jsr	$7D3A.l
	else
	ext.w	D2
	beq.b	.far_height_ready
	divs.w	D2,D0
	endif
.far_height_ready:
	divs.w	D0,D1			; scale the height delta by the z fraction
	add.b	(-$10,A4),D1
	ext.w	D1
	lsl.w	#4,D1			; height bytes are 16 world units
	neg.w	D1
	add.w	($E,A5),D1		; camera-relative vertical coordinate
	ext.l	D1
	lsl.l	#8,D1
	move.l	D6,D0
	move.w	D5,D2
	beq.b	.far_projected
	ifne TERRAIN_PROJECT
	jsr	$7D40.l
	else
	divs.w	D2,D0
	divs.w	D2,D1
	endif
.far_projected:
	addi.w	#46,D1			; terrain viewport center (160,46)
	addi.w	#160,D0
	move.w	D0,(A1)+
	move.w	D1,(A1)+
	subq.w	#2,A4
	subi.l	#$40000,D6		; next x vertex in 8.8 fixed point
	dbf	D7,.far_point

	move.w	#7,D7			; eight complete interior terrain rows
	move.w	($153A,A5),D5
	addi.w	#$FD00,D5		; first integer row depth: translation - $300
	dc.w	$263C
	dc.l	$00040000		; move.l #$40000,D3 (vasm selects MOVEQ+SWAP)
.interior_row:
	; The packed height rows already meet after eight two-byte steps.
	move.w	($1538,A5),D4
	ext.l	D4
	lsl.l	#8,D4
	moveq	#7,D6
.interior_point:
	clr.w	D1
	move.b	(A4),D1
	lsl.w	#4,D1
	neg.w	D1
	add.w	($E,A5),D1
	ext.l	D1
	lsl.l	#8,D1
	move.l	D4,D0
	move.w	D5,D2
	beq.b	.interior_projected
	ifne TERRAIN_PROJECT
	jsr	$7D40.l
	else
	divs.w	D2,D0
	divs.w	D2,D1
	endif
.interior_projected:
	addi.w	#46,D1
	addi.w	#160,D0
	move.w	D0,(A1)+
	move.w	D1,(A1)+
	subq.w	#2,A4
	sub.l	D3,D4
	dbf	D6,.interior_point
	subi.w	#$400,D5		; next row is one doubled terrain cell nearer
	dbf	D7,.interior_row

	; A4 already points at the near row in the packed height window.
	move.l	#$400,D4
	ext.l	D5
	subi.w	#$FD00,D5		; recover the near-edge fraction from the row depth
	bge.b	.near_fraction_ready
	add.l	D5,D4			; a negative fraction shortens the nominal $400 interpolation span
.near_fraction_ready:
	move.l	D4,D5
	addi.w	#$FD00,D5		; projection depth is fraction - $300 (normally $100)
	move.w	($1538,A5),D6
	ext.l	D6
	lsl.l	#8,D6
	move.l	#$400,D3
	lsl.l	#8,D4			; near-edge z interpolation fraction in 8.8 form
	moveq	#7,D7
.near_point:
	move.l	D4,D1
	move.b	(A4),D2
	sub.b	(-$10,A4),D2
	ext.w	D2
	beq.b	.near_height_ready	; zero delta retains D4 fraction, unlike the far edge
	ifne TERRAIN_DELTA
	jsr	$7D3A.l
	else
	move.l	D3,D0
	divs.w	D2,D0
	endif
	divs.w	D0,D1
.near_height_ready:
	asr.l	#8,D1
	add.b	(-$10,A4),D1
	ext.w	D1
	lsl.w	#4,D1
	neg.w	D1
	add.w	($E,A5),D1
	ext.l	D1
	lsl.l	#8,D1
	move.l	D6,D0
	tst.w	D5
	beq.b	.near_projected
	divs.w	D5,D0
	divs.w	D5,D1
.near_projected:
	addi.w	#46,D1
	addi.w	#160,D0
	move.w	D0,(A1)+
	move.w	D1,(A1)+
	subq.w	#2,A4
	subi.l	#$40000,D6
	dbf	D7,.near_point
	rts


; Snapshot eleven height rows: far boundary, eight interior rows, near boundary
; and its interpolation neighbour. Clamp vertex coordinates before any map read.
; Descriptor masks retain cells x=0..127,z=0..126; no outside descriptor is read.
View9_PrepareTerrain:
        movem.l D0-D7/A0-A2,-(SP)
        movea.l $8386.l,A0
        lea View9_Heights+174(PC),A1
        movem.w ($153C,A5),D4-D5
        moveq #10,D7
.height_row:
        move.w D5,D1
        bpl.b .z_nonnegative
        clr.w D1
.z_nonnegative:
        cmpi.w #127,D1
        ble.b .z_ready
        moveq #127,D1
.z_ready:
        lsl.w #8,D1
        move.w D4,D2
        moveq #7,D6
.height_point:
        move.w D2,D0
        bpl.b .x_nonnegative
        clr.w D0
.x_nonnegative:
        cmpi.w #127,D0
        ble.b .x_ready
        moveq #127,D0
.x_ready:
        add.w D0,D0
        add.w D1,D0
        andi.l #$FFFF,D0
        move.b (A0,D0.l),D3
        move.b D3,(A1)
        subq.l #2,A1
        subq.w #1,D2
        dbf D6,.height_point
        subq.w #1,D5
        dbf D7,.height_row
        lea View9_Mask(PC),A0
        lea View9_Template(PC),A1
        movem.w ($153C,A5),D4-D5
        moveq #8,D7
.mask_row:
        subq.w #1,D5
        move.w D4,D2
        moveq #6,D6
.mask_cell:
        subq.w #1,D2
        move.b (A1)+,D0
        cmpi.w #127,D2
        bhi.b .masked
        cmpi.w #126,D5
        bls.b .store
.masked:
        clr.b D0
.store:
        move.b D0,(A0)+
        dbf D6,.mask_cell
        dbf D7,.mask_row
        movem.l (SP)+,D0-D7/A0-A2
        rts

; Replace $4230..$4257. At most 30 active slots are scanned by the game.
; Each row holds 31 offsets and has an explicit bounds check before writing.
View9_QueueObject:
        add.w ($154C,A5),D2
        ext.l D2
        lsr.l #8,D2
        lsr.l #2,D2
        neg.w D2
        addq.w #8,D2
        cmpi.w #8,D2
        bhi.b .outside
        lsl.w #6,D2
        lea View9_Queues(PC),A0
        adda.w D2,A0
        move.w (A0),D0
        cmpi.w #31,D0
        bhs.b .overflow
        addq.w #1,D0
        move.w D0,(A0)
        move.l A0,-(SP)
        lea View9_QueuePeak(PC),A0
        cmp.w (A0),D0
        bls.b .peak_ready
        move.w D0,(A0)
.peak_ready:
        movea.l (SP)+,A0
        add.w D0,D0
        move.w (A3),(A0,D0.w)
        jmp $4258.l
.overflow:
        lea View9_QueueOverflow(PC),A0
        addq.l #1,(A0)
.outside:
        sf ($1C,A4)
        jmp $4224.l

; Restricted/focused views consume the same queues without drawing terrain.
View9_ShapeParts:
        lea View9_Queues(PC),A1
        move.w #8,($C0,A5)
.row:
        move.w (A1),D7
        beq.b .next
        jsr $4E82.l
.next:
        adda.w #64,A1
        subq.w #1,($C0,A5)
        bpl.b .row
        rts

        even
View9_QueuePeak: dc.w 0
View9_QueueOverflow: dc.l 0
View9_GuardBefore: dc.l $39564945
View9_Grid: ds.b 320
View9_GridEnd: dc.l $39475244
View9_Mask: ds.b 63
View9_Template:
        dcb.b 42,1                    ; six full far rows
        dc.b 0,1,1,1,1,1,0
        dc.b 0,1,1,1,1,1,0
        dc.b 0,0,1,1,1,0,0
        even
View9_MaskEnd: dc.l $394D4153
View9_Heights: ds.b 176
View9_HeightsEnd: dc.l $39484549
View9_Queues: ds.b 9*64
View9_QueuesEnd: dc.l $39515545
View9_End:
