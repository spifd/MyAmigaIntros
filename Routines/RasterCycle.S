	bsr	RasterCycle

;; - Raster Cycle Routine -

RasterCycle:
	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.l	#$09f00000,BltCon0(a5)
	move.l	#2^16*2+2,BltAmod(a5)
	move.l	#FirstCycling+6+4,BltApth(a5)
	move.l	#FirstCycling+6,BltDpth(a5)
	move.w	#64*[(352/8)-1]+1,BltSize(a5)

	WaitBlitter
	move.w	#$0002,BltCon1(a5)
	move.l	#SecondCycling+6+[[(352/8)-2]*4],BltApth(a5)
	move.l	#SecondCycling+6+[[(352/8)-1]*4],BltDpth(a5)
	move.w	#64*[(352/8)-1]+1,BltSize(a5)

	move.l	ColorPointer(pc),a0
	move.w	(a0),FirstCycling+6+[[(352/8)-1]*4]
	move.w	(a0),SecondCycling+6

	addq.l	#2,ColorPointer
	cmp.l	#RasterColorsEnd,ColorPointer
	bne.s	RasterCycleEnd

	move.l	#RasterColors,ColorPointer

RasterCycleEnd:
	rts

ColorPointer:	dc.l	RasterColors

RasterColors:
	dc.w	$0f00,$0f10,$0f20,$0f30,$0f40,$0f50,$0f60,$0f70
	dc.w	$0f80,$0f90,$0fa0,$0fb0,$0fc0,$0fd0,$0fe0,$0ff0
	dc.w	$0ef0,$0df0,$0cf0,$0bf0,$0af0,$09f0,$08f0,$07f0
	dc.w	$06f0,$05f0,$04f0,$03f0,$02f0,$01f0,$00f0,$00f1
	dc.w	$00f2,$00f3,$00f4,$00f5,$00f6,$00f7,$00f8,$00f9
	dc.w	$00fa,$00fb,$00fc,$00fd,$00fe,$00ff,$00ef,$00df
	dc.w	$00cf,$00bf,$00af,$009f,$008f,$007f,$006f,$005f
	dc.w	$004f,$003f,$002f,$001f,$000f,$010f,$020f,$030f
	dc.w	$040f,$050f,$060f,$070f,$080f,$090f,$0a0f,$0b0f
	dc.w	$0c0f,$0d0f,$0e0f,$0f0f,$0f0e,$0f0c,$0f0b,$0f0a
	dc.w	$0f09,$0f08,$0f07,$0f06,$0f05,$0f04,$0f03,$0f02
	dc.w	$0f01,$0f00
RasterColorsEnd:

FirstCycling:
	dc.b	FirstCyclingLine,$39
	dc.w	$fffe
	blk.l	(352/8)+1,$01800000

SecondCycling:
	dc.b	SecondCyclingLine,$39
	dc.w	$fffe
	blk.l	(352/8)+1,$01800000
