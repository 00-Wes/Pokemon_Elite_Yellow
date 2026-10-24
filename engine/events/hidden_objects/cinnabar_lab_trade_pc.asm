CinnabarLabFossilRoomTradeTestPCHiddenObject:
	ld a, CINNABARLABFOSSILROOM_TRADEBACKNPC
	ldh [hSpriteIndex], a
	ld a, SPRITE_FACING_DOWN
	ldh [hSpriteFacingDirection], a
	ld a, $1
	ld [wUpdateSpritesEnabled], a
	call SetSpriteFacingDirectionAndDelay
	call UpdateSprites
	ld c, 5
	call DelayFrames
	ld a, $ff
	ldh [hItemAlreadyFound], a
	ret
