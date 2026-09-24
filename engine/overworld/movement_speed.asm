ExtraHeldBSpeed::
	ld a, [wWalkBikeSurfState]
	and a
	jr z, .oneSpeedup
	dec a
	jr z, .bike
	call DoBikeSpeedup
.oneSpeedup
	call DoBikeSpeedup
	ret
.bike
	call DoBikeSpeedup
	call DoBikeSpeedup
	call DoBikeSpeedup
	call DoBikeSpeedup
	ret