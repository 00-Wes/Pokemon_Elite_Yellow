; Stat Exp/DV toggle view support for the status screen (see status_screen.asm).
; Lives in a separate bank ("Engine Spillover") since bank4 has no free space.

; DV parsing from shin pokered
;joenote - parse DV scores
DVParse:
	push hl
	push bc
	ld hl, wDVCalcVar2
	ld b, $00

	ld a, [wLoadedMonDVs]	;get attack dv
	swap a
	and $0F
	ld [hl], a
	inc hl
	and $01
	sla a
	sla a
	sla a
	or b
	ld b, a


	ld a, [wLoadedMonDVs]	;get defense dv
	and $0F
	ld [hl], a
	inc hl
	and $01
	sla a
	sla a
	or b
	ld b, a

	ld a, [wLoadedMonDVs + 1]	;get speed dv
	swap a
	and $0F
	ld [hl], a
	inc hl
	and $01
	sla a
	or b
	ld b, a

	ld a, [wLoadedMonDVs + 1]	;get special dv
	and $0F
	ld [hl], a
	inc hl
	and $01
	or b
	ld b, a

	ld [hl], b	;load hp dv

	pop bc
	pop hl
	ret

; prints the stat exp/DV number below the HP bar, shown in place of the HP
; fraction when toggled
DrawStatusScreenToggleNumber:
	coord hl, 11, 3
	push de
	ld bc, SCREEN_WIDTH + 1
	add hl, bc
	call DVParse
	push hl
	ld a, " "
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	pop hl
	ld a, [wStatusScreenViewMode]
	bit BIT_SELECT, a
	jr z, .checkstart
	ld de, wLoadedMonHPExp
	lb bc, 2, 5
	jr .printnum
.checkstart	;print DVs if DV view is active
	bit BIT_START, a
	jr z, .doregular
	ld de, wDVCalcVar2 + 4
	lb bc, 1, 2
.printnum
	call PrintNumber
	jr .done
.doregular	;view is normal, print the HP fraction like DrawHP does
	ld de, wLoadedMonHP
	lb bc, 2, 3
	call PrintNumber
	ld a, "/"
	ld [hli], a
	ld de, wLoadedMonMaxHP
	lb bc, 2, 3
	call PrintNumber
.done
	pop de
	ret

; Redraws just the toggled numbers (HP-exp/DV and the stats box) without
; the whiteout/screen clear/cry that a full StatusScreen redraw does
RefreshStatusScreenToggle:
	call DrawStatusScreenToggleNumber
	ld d, 0
	farjp PrintStatsBox

; e = STATUS_VIEW_STATEXP or STATUS_VIEW_DV to toggle to/from STATUS_VIEW_NORMAL
ToggleView:
	ld a, [wStatusScreenViewMode]
	cp e
	ld a, STATUS_VIEW_NORMAL
	jr z, .store
	ld a, e
.store
	ld [wStatusScreenViewMode], a
	ret

; e = pressed buttons (passed via e, not a, since Bankswitch clobbers a);
; if SELECT/START pressed, toggles the view and does a seamless partial
; redraw, returning with carry set. Otherwise carry is clear.
CheckToggleView:
	ld a, e
	and SELECT | START
	ret z
	ld e, a
	call ToggleView
	call RefreshStatusScreenToggle
	scf
	ret
