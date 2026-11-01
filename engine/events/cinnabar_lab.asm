GiveFossilToCinnabarLab::
	ld hl, wd730
	set 6, [hl]
	xor a
	ld [wCurrentMenuItem], a
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, [wFilteredBagItemsCount]
	dec a
	ld [wMaxMenuItem], a
	ld a, 2
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	ld a, [wFilteredBagItemsCount]
	dec a
	ld bc, 2
	ld hl, 3
	call AddNTimes
	dec l
	ld b, l
	ld c, $d
	hlcoord 0, 0
	call TextBoxBorder
	call UpdateSprites
	call PrintFossilsInBag
	ld hl, wd730
	res 6, [hl]
	call HandleMenuInput
	bit BIT_B_BUTTON, a
	jr nz, .cancelledGivingFossil
	ld hl, wFilteredBagItems
	ld a, [wCurrentMenuItem]
	ld d, 0
	ld e, a
	add hl, de
	ld a, [hl]
	ldh [hItemToRemoveID], a
	cp DOME_FOSSIL
	jr z, .choseDomeFossil
	cp HELIX_FOSSIL
	jr z, .choseHelixFossil
	ld b, AERODACTYL
	jr .fossilSelected
.choseHelixFossil
	ld b, OMANYTE
	jr .fossilSelected
.choseDomeFossil
	ld b, KABUTO
.fossilSelected
	ld [wFossilItem], a
	ld a, b
	ld [wFossilMon], a
	call LoadFossilItemAndMonName
	ld hl, .ScientistSeesFossilText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .cancelledGivingFossil
	ld hl, .ScientistTakesFossilText
	call PrintText
	ld a, [wFossilItem]
	ldh [hItemToRemoveID], a
	farcall RemoveItemByID
	ld hl, .GoForAWalkText
	call PrintText
	SetEvents EVENT_GAVE_FOSSIL_TO_LAB, EVENT_LAB_STILL_REVIVING_FOSSIL
	ret
.cancelledGivingFossil
	ld hl, .ComeAgainText
	call PrintText
	ret

.ScientistSeesFossilText:
	text_far _CinnabarLabFossilRoomScientist1SeesFossilText
	text_end

.ScientistTakesFossilText:
	text_far _CinnabarLabFossilRoomScientist1TakesFossilText
	text_end

.GoForAWalkText:
	text_far _CinnabarLabFossilRoomScientist1GoForAWalkText2
	text_end

.ComeAgainText:
	text_far _CinnabarLabFossilRoomScientist1ComeAgainText
	text_end

PrintFossilsInBag:
; Prints each fossil in the player's bag on a separate line in the menu.
	ld hl, wFilteredBagItems
	xor a
	ldh [hItemCounter], a
.loop
	ld a, [hli]
	cp $ff
	ret z
	push hl
	ld [wd11e], a
	call GetItemName
	hlcoord 2, 2
	ldh a, [hItemCounter]
	ld bc, SCREEN_WIDTH * 2
	call AddNTimes
	ld de, wcd6d
	call PlaceString
	ld hl, hItemCounter
	inc [hl]
	pop hl
	jr .loop

; loads the names of the fossil item and the resulting mon
LoadFossilItemAndMonName::
	ld a, [wFossilMon]
	ld [wd11e], a
	call GetMonName
	call CopyToStringBuffer
	ld a, [wFossilItem]
	ld [wd11e], a
	call GetItemName
	ret

; the Museum scientist resurrects a DOME or HELIX fossil right away
MuseumScientistResurrectFossil::
	ld hl, .IntroText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jp nz, .comeAgain
	call .GetFossilsInBag
	ld a, [wFilteredBagItemsCount]
	and a
	jp z, .noFossils
	ld hl, wd730
	set 6, [hl]
	xor a
	ld [wCurrentMenuItem], a
	ld a, A_BUTTON | B_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, [wFilteredBagItemsCount]
	dec a
	ld [wMaxMenuItem], a
	ld a, 2
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	ld a, [wFilteredBagItemsCount]
	dec a
	ld bc, 2
	ld hl, 3
	call AddNTimes
	dec l
	ld b, l
	ld c, $d
	hlcoord 0, 0
	call TextBoxBorder
	call UpdateSprites
	call PrintFossilsInBag
	ld hl, wd730
	res 6, [hl]
	call HandleMenuInput
	bit BIT_B_BUTTON, a
	jr nz, .comeAgain
	ld hl, wFilteredBagItems
	ld a, [wCurrentMenuItem]
	ld d, 0
	ld e, a
	add hl, de
	ld a, [hl]
	ld [wFossilItem], a
	ld b, OMANYTE
	cp HELIX_FOSSIL
	jr z, .fossilSelected
	ld b, KABUTO
.fossilSelected
	ld a, b
	ld [wFossilMon], a
	call LoadFossilItemAndMonName
	ld hl, .SeesFossilText
	call PrintText
	ld a, [wFossilMon]
	ld b, a
	ld c, 20
	call GivePokemon
	jr nc, .noSpace
	ld a, [wFossilItem]
	ldh [hItemToRemoveID], a
	farcall RemoveItemByID
	ret
.comeAgain
	ld hl, .ComeAgainText
	call PrintText
	ret
.noFossils
	ld hl, .NoFossilsText
	call PrintText
	ret
.noSpace
	ld hl, .NoSpaceText
	call PrintText
	ret

.GetFossilsInBag
; fills wFilteredBagItems with the DOME and HELIX fossils in the player's bag
	xor a
	ld [wFilteredBagItemsCount], a
	ld de, wFilteredBagItems
	ld hl, .FossilsList
.loop
	ld a, [hli]
	and a
	jr z, .done
	push hl
	push de
	ld [wd11e], a
	ld b, a
	predef GetQuantityOfItemInBag
	pop de
	pop hl
	ld a, b
	and a
	jr z, .loop

	; A fossil's in the bag
	ld a, [wd11e]
	ld [de], a
	inc de
	push hl
	ld hl, wFilteredBagItemsCount
	inc [hl]
	pop hl
	jr .loop
.done
	ld a, $ff
	ld [de], a
	ret

.FossilsList:
	db DOME_FOSSIL
	db HELIX_FOSSIL
	db 0 ; end

.IntroText:
	text_far _Museum1FResurrectionScientistIntroText
	text_end

.NoFossilsText:
	text_far _Museum1FResurrectionScientistNoFossilsText
	text_end

.SeesFossilText:
	text_far _Museum1FResurrectionScientistSeesFossilText
	text_end

.ComeAgainText:
	text_far _Museum1FScientist1ComeAgainText
	text_end

.NoSpaceText:
	text_far _Museum1FScientist2YouDontHaveSpaceText
	text_end
