; ******************************
; *                            *
; * Title: Plasma              *
; *                            *
; * Coder: Spirit              *
; * Date : May 1991            *
; *                            *
; * Infos: Simple Plasma       *
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

ColorYStep1	= 2
ColorYStep2	= 5

ColorDesignStep	= 2

OnePixelStep1	= 3
OnePixelStep2	= 8

PlasmaStartLine	= $40
PlasmaHeight	= 180
Ampli		= 80

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

	bsr	BuildRGBTable
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
	move.w	#%000000000100000,$09c(a5)

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
	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.l	#[(416/8)*2+4-1]*2,BltAmod(a5)

	move.l	ColorPointerY(pc),a0

	moveq	#(416/8)-1,d0
	lea	PlasmaCop+10(pc),a6

PlasmaLoop:
	WaitBlitter
	move.l	#$09f00000,BltCon0(a5)

	move.w	(a0),d1
	add.w	d1,d1
	lea	ColorTable,a3
	lea	(a3,d1.w),a3
	move.l	a3,BltApth(a5)

	move.l	a6,BltDpth(a5)

	move.w	#64*PlasmaHeight+1,BltSize(a5)

ColorCtrl:
	add.l	#2*ColorYStep2,a0
	cmp.l	#MotionTableYEnd,a0
	blt.s	GoOnPlasmaLoop

	sub.l	#(MotionTableYEnd-MotionTableY),a0

GoOnPlasmaLoop:
	addq.l	#4,a6
	dbra	d0,PlasmaLoop

	lea	ColorPointerY(pc),a0
	add.l	#2*ColorYStep1,(a0)
	cmp.l	#MotionTableYEnd,(a0)
	blt.s	NoColorMoreY

	sub.l	#(MotionTableYEnd-MotionTableY),(a0)

NoColorMoreY:
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

ColorPointerY:	dc.l	MotionTableY

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
	incbin	TFTSD:Datas/SinTable_A30_L180.b
OnePixelMotionTableEnd:

;; - Table Construction Kit -

BuildRGBTable:
	lea	SimpleColorTable(pc),a0
	lea	ColorTable,a1

BuildColorTableLoop1:
	moveq	#ColorDesignStep,d0

BuildColorTableLoop2:
	move.w	(a0),(a1)+

	cmp.l	#ColorTableEnd,a1
	beq.s	ColorEnd

	dbra	d0,BuildColorTableLoop2

	addq.l	#2,a0
	cmp.l	#SimpleColorTableEnd,a0
	bne.s	BuildColorTableLoop1

	lea	SimpleColorTable(pc),a0
	bra.s	BuildColorTableLoop1

ColorEnd:
	rts

SimpleColorTable:
	dc.w	$0000,$0001,$0002,$0003,$0004,$0005,$0006,$0007
	dc.w	$0008,$0009,$000a,$000b,$000c,$000d,$000e,$000f
	dc.w	$011f,$022f,$033f,$044f,$055f,$066f,$077f,$088f
	dc.w	$099f,$0aaf,$0bbf,$0ccf,$0ddf,$0eef,$0fff
	dc.w	$0eee,$0ddd,$0ccc,$0bbb,$0aaa,$0999,$0888
	dc.w	$0777,$0666,$0555,$0444,$0333,$0222,$0111
SimpleColorTableEnd:

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

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

Plasma8Design:	blk.w	22,$f00f

ColorTable:	ds.w	PlasmaHeight+Ampli
ColorTableEnd:
