; Moved out of engine/items/item_effects.asm (bank3 has no free space) - see ItemUseBall.
; Checks whether a ball can be thrown at all: in battle, not at a trainer's
; mon, and (outside the old man/Pikachu tutorial battles) party & box not full.
; Returns normally if the ball can be thrown; otherwise tail-jumps to the
; appropriate bank3 failure handler and never returns to the caller.
CheckPartyOrBoxFullForBallThrow::
	ld a, [wIsInBattle]
	and a
	jr nz, .inBattle
	pop hl ; this call never returns; discard the return address
	farjp ItemUseNotTime

.inBattle
	dec a
	jr z, .canThrow ; wild battle
	pop hl ; this call never returns; discard the return address
	farjp ThrowBallAtTrainerMon

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
	pop hl ; this call never returns; discard the return address
	farjp BoxFullCannotThrowBall
