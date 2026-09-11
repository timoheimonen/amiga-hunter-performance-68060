; Static eight-colour title picture, KS3.1/PAL. CHIP hunk, position-independent entry.
; Intuition owns the display and input; return to DOS after press and release.
        org 0
start:
        movem.l d0-d7/a0-a6,-(sp)
        lea start(pc),a5
        move.l 4.w,a6
        cmpi.w #39,20(a6)       ; lib_Version: this picture requires V39 APIs
        blo cleanup
        ; Let Exec/CPU support flush dirty data before disabling the data cache.
        ; CacheControl uses the Exec bit definitions, not the 68060 CACR layout.
        moveq #0,d0
        move.l #$100,d1         ; CACRF_EnableD; retain the instruction-cache state
        jsr -648(a6)            ; CacheControl; leave D-cache off for the game
        lea intuition_name(pc),a1
        moveq #39,d0
        jsr -552(a6)
        move.l d0,ibase-start(a5)
        beq cleanup
        lea graphics_name(pc),a1
        moveq #39,d0
        jsr -552(a6)
        move.l d0,gbase-start(a5)
        beq cleanup
        move.l ibase-start(a5),a6
        suba.l a0,a0
        lea screen_tags(pc),a1
        jsr -612(a6)
        move.l d0,screen-start(a5)
        beq cleanup
        move.l d0,window_screen-start(a5)
        lea new_window(pc),a0
        jsr -204(a6)
        move.l d0,window-start(a5)
        beq cleanup
        move.l d0,a0
        lea blank_pointer(pc),a1
        moveq #1,d0
        moveq #16,d1
        moveq #0,d2
        moveq #0,d3
        jsr -270(a6)
        ; Copy planar image once into the screen's own bitmap.
        move.l screen-start(a5),a0
        move.l 88(a0),a2
        moveq #0,d2
        move.w (a2),d2
        sub.w #IMAGE_ROW_BYTES,d2
        addq.l #8,a2
        lea image_data(pc),a0
        moveq #IMAGE_DEPTH-1,d3
.plane:
        move.l (a2)+,a1
        move.w #IMAGE_HEIGHT-1,d1
.row:
        moveq #IMAGE_ROW_BYTES/4-1,d0
.copy:
        move.l (a0)+,(a1)+
        dbra d0,.copy
        adda.w d2,a1
        dbra d1,.row
        dbra d3,.plane
        move.l gbase-start(a5),a6
        move.l screen-start(a5),a0
        lea 44(a0),a0
        lea image_palette(pc),a1
        jsr -882(a6)            ; LoadRGB32 after the picture has been copied
        move.l ibase-start(a5),a6
        move.l screen-start(a5),a0
        jsr -252(a6)            ; ScreenToFront
wait_input:
        move.l window-start(a5),a0
        move.l 86(a0),a0
        move.l 4.w,a6
        jsr -384(a6)            ; WaitPort: sleep until an input event arrives
.get_message:
        move.l window-start(a5),a0
        move.l 86(a0),a0
        jsr -372(a6)            ; GetMsg
        tst.l d0
        beq.s wait_input
        move.l d0,a1
        move.l 20(a1),d2
        move.w 24(a1),d3
        jsr -378(a6)            ; ReplyMsg before processing copied fields
        tst.l pressed_class-start(a5)
        bne.s .release
        cmp.l #$400,d2
        bne.s .mouse
        cmp.w #$40,d3           ; RAWKEY Space
        bne.s .get_message
        bra.s .press
.mouse:
        cmp.l #8,d2
        bne.s .get_message
        cmp.w #$68,d3           ; Left/right/middle mouse button down
        blo.s .get_message
        cmp.w #$6a,d3
        bhi.s .get_message
.press:
        move.l d2,pressed_class-start(a5)
        or.w #$80,d3
        move.w d3,pressed_code-start(a5)
        bra.s .get_message
.release:
        cmp.l pressed_class-start(a5),d2
        bne.s .get_message
        cmp.w pressed_code-start(a5),d3
        bne.s .get_message
cleanup:
        move.l ibase-start(a5),a6
        move.l window-start(a5),d0
        beq.s .no_window
        move.l d0,a0
        jsr -72(a6)
.no_window:
        move.l screen-start(a5),d0
        beq.s .no_screen
        move.l d0,a0
        jsr -66(a6)
.no_screen:
        move.l gbase-start(a5),d0
        beq.s .no_gfx
        move.l d0,a6
        jsr -228(a6)            ; WaitBlit
        jsr -270(a6)            ; Allow display teardown to complete
        jsr -270(a6)
        move.l gbase-start(a5),a1
        move.l 4.w,a6
        jsr -414(a6)
.no_gfx:
        move.l ibase-start(a5),d0
        beq.s .done
        move.l d0,a1
        move.l 4.w,a6
        jsr -414(a6)
.done:
        movem.l (sp)+,d0-d7/a0-a6
        moveq #0,d0             ; Successful DOS exit, including graceful skip
        rts

intuition_name: dc.b 'intuition.library',0
graphics_name: dc.b 'graphics.library',0
        even
screen_tags:
        dc.l $80000023,IMAGE_WIDTH,$80000024,IMAGE_HEIGHT,$80000025,IMAGE_DEPTH
        dc.l $80000032,$8004     ; HIRES | LACE, default PAL monitor
        dc.l $80000036,0,$80000037,1,$80000038,1,$8000003e,0,0,0
new_window:
        dc.w 0,0,IMAGE_WIDTH,IMAGE_HEIGHT
        dc.b 0,0
        dc.l $408,$31940,0,0,0
window_screen: dc.l 0
        dc.l 0
        dc.w 0,0,IMAGE_WIDTH,IMAGE_HEIGHT,$f
blank_pointer: dcb.l 3,0
ibase: dc.l 0
gbase: dc.l 0
screen: dc.l 0
window: dc.l 0
pressed_class: dc.l 0
pressed_code: dc.w 0
