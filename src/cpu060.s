; 68060-only bootstrap and resident cache support. Assembled at the original
; first HUNK end; all resident internal references are PC-relative.
        machine 68060
        org $EE8
Bootstrap_OpenDos:
        movem.l D0-D7/A0-A6,-(SP)
        ; Also cover --no-custom-intro and direct Hunt01.exe startup.
        ; Exec/CPU support owns writeback and the global cache state transition.
        moveq #0,D0
        move.l #$101,D1                ; CACRF_EnableI | CACRF_EnableD (Exec bits)
        jsr -648(A6)                   ; CacheControl: flush, then disable caches
        ifne FAST_DATA
        bsr.w Bootstrap_AllocFast
        endif
        movem.l (SP)+,D0-D7/A0-A6
        jmp -$228(A6)                  ; displaced OpenLibrary call

        ifne FAST_DATA
; Allocate before the intros take over. Reverse allocation avoids the fixed
; low expansion-memory loader; reject any remaining legacy scratch overlap.
Bootstrap_AllocFast:
        move.l #$18A00+VIEW_9*$1000,D0
        move.l #$50005,D1              ; MEMF_PUBLIC|FAST|CLEAR|REVERSE (KS3.1)
        jsr -198(A6)                   ; Exec AllocMem
        tst.l D0
        beq.b .done
        cmpi.l #$400000,D0
        blo.b .reject
        move.l D0,D1
        addi.l #$18A00+VIEW_9*$1000,D1
        bcs.b .reject
        cmpi.l #$C00000,D0
        bhs.b .above_low_fast
        cmpi.l #$C00000,D1
        bhi.b .reject
        bra.b .accept
.above_low_fast:
        cmpi.l #$C80000,D0
        blo.b .reject                 ; legacy resource preload arena
.accept:
        lea Bootstrap_FastBase(PC),A0
        move.l D0,(A0)
.done:
        rts
.reject:
        movea.l D0,A1
        move.l #$18A00+VIEW_9*$1000,D0
        jsr -210(A6)                   ; Exec FreeMem; retain Chip fallback
        rts
Bootstrap_FastBase:
        dc.l 0
        endif

Bootstrap_Install:
        movem.l D0-D7/A0-A6,-(SP)
        ; Loader_Tail has just copied the original loader; A2 points past it.
        ; Reserve the existing unused gap before normalized loader $1D98.
        movea.l A2,A4
        lea Resident_Start(PC),A0
        lea Resident_End(PC),A1
.copy_resident:
        move.b (A0)+,(A2)+
        cmpa.l A0,A1
        bne.b .copy_resident
        ; Patch the decompressed source before Boot_CopyDown and trainer hooks.
        lea Game_Patches(PC),A0
.next_patch:
        move.l (A0)+,D0
        beq.b .hooks
        movea.l D0,A1
        move.w (A0)+,D0
.copy_patch:
        move.b (A0)+,(A1)+
        dbf D0,.copy_patch
        bra.b .next_patch
.hooks:
        ifne FAST_DATA
        move.l Bootstrap_FastBase(PC),Resident_FastBase-Resident_Start(A4)
        lea Resident_InitData-Resident_Start(A4),A0
        move.l A0,$47D36.l             ; relocated JMP operand in unused table
        endif
        ifne TERRAIN_DELTA
        lea Resident_TerrainDelta-Resident_Start(A4),A0
        move.l A0,$43B54.l             ; far-edge absolute JSR operand
        move.l A0,$47D3C.l             ; near-edge trampoline JMP operand
        endif
        ifne TERRAIN_DIV
        lea Resident_TerrainDiv-Resident_Start(A4),A0
        move.l A0,$43716.l
        move.l A0,$43734.l
        move.l A0,$43740.l
        endif
        ifne TERRAIN_PROJECT
        lea Resident_TerrainProject-Resident_Start(A4),A0
        move.l A0,$47D42.l             ; shared projection trampoline operand
        endif
        ifne SPAN_FILL
        lea Resident_SpanFill-Resident_Start(A4),A0
        move.l A0,$4791A.l             ; polygon-level generated-span dispatch
        endif
        ifne TRAPEZOID_FILL
        lea Resident_TrapezoidFill-Resident_Start(A4),A0
        move.l A0,$47C02.l             ; once-per-record trapezoid dispatch
        endif
        ifne VIEW_9
        bsr.w Bootstrap_InstallView9
        endif
        move.w #$4EF9,$41EBA.l          ; displaced LEA supervisor stack
        lea Resident_Enable-Resident_Start(A4),A0
        move.l A0,$41EBC.l
        movem.l (SP)+,D0-D7/A0-A6
        jmp $40700.l

        ifne VIEW_9
Bootstrap_InstallView9:
        move.l Bootstrap_FastBase(PC),D0
        beq.w .done                   ; retain a complete original 7x7 fallback
        movea.l D0,A3
        adda.l #$18A00,A3
        movea.l A3,A2
        lea View9_Start(PC),A0
        lea View9_End(PC),A1
.copy:
        move.b (A0)+,(A2)+
        cmpa.l A0,A1
        bne.b .copy
        lea View9_Patches(PC),A0
.patch:
        move.l (A0)+,D0
        beq.b .targets
        movea.l D0,A1
        move.w (A0)+,D0
.bytes:
        move.b (A0)+,(A1)+
        dbf D0,.bytes
        bra.b .patch
.targets:
        lea View9_DrawWindow-View9_Start(A3),A0
        move.l A0,$439B2.l
        lea View9_ProjectGrid-View9_Start(A3),A0
        move.l A0,$43B1E.l
        lea View9_QueueObject-View9_Start(A3),A0
        move.l A0,$44232.l
        lea View9_ShapeParts-View9_Start(A3),A0
        move.l A0,$44E68.l
.done:
        rts
        endif

Resident_Start:
Resident_Enable:
        lea $7E800.l,SP                ; displaced game_startup_trap instruction
        movem.l D0/A0,-(SP)
        lea Resident_Sync(PC),A0
        move.l A0,$BC.w                ; private TRAP #15; VBR is zero in target
        cinva IC                       ; all copied/trainer-patched code is final
        movec CACR,D0
        andi.l #$7FFF7FFF,D0            ; D-cache is already off since CacheControl
        ori.l #$8000,D0                ; EIC=1; preserve other controls; EDC=0
        movec D0,CACR
        movem.l (SP)+,D0/A0
        jmp $1EC0.l                    ; original switch to user mode
Resident_Sync:
        cinva IC                       ; whole-cache invalidation avoids page errata
        rte
Resident_LoaderReturn:
        trap #15                       ; synchronize freshly loaded code overlays
        movem.l (SP)+,D0-D7/A0-A6
        moveq #0,D0
        rts
        ifne FAST_DATA
Resident_InitData:
        jsr $83C4.l                    ; original Chip arena initialization
        move.w CCR,-(SP)
        movem.l D0/A0,-(SP)
        move.l Resident_FastBase(PC),D0
        beq.b .unchanged
        movea.l D0,A0
        move.l A0,$837E.l              ; object geometry: $10000 bytes
        adda.l #$10000,A0
        move.l A0,$8386.l              ; terrain/scratch: $8200 bytes
        adda.l #$8200,A0
        move.l A0,$838E.l              ; trig B followed by trig A
        adda.l #$400,A0
        move.l A0,$8396.l
.unchanged:
        movem.l (SP)+,D0/A0
        move.w (SP)+,CCR
        rts
Resident_FastBase:
        dc.l 0
        endif
        ifne TERRAIN_DELTA
        include "terrain_delta.s"
        endif
        ifne TERRAIN_DIV
        include "terrain_div.s"
        endif
        ifne TERRAIN_PROJECT
        include "terrain_project.s"
        endif
        ifne SPAN_FILL
        include "span_fill.s"
        endif
        ifne TRAPEZOID_FILL
        include "trapezoid_fill.s"
        endif
Resident_End:
        even
        ifne VIEW_9
        include "view9.s"
View9_Patches:
        include "view9_patches.i"
        dc.l 0
        endif
Game_Patches:
        include "game_patches.i"
        dc.l 0
        cnop 0,4
