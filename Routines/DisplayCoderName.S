	lea	Bp,a1
	bsr	DisplayCoderName

;; - Display Coder Name Routine -

; a1 = Bitplane Address

DisplayCoderName:
	move.l	CoderName+00(pc),44*0(a1)
	move.l	CoderName+04(pc),44*1(a1)
	move.l	CoderName+08(pc),44*2(a1)
	move.l	CoderName+12(pc),44*3(a1)
	move.l	CoderName+16(pc),44*4(a1)
	rts

CoderName:	
	dc.l	%00001111011110101111010111100000
	dc.l	%00001000010010101001010000100000
	dc.l	%00001111011110101111010000100000
	dc.l	%00000001010000101010010000100000
	dc.l	%00001111010000101001010000100000
