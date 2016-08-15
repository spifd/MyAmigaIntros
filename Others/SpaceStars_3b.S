; ******************************
; *                            *
; * Title: Space Stars         *
; *                            *
; * Coder: Spirit              *
; * Date : June 1991           *
; *                            *
; * Infos: 3D Stars            *
; *        3 Bitplanes         *
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

ScreenHeight	= 200
Stars3DLine	= $2c

Zmax		= 2047	; Must be 2^x-1

StarsXStep	= 0
StarsYStep	= 0
StarsZStep	= -10

ColorZ1		= 300
ColorZ2		= 500
ColorZ3		= 700
ColorZ4		= 900
ColorZ5		= 1100
ColorZ6		= 1300
ColorZ7		= 1500

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
	move.w	#%1000011111000000,$096(a5)
	move.w	#$7fff,$09a(a5)
	move.w	#%1100000000100000,$09a(a5)

	move.l	#CopperList,$080(a5)
	clr.w	$088(a5)

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

	btst	#10,$dff016
	beq.s	GoOnIrq3

	bsr	MoveInSpace

GoOnIrq3:
	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - 3D Space Stars Routine -

MoveInSpace:
	lea	BStars(pc),a0
	move.l	(a0),a1
	move.l	4(a0),d0
	move.l	d0,(a0)
	move.l	a1,4(a0)

InitScreenPointers:
	lea	ScreenPointers,a0
	moveq	#44,d1
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	d1,d0
	move.w	d0,14(a0)
	swap	d0
	move.w	d0,10(a0)
	swap	d0
	add.l	d1,d0
	move.w	d0,22(a0)
	swap	d0
	move.w	d0,18(a0)

	WaitBlitter
	move.l	#$01000000,BltCon0(a5)
	move.w	#0,BltDmod(a5)
	move.l	a1,BltDpth(a5)
	move.w	#64*(ScreenHeight*3)+22,BltSize(a5)
	WaitBlitter

Project3DStars:
	lea	StarsCoord3D(pc),a0

Project3DStarsLoop:
	movem.w	(a0)+,d0/d1/d2

ObsPosition:
	sub.w	#0,d0
	sub.w	#0,d1
	sub.w	#0,d2

StarTo2D:
	asl.w	#8,d0
	asl.w	#8,d1
	ext.l	d0
	ext.l	d1

ZoomValue:
	move.w	#Zmax,d3
	sub.w	d2,d3
	beq	TestStarsCoord3DEnd

	cmp.w	#Zmax,d3
	ble.s	Proj2D

	sub.w	#Zmax,d3

Proj2D:
	divs	d3,d0
	divs	d3,d1

XClipping:
	add.w	#(352/2),d0
	bmi	TestStarsCoord3DEnd

	cmp.w	#352,d0
	bhi.s	TestStarsCoord3DEnd

YClipping:
	add.w	#(ScreenHeight/2),d1
	bmi.s	TestStarsCoord3DEnd

	cmp.w	#ScreenHeight,d1
	bhi.s	TestStarsCoord3DEnd

StarAddress:
	mulu	#44*3,d1
	move.l	a1,a2
	lea	(a2,d1.w),a2
	move.b	d0,d1
	lsr.w	#3,d0
	lea	(a2,d0.w),a2
	and.b	#%00000111,d1
	not.b	d1

ZColor:
	cmp.w	#ColorZ1,d3
	bhi.s	NoColor1

	bset	d1,(a2)
	bra.s	TestStarsCoord3DEnd

NoColor1:
	cmp.w	#ColorZ2,d3
	bhi.s	NoColor2

	bset	d1,44(a2)
	bra.s	TestStarsCoord3DEnd

NoColor2:
	cmp.w	#ColorZ3,d3
	bhi.s	NoColor3

	bset	d1,(a2)
	bset	d1,44(a2)
	bra.s	TestStarsCoord3DEnd

NoColor3:
	cmp.w	#ColorZ4,d3
	bhi.s	NoColor4

	bset	d1,44*2(a2)
	bra.s	TestStarsCoord3DEnd

NoColor4:
	cmp.w	#ColorZ5,d3
	bhi.s	NoColor5

	bset	d1,(a2)
	bset	d1,44*2(a2)
	bra.s	TestStarsCoord3DEnd

NoColor5:
	cmp.w	#ColorZ6,d3
	bhi.s	NoColor6

	bset	d1,44(a2)
	bset	d1,44*2(a2)
	bra.s	TestStarsCoord3DEnd

NoColor6:
	bset	d1,(a2)
	bset	d1,44(a2)
	bset	d1,44*2(a2)

TestStarsCoord3DEnd:
	cmp.w	#$ffff,(a0)
	bne.w	Project3DStarsLoop

	lea	ObsPosition(pc),a0

	add.w	#StarsXStep,2(a0)
	and.w	#Zmax,2(a0)

	add.w	#StarsYStep,6(a0)
	and.w	#Zmax,6(a0)

	add.w	#StarsZStep,10(a0)
	and.w	#Zmax,10(a0)

	rts

BStars:	dc.l	BStars1,BStars2

StarsCoord3D:
	dc.w	-120,0100,2047
	dc.w	1120,0100,1947
	dc.w	-120,-120,1847
	dc.w	1120,-100,1747
	dc.w	-100,0060,0700
	dc.w	1100,0060,0800
	dc.w	-100,-070,0900
	dc.w	1110,-060,1000
	dc.w	-060,0030,0250
	dc.w	0060,0040,1400
	dc.w	-060,-040,0460
	dc.w	0060,-040,0120
	dc.w	-160,0060,0300
	dc.w	-120,0100,1047
	dc.w	0120,0100,0947
	dc.w	-120,-120,0847
	dc.w	0120,-100,0747
	dc.w	-100,0060,1700
	dc.w	0100,0060,1800
	dc.w	-100,-070,1900
	dc.w	0110,-060,2000
	dc.w	-060,0030,1250
	dc.w	0060,0040,0400
	dc.w	-060,-040,1460
	dc.w	0060,-040,1120
	dc.w	-160,0060,1300
	dc.w	-020,0120,2047
	dc.w	0020,0110,1947
	dc.w	-020,-100,1847
	dc.w	0020,-120,1747
	dc.w	-000,0070,0700
	dc.w	0000,0120,0800
	dc.w	-000,-070,0900
	dc.w	0010,-060,1000
	dc.w	-160,0030,0250
	dc.w	0160,0040,1400
	dc.w	-160,-040,0460
	dc.w	0160,-040,0120
	dc.w	-060,0060,0300
	dc.w	-020,0100,1047
	dc.w	0020,0100,0947
	dc.w	-020,-120,0847
	dc.w	0020,-100,0747
	dc.w	-000,0060,1700
	dc.w	0000,0060,1800
	dc.w	-000,-070,1900
	dc.w	0010,-060,2000
	dc.w	-160,0030,1250
	dc.w	0160,0040,0400
	dc.w	-160,-040,1460
	dc.w	0160,-040,1120
	dc.w	-060,0060,1300

	dc.w	-020,0920,2047
	dc.w	2020,1110,1947
	dc.w	-920,-500,1847
	dc.w	1020,-620,1747
	dc.w	-800,1070,0700
	dc.w	0000,1120,0800
	dc.w	-700,-070,0900
	dc.w	0010,-060,1000
	dc.w	-660,0030,0250
	dc.w	1160,0040,1400
	dc.w	-160,-840,0460
	dc.w	1160,-040,0120
	dc.w	-860,0060,0300
	dc.w	-820,0100,1047
	dc.w	2020,0100,0947
	dc.w	-520,-120,0847
	dc.w	2020,-100,0747
	dc.w	-780,0060,1700
	dc.w	2000,0060,1800
	dc.w	-000,-070,1900
	dc.w	0910,-060,2000
	dc.w	-360,0030,1250
	dc.w	1160,0040,0400
	dc.w	-560,-040,1460
	dc.w	1160,-040,1120
	dc.w	-460,0060,1300

	dc.w	$ffff

;; - Save & Restore All Routine -

	INCLUDE	TFTSD:Help/Save&RestoreAll.S

;
;; ---- COPPERLIST ----
;

	SECTION DATA_C

CopperList:
	dc.w	$0100,$0000
	dc.w	$008e,$2971,$0090,$29e1
	dc.w	$0092,$0030,$0094,$00d8
	dc.w	$0102,$0000,$0104,$0000
	dc.w	$0108,44*2,$010a,44*2

	dc.w	$0180,$0000,$0182,$0fff,$0184,$0ddd,$0186,$0bbb
	dc.w	$0188,$0999,$018a,$0777,$018c,$0555,$018e,$0222

	dc.w	$2b09,$fffe

ScreenPointers:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000

	dc.b	Stars3DLine,$09
	dc.w	$fffe
	dc.w	$0100,$3200

	dc.b	Stars3DLine+ScreenHeight,$09
	dc.w	$fffe
	dc.w	$0100,$0000

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

BStars1:	ds.b	((352*ScreenHeight/8)*3)
BStars2:	ds.b	((352*ScreenHeight/8)*3)
