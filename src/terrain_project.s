; Exact single-entry memoization for the far/interior terrain projection pair.
; D0/D1 are signed long numerators, D2.w is a NONZERO signed divisor.
; Preserve every other register and X. NZVC are dead at both call sites:
; the immediately following ADDI.W #46,D1 replaces all condition flags.
; Cache the full DIVS result, including remainder and overflow behavior.
Resident_TerrainProject:
        divs.w D2,D0
        cmp.w Terrain_ProjectDepth(PC),D2
        bne.b .miss
        cmp.l Terrain_ProjectInput(PC),D1
        bne.b .miss
        move.l Terrain_ProjectResult(PC),D1
        rts
.miss:
        move.l A0,-(SP)
        lea Terrain_ProjectDepth(PC),A0
        move.w D2,(A0)+
        move.l D1,(A0)+
        divs.w D2,D1
        move.l D1,(A0)
        movea.l (SP)+,A0
        rts
; Zero is an invalid key: the unchanged caller bypasses both divisions.
; These writable data words are never executed; no code invalidation is needed.
Terrain_ProjectDepth:
        dc.w 0
Terrain_ProjectInput:
        dc.l 0
Terrain_ProjectResult:
        dc.l 0
