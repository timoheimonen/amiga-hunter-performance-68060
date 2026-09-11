; Loader arena: $C98 image, $1000 resident gap, $1000 OFS workspace,
; then packed input at +$2C98. The largest original file is $1030C bytes.
; Raw disk DMA still uses the game's Chip pointer at $8346, not this arena.
Loader_ArenaBytes equ $14000

; Exec is still alive, interrupts enabled, A6 = ExecBase. Allocations last
; until reset because Hunter takes over the machine and never returns to DOS.
Bootstrap_AllocLoader:
        lea Bootstrap_LoaderBase(PC),A0
        clr.l (A0)
        move.l #Loader_ArenaBytes,D0
        move.l #$50005,D1              ; MEMF_PUBLIC|FAST|CLEAR|REVERSE
        jsr -198(A6)                   ; AllocMem
        tst.l D0
        beq.b .chip
        cmpi.l #$200000,D0
        blo.b .reject_fast
        move.l D0,D1
        addi.l #Loader_ArenaBytes,D1
        bcs.b .reject_fast
        tst.l D1                      ; loader uses signed address comparisons
        bmi.b .reject_fast
        cmpi.l #$C00000,D0
        bhs.b .above_preload
        cmpi.l #$C00000,D1
        bhi.b .reject_fast
        bra.b .accept
.above_preload:
        cmpi.l #$C80000,D0             ; exclude the legacy resource preload
        bhs.b .accept
.reject_fast:
        bsr.b .free
.chip:
        move.l #Loader_ArenaBytes,D0
        move.l #$50003,D1              ; MEMF_PUBLIC|CHIP|CLEAR|REVERSE
        jsr -198(A6)
        tst.l D0
        beq.b .done
        cmpi.l #$80000,D0              ; below here the game overwrites memory
        blo.b .free
        move.l D0,D1
        addi.l #Loader_ArenaBytes,D1
        bcs.b .free
        cmpi.l #$200000,D1             ; upper bound of A1200 Chip RAM
        bhi.b .free
.accept:
        lea Bootstrap_LoaderBase(PC),A0
        move.l D0,(A0)
.done:
        rts
.free:
        movea.l D0,A1
        move.l #Loader_ArenaBytes,D0
        jmp -210(A6)                   ; FreeMem; failed/rejected base stays zero

Bootstrap_LoaderBase:
        dc.l 0

; Enter after the original LEA loader_destination_ptr(PC),A5. Both paths
; restore INTENA through the existing bootstrap sequence; no RAM probes run.
Bootstrap_SelectLoader:
        move.l Bootstrap_LoaderBase(PC),D0
        beq.w $CE                     ; original DOS error path, before intros
        movea.l D0,A0
        move.w #$C000,$DFF09A.l
        move.l A0,(A5)
        bra.w $100                    ; resume the original overlay stream load
