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

CalcExpToLevelUp:
	ld a, [wLoadedMonLevel]
	cp MAX_LEVEL
	jr z, .atMaxLevel
	inc a
	ld d, a
	callfar CalcExperience
	ld hl, wLoadedMonExp + 2
	ld de, wBuffer + 2
	ldh a, [hExperience + 2]
	sub [hl]
	ld [de], a
	dec hl
	dec de
	ldh a, [hExperience + 1]
	sbc [hl]
	ld [de], a
	dec hl
	dec de
	ldh a, [hExperience]
	sbc [hl]
	ld [de], a
	ret
.atMaxLevel
	ld hl, wBuffer
	xor a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ret

; Prints each of the loaded mon's known moves' Type (over the blank left
; side of the PP rows) and Base Power/Accuracy (in place of the PP
; numbers) in the moves box on status screen page 2, then waits for a
; button press and returns it in e.
; farcalled from status_screen.asm when START is pressed on that page.
ShowMoveDetails:
	ld de, wLoadedMonMoves
	hlcoord 1, 10
	ld a, NUM_MOVES
	ld [wBuffer + 19], a
.loop
	ld a, l
	ld [wBuffer + 16], a
	ld a, h
	ld [wBuffer + 17], a
	ld a, [de]
	and a
	jp z, .blankRow
	push de
	dec a
	ld hl, Moves
	ld bc, MOVE_LENGTH
	call AddNTimes
	ld de, wBuffer
	ld a, BANK(Moves)
	call FarCopyData ; wBuffer+2 = power, +3 = type, +4 = accuracy

; moves.asm stores accuracy as pct*$ff/100; convert back to a percent,
; rounding to the nearest whole number: pct = (byte*100 + 127) / 255
	ld a, [wBuffer + 4]
	ldh [hMultiplicand + 2], a
	xor a
	ldh [hMultiplicand], a
	ldh [hMultiplicand + 1], a
	ld a, 100
	ldh [hMultiplier], a
	call Multiply
	ldh a, [hProduct + 3]
	ld l, a
	ldh a, [hProduct + 2]
	ld h, a
	ld de, 127
	add hl, de
	ld a, h
	ldh [hDividend + 2], a
	ld a, l
	ldh [hDividend + 3], a
	xor a
	ldh [hDividend], a
	ldh [hDividend + 1], a
	ld a, 255
	ldh [hDivisor], a
	ld b, 4
	call Divide
	ldh a, [hQuotient + 3]
	ld [wBuffer + 18], a

	ld a, [wBuffer + 3]
	add a
	ld hl, TypeNames
	ld e, a
	ld d, 0
	add hl, de
	ld de, wBuffer + 6
	ld bc, 2
	ld a, BANK(TypeNames)
	call FarCopyData ; wBuffer+6/7 = pointer to the type's name string
	ld a, [wBuffer + 6]
	ld l, a
	ld a, [wBuffer + 7]
	ld h, a
	ld de, wBuffer + 6
	ld bc, 9
	ld a, BANK(TypeNames)
	call FarCopyData ; wBuffer+6.. = type name string

	ld a, [wBuffer + 16]
	ld l, a
	ld a, [wBuffer + 17]
	ld h, a
	inc hl
	inc hl
	ld de, wBuffer + 6
	call PlaceString ; print the type name at col 3

	ld a, [wBuffer + 16]
	ld l, a
	ld a, [wBuffer + 17]
	ld h, a
	ld bc, 9
	add hl, bc ; col 10, where the PP numbers used to be
	ld a, "<BOLD_P>"
	ld [hli], a
	push hl
	ld a, " "
	ld [hli], a
	ld [hli], a
	ld [hli], a
	pop hl
	ld de, wBuffer + 2
	lb bc, 1, 3
	call PrintNumber ; power (blank, not zero, for unused leading digits)
	ld a, " "
	ld [hli], a
	ld a, "<BOLD_A>"
	ld [hli], a
	push hl
	ld a, " "
	ld [hli], a
	ld [hli], a
	ld [hli], a
	pop hl
	ld de, wBuffer + 18
	lb bc, 1, 3
	call PrintNumber ; accuracy (blank, not zero, for unused leading digits)
	pop de
	jr .nextRow
.blankRow
; no move in this slot; blank the whole row instead of leaving old PP text
	REPT 18
	ld a, " "
	ld [hli], a
	ENDR
.nextRow
	ld a, [wBuffer + 16]
	ld l, a
	ld a, [wBuffer + 17]
	ld h, a
	ld bc, SCREEN_WIDTH * 2
	add hl, bc
	inc de
	ld a, [wBuffer + 19]
	dec a
	ld [wBuffer + 19], a
	jp nz, .loop
.wait
	ld a, 1
	ldh [hAutoBGTransferEnabled], a
	call Delay3
	ld b, A_BUTTON | B_BUTTON | SELECT | START | D_UP | D_DOWN
.waitForButtonPress
	push bc
	call JoypadLowSensitivity
	pop bc
	ldh a, [hJoy5]
	and b
	jr z, .waitForButtonPress
	bit BIT_SELECT, a
	jr z, .returnButton
	call StatusMoveOrderMenu
	callfar StatusScreen2Hidden
	jp ShowMoveDetails
.returnButton
	ld e, a ; Bankswitch clobbers a/b/c on return, so pass the button mask via e
	ret

StatusMoveOrderMenu:
	ld a, [wMonDataLocation]
	cp PLAYER_PARTY_DATA
	jr z, .supported
	cp BOX_DATA
	ret nz
.supported
	xor a
	ld [wBuffer + 20], a
	dec a
	ld [wBuffer + 21], a
.redraw
	call .drawCursors
.wait
	ld b, D_UP | D_DOWN | B_BUTTON | SELECT
	push bc
	call JoypadLowSensitivity
	pop bc
	ldh a, [hJoy5]
	and b
	jr z, .wait
	bit BIT_B_BUTTON, a
	ret nz
	bit BIT_D_UP, a
	jr nz, .up
	bit BIT_D_DOWN, a
	jr nz, .down
	ld a, [wBuffer + 21]
	cp $ff
	jr nz, .swap
	ld a, [wBuffer + 20]
	ld [wBuffer + 21], a
	jr .redraw
.up
	ld hl, wBuffer + 20
	ld a, [hl]
	and a
	jr nz, .decrement
	ld a, [wNumMovesMinusOne]
	ld [hl], a
	jr .redraw
.decrement
	dec [hl]
	jr .redraw
.down
	ld hl, wBuffer + 20
	ld a, [wNumMovesMinusOne]
	cp [hl]
	jr nz, .increment
	ld [hl], 0
	jr .redraw
.increment
	inc [hl]
	jr .redraw
.swap
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	ld a, [wMonDataLocation]
	cp PLAYER_PARTY_DATA
	jr z, .gotBase
	ld hl, wBoxMon1Moves
	ld bc, wBoxMon2 - wBoxMon1
.gotBase
	ld a, [wWhichPokemon]
	call AddNTimes
	push hl
	call .swapBytes
	pop hl
	ld bc, wPartyMon1PP - wPartyMon1Moves
	add hl, bc
	call .swapBytes
	ld a, [wMonDataLocation]
	cp PLAYER_PARTY_DATA
	jr nz, .reload
	ld a, [wIsInBattle]
	and a
	jr z, .reload
	ld a, [wWhichPokemon]
	ld b, a
	ld a, [wPlayerMonNumber]
	cp b
	jr nz, .reload
	ld a, [wPlayerBattleStatus3]
	bit TRANSFORMED, a
	jr nz, .reload
	ld hl, wBattleMonMoves
	call .swapBytes
	ld hl, wBattleMonPP
	call .swapBytes
	ld hl, wPlayerDisabledMove
	ld a, [hl]
	swap a
	and $f
	ld b, a
	ld a, [wBuffer + 20]
	inc a
	cp b
	jr z, .disabledWasCurrent
	ld a, [wBuffer + 21]
	inc a
	cp b
	jr nz, .reload
	ld a, [wBuffer + 20]
	jr .updateDisabled
.disabledWasCurrent
	ld a, [wBuffer + 21]
.updateDisabled
	inc a
	swap a
	ld b, a
	ld a, [hl]
	and $f
	or b
	ld [hl], a
.reload
	call LoadMonData
	ret
.swapBytes
	push hl
	ld a, [wBuffer + 21]
	ld c, a
	ld b, 0
	add hl, bc
	ld d, h
	ld e, l
	pop hl
	ld a, [wBuffer + 20]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [de]
	ld b, [hl]
	ld [hl], a
	ld a, b
	ld [de], a
	ret
.drawCursors
	hlcoord 1, 9
	ld de, SCREEN_WIDTH * 2
	ld b, NUM_MOVES
.clearLoop
	ld [hl], " "
	add hl, de
	dec b
	jr nz, .clearLoop
	ld a, [wBuffer + 21]
	cp $ff
	jr z, .drawCurrent
	hlcoord 1, 9
	ld bc, SCREEN_WIDTH * 2
	call AddNTimes
	ld [hl], "▷"
.drawCurrent
	hlcoord 1, 9
	ld a, [wBuffer + 20]
	ld bc, SCREEN_WIDTH * 2
	call AddNTimes
	ld [hl], "▶"
	ret
