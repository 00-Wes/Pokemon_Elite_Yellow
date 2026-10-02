PewterSpeechHouse_Script:
	jp EnableAutoTextBoxDrawing

PewterSpeechHouse_TextPointers:
	def_text_pointers
	dw_const MoveRelearnerText1,              TEXT_PEWTERSPEECHHOUSE_GAMBLER
	dw_const PewterSpeechHouseYoungsterText, TEXT_PEWTERSPEECHHOUSE_YOUNGSTER

PewterSpeechHouseYoungsterText:
	text_far _PewterSpeechHouseYoungsterText
	text_end
