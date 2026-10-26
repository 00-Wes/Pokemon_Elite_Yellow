; Moved out of engine/items/item_effects.asm (bank3 has no free space) - see ItemUseBall.
; Checks whether a ball can be thrown at all: in battle, not at a trainer's
; mon, and (outside the old man/Pikachu tutorial battles) party & box not full.
; Returns normally if the ball can be thrown; otherwise tail-jumps to the
; appropriate bank3 failure handler and never returns to the caller.
CheckPartyOrBoxFullForBallThrow::
	ld a, [wIsInBattle]
	and a
	jr nz, .inBattle
	ld hl, ItemUseNotTime
	ld b, BANK(ItemUseNotTime)
	jr .cannotThrow

.inBattle
	dec a
	jr z, .canThrow ; wild battle
	ld hl, ThrowBallAtTrainerMon
	ld b, BANK(ThrowBallAtTrainerMon)
	jr .cannotThrow

.canThrow
	xor a
	ld [wCapturedMonSpecies], a

; skip the party/box full check for the old man and Pikachu tutorial battles
	ld a, [wBattleType]
	cp BATTLE_TYPE_OLD_MAN
	ret z
	cp BATTLE_TYPE_PIKACHU
	ret z
	ld a, [wPartyCount] ; is party full?
	cp PARTY_LENGTH
	jr nz, .canThrow2
	ld a, [wBoxCount] ; is box full?
	cp MONS_PER_BOX
	jr z, .boxFull

.canThrow2
	ld a, [wBattleType]
	cp BATTLE_TYPE_SAFARI
	ret nz
	ld hl, wNumSafariBalls
	dec [hl] ; remove a Safari Ball
	ret

.boxFull
	ld hl, BoxFullCannotThrowBall
	ld b, BANK(BoxFullCannotThrowBall)

; discards the callfar's Bankswitch frame and ItemUseBall's continuation, then
; farjps so the handler returns straight to ItemUseBall's caller; the bank switch
; must happen from home bank code, since this bank's code would be unmapped mid-routine
.cannotThrow
	pop de
	pop de
	pop de
	jp Bankswitch
