; ******************************
; *                            *
; * Title: Plasma RGB          *
; *                            *
; * Coder: Spirit              *
; * Date : May 1991            *
; *                            *
; * Infos: Simple Plasma RGB   *
; *                            *
; *                            *
; ******************************

;
;; ---- REGISTERS & VALUES ----
;

; - Exec.library -

ExecBase	= 4
Forbid		= -132
Permit		= -138
OpenLibrary	= -552
CloseLibrary	= -414

; - Blitter Registers -

	INCLUDE	TFTSD:Help/BlitterRegisters.S

; - Others -

RedYStep1	= 4
GreenYStep1	= 3
BlueYStep1	= 2

RedYStep2	= 2
GreenYStep2	= 3
BlueYStep2	= 5

RedDesignStep	= 10
GreenDesignStep	= 8
BlueDesignStep	= 5

OnePixelStep1	= 6
OnePixelStep2	= 10

PlasmaStartLine	= $50
PlasmaHeight	= 150
Ampli		= 40

;
;; ---- MACROS ----
;

;; - Wait Blitter Macro -

WaitBlitter:	MACRO
WaitBlitterLoop\@:
	btst	#14,$002(a5)
	bne.s	WaitBlitterLoop\@
		ENDM

;
;; ---- MAIN PROGRAM ----
;

Start:
	movem.l	d0-d7/a0-a6,-(sp)

	lea	$dff000,a5

	bsr	SaveAll

	move.w	#$7fff,$096(a5)
	move.w	#%1000001111000000,$096(a5)
	move.w	#$7fff,$09a(a5)
	move.w	#%1100000000100000,$09a(a5)

	move.l	#CopperList,$080(a5)
	clr.w	$088(a5)

	bsr	BuildRGBTables
	bsr	InitPlasma8Design

	move.l	#Irq3,$6c

LeftButtonTest:
	btst	#6,$bfe001
	bne.s	LeftButtonTest

End:
	bsr	RestoreAll

	movem.l	(sp)+,d0-d7/a0-a6
	rts

;
;; ---- INTERRUPT ----
;

Irq3:
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	$01c(a5),d0
	and.w	$01e(a5),d0

Vbl:
	btst	#5,d0
	beq.s	Irq3End

	btst	#10,$016(a5)
	beq.s	GoOnIrq3

	bsr	Plasma

GoOnIrq3:
	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Init Plasma8Design in CopperList -

InitPlasma8Design:
	lea	PlasmaBpl(pc),a0
	move.l	#Plasma8Design,d0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	rts

;; - Plasma Routine -

Plasma:
	move.l	RedPointerY(pc),a0
	move.l	GreenPointerY(pc),a1
	move.l	BluePointerY(pc),a2

	moveq	#(416/8)-1,d0
	lea	PlasmaCop+10(pc),a6

PlasmaLoop:
	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.l	#$0ffe0000,BltCon0(a5)
	move.l	#[(416/8)*2+4-1]*2,BltAmod(a5)
	move.l	#0,BltCmod(a5)

	move.w	(a0),d1
	add.w	d1,d1
	lea	RedTable,a3
	lea	(a3,d1.w),a3
	move.l	a3,BltApth(a5)

	move.w	(a1),d1
	add.w	d1,d1
	lea	GreenTable,a3
	lea	(a3,d1.w),a3
	move.l	a3,BltBpth(a5)

	move.w	(a2),d1
	add.w	d1,d1
	lea	BlueTable,a3
	lea	(a3,d1.w),a3
	move.l	a3,BltCpth(a5)

	move.l	a6,BltDpth(a5)

	move.w	#64*PlasmaHeight+1,BltSize(a5)

RedCtrl:
	add.l	#2*RedYStep2,a0
	cmp.l	#MotionTableYEnd,a0
	blt.s	GreenCtrl

	sub.l	#(MotionTableYEnd-MotionTableY),a0

GreenCtrl:
	add.l	#2*GreenYStep2,a1
	cmp.l	#MotionTableYEnd,a1
	blt.s	BlueCtrl

	sub.l	#(MotionTableYEnd-MotionTableY),a1

BlueCtrl:
	add.l	#2*BlueYStep2,a2
	cmp.l	#MotionTableYEnd,a2
	blt.s	GoOnPlasmaLoop

	sub.l	#(MotionTableYEnd-MotionTableY),a2

GoOnPlasmaLoop:
	addq.l	#4,a6
	dbra	d0,PlasmaLoop

	lea	RedPointerY(pc),a0
	add.l	#2*RedYStep1,(a0)
	cmp.l	#MotionTableYEnd,(a0)
	blt.s	NoRedMoreY

	sub.l	#(MotionTableYEnd-MotionTableY),(a0)

NoRedMoreY:
	lea	GreenPointerY(pc),a0
	add.l	#2*GreenYStep1,(a0)
	cmp.l	#MotionTableYEnd,(a0)
	blt.s	NoGreenMoreY

	sub.l	#(MotionTableYEnd-MotionTableY),(a0)

NoGreenMoreY:
	lea	BluePointerY(pc),a0
	add.l	#2*BlueYStep1,(a0)
	cmp.l	#MotionTableYEnd,(a0)
	blt.s	NoBlueMoreY

	sub.l	#(MotionTableYEnd-MotionTableY),(a0)

NoBlueMoreY:
	move.l	OnePixelPointer(pc),a0
	lea	PlasmaCop(pc),a1
	move.w	#PlasmaHeight-1,d2

OnePixelLoop:
	move.w	(a0),d0
	move.w	d0,d1
	and.b	#%11111000,d0
	add.b	#$15,d0
	move.b	d0,1(a1)
	and.b	#%00000111,d1
	move.b	d1,7(a1)

	add.l	#2*OnePixelStep2,a0
	cmp.l	#OnePixelMotionTableEnd,a0
	blt.s	GoOnOnePixelLoop

	sub.l	#(OnePixelMotionTableEnd-OnePixelMotionTable),a0

GoOnOnePixelLoop:
	add.l	#416/2+8,a1
	dbra	d2,OnePixelLoop

	lea	OnePixelPointer(pc),a0
	add.l	#2*OnePixelStep1,(a0)
	cmp.l	#OnePixelMotionTableEnd,(a0)
	blt.s	PlasmaEnd

	sub.l	#(OnePixelMotionTableEnd-OnePixelMotionTable),(a0)

PlasmaEnd:
	rts

RedPointerY:	dc.l	MotionTableY
GreenPointerY:	dc.l	MotionTableY
BluePointerY:	dc.l	MotionTableY

MotionTableY:
	dc.w	40,41,42,43,44,45,45,46,47,48,49,50,51,52,53,53,54,55,56
	dc.w	57,57,58,59,60,60,61,62,62,63,64,64,65,66,66,67,67,68,69
	dc.w	69,70,70,71,71,72,72,73,74,74,75,75,75,76,76,76,77,77,77
	dc.w	78,78,78,78,78,79,79,79,79,79,79,79,79,79,79,80,79,79,79
	dc.w	79,79,79,79,79,79,79,78,78,78,78,78,77,77,77,76,76,76,75
	dc.w	75,75,74,74,73,73,72,72,71,71,70,70,69,69,68,67,67,66,65
	dc.w	64,64,63,62,62,61,60,60,59,58,57,57,56,55,54,53,53,52,51
	dc.w	50,49,49,48,47,46,45,45,44,43,42,41,40,40,40,39,38,37,36
	dc.w	35,35,34,33,32,31,31,30,29,28,27,27,26,25,24,23,23,22,21
	dc.w	20,20,19,18,18,17,16,16,15,14,14,13,13,12,11,10,10,9,9,8
	dc.w	8,7,7,6,6,5,5,5,4,4,4,3,3,3,2,2,2,2,2,1,1,1,1,1,1,1,1,1
	dc.w	1,0,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,4,4,4,5,5,5,6,6
	dc.w	7,7,8,8,9,9,10,10,11,11,12,13,13,14,14,15,16,16,17,18,18
	dc.w	19,20,20,21,22,23,23,24,25,26,27,27,28,29,30,31,31,32,33
	dc.w	34,35,35,36,37,38,39,40,40
MotionTableYEnd:

OnePixelPointer:
	dc.l	OnePixelMotionTable

OnePixelMotionTable:
	dc.w	20,20,19,18,18,17,16,16,15,14,14,13,13,12,11,10,10,9,9,8
	dc.w	8,7,7,6,6,5,5,5,4,4,4,3,3,3,2,2,2,2,2,1,1,1,1,1,1,1,1,1
	dc.w	1,0,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,3,3,3,4,4,4,5,5,5,6,6
	dc.w	7,7,8,8,9,9,10,10,11,11,12,13,13,14,14,15,16,16,17,18,18
	dc.w	19,20,20
OnePixelMotionTableEnd:

;; - Table Construction Kit -

BuildRGBTables:
	lea	SimpleRedTable(pc),a0
	lea	RedTable,a1

BuildRedTableLoop1:
	moveq	#RedDesignStep,d0

BuildRedTableLoop2:
	move.w	(a0),(a1)+

	cmp.l	#RedTableEnd,a1
	beq.s	RedEnd

	dbra	d0,BuildRedTableLoop2

	addq.l	#2,a0
	cmp.l	#SimpleRedTableEnd,a0
	bne.s	BuildRedTableLoop1

	lea	SimpleRedTable(pc),a0
	bra.s	BuildRedTableLoop1

RedEnd:
	lea	SimpleGreenTable(pc),a0
	lea	GreenTable,a1

BuildGreenTableLoop1:
	moveq	#GreenDesignStep,d0

BuildGreenTableLoop2:
	move.w	(a0),(a1)+

	cmp.l	#GreenTableEnd,a1
	beq.s	GreenEnd

	dbra	d0,BuildGreenTableLoop2

	addq.l	#2,a0
	cmp.l	#SimpleGreenTableEnd,a0
	bne.s	BuildGreenTableLoop1

	lea	SimpleGreenTable(pc),a0
	bra.s	BuildGreenTableLoop1

GreenEnd:
	lea	SimpleBlueTable(pc),a0
	lea	BlueTable,a1

BuildBlueTableLoop1:
	moveq	#BlueDesignStep,d0

BuildBlueTableLoop2:
	move.w	(a0),(a1)+

	cmp.l	#BlueTableEnd,a1
	beq.s	BlueEnd

	dbra	d0,BuildBlueTableLoop2

	addq.l	#2,a0
	cmp.l	#SimpleBlueTableEnd,a0
	bne.s	BuildBlueTableLoop1

	lea	SimpleBlueTable(pc),a0
	bra.s	BuildBlueTableLoop1

BlueEnd:
	rts

SimpleRedTable:
	dc.w	$0000,$0100,$0200,$0300,$0400,$0500,$0600,$0700
	dc.w	$0800,$0900,$0a00,$0b00,$0c00,$0d00,$0e00,$0f00
	dc.w	$0e00,$0d00,$0c00,$0b00,$0a00,$0900,$0800,$0700
	dc.w	$0600,$0500,$0400,$0300,$0200,$0100
SimpleRedTableEnd:

SimpleGreenTable:
	dc.w	$0000,$0010,$0020,$0030,$0040,$0050,$0060,$0070
	dc.w	$0080,$0090,$00a0,$00b0,$00c0,$00d0,$00e0,$00f0
	dc.w	$00e0,$00d0,$00c0,$00b0,$00a0,$0090,$0080,$0070
	dc.w	$0060,$0050,$0040,$0030,$0020,$0010
SimpleGreenTableEnd:

SimpleBlueTable:
	dc.w	$0000,$0001,$0002,$0003,$0004,$0005,$0006,$0007
	dc.w	$0008,$0009,$000a,$000b,$000c,$000d,$000e,$000f
	dc.w	$000e,$000d,$000c,$000b,$000a,$0009,$0008,$0007
	dc.w	$0006,$0005,$0004,$0003,$0002,$0001
SimpleBlueTableEnd:

;; - Save & Restore All Routine -

	INCLUDE	TFTSD:Help/Save&RestoreAll.S

;
;; ---- COPPERLIST ----
;

CopperList:
	dc.w	$0100,$0000
	dc.w	$008e,$2971,$0090,$29e1
	dc.w	$0092,$0030,$0094,$00d8
	dc.w	$0102,$0000,$0104,$0000
	dc.w	$0108,0,$010a,0
	dc.w	$0180,$0000

	dc.b	PlasmaStartLine-2,$09
	dc.w	$fffe

PlasmaBpl:
	dc.w	$00e0,$0000,$00e2,$0000

	dc.w	$0108,-44

	dc.b	PlasmaStartLine-1,$e1
	dc.w	$fffe

	dc.w	$0100,$1200

PlasmaCop:

CurrentLine:	set	PlasmaStartLine

	REPT	PlasmaHeight

	dc.b	CurrentLine,$19-4
	dc.w	$fffe
	dc.w	$0102,$0000

	REPT	(416/8/2)

	dc.l	$01800000
	dc.l	$01820000

	ENDR

CurrentLine:	set	CurrentLine+1

	ENDR

	dc.b	PlasmaStartLine+PlasmaHeight,$09
	dc.w	$fffe

	dc.w	$0100,$0000
	dc.w	$0180,$0000

	dc.w	$009c,$8010

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

RedTable:	blk.w	PlasmaHeight+Ampli*2
RedTableEnd:

GreenTable:	blk.w	PlasmaHeight+Ampli*2
GreenTableEnd:

BlueTable:	blk.w	PlasmaHeight+Ampli*2
BlueTableEnd:

Plasma8Design:	blk.w	22,$f00f
