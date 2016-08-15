; ******************************
; *                            *
; * Title: 3D Logo             *
; *                            *
; * Coder: Spirit              *
; * Date : May 1991            *
; *                            *
; * Infos: Simple Logo         *
; *        Rotating in Space   *
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

ScreenWidth	= 20
ScreenHeight	= 250
LineStart3D	= $2c

ZoomValueStart	= 270
AlphaStep	= 20
BetaStep	= 19
GamaStep	= 22

HDec		= 1
VDec		= 1

;
;; ---- MACROS ----
;

;; - Clear Mem Macro -

; Syntax = ClrMem Address,Width,Height

ClrMem:		MACRO
	WaitBlitter
	move.l	#$01000000,BltCon0(a5)
	move.w	#0,BltDmod(a5)
	move.l	#\1,BltDpth(a5)
	move.w	#64*\3+\2,BltSize(a5)
		ENDM

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

	ClrMem	BGraph1,22,ScreenHeight+1
	ClrMem	BGraph2,22,ScreenHeight+1
	bsr	TransformFacesOffset

	move.l	#Irq3,$6c

LeftButtonTest:
	btst	#6,$bfe001
	bne.s	LeftButtonTest
	WaitBlitter

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

	bsr	MoveObject

GoOnIrq3:
	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Transform Faces Offset -

TransformFacesOffset:
	lea	Faces(pc),a0

TransformFacesOffsetLoop1:
	moveq	#0,d0
	move.b	(a0)+,d0
	subq.b	#1,d0

TransformFacesOffsetLoop2:
	move.b	(a0),d1
	lsl.b	#2,d1
	move.b	d1,(a0)+
	dbra	d0,TransformFacesOffsetLoop2

	cmp.b	#$ff,(a0)
	bne.s	TransformFacesOffsetLoop1
	rts

;; - 3D Object Motion Routine -

MoveObject:
	lea	Screenpointers(pc),a0
	move.l	CurrentScreen+4,d0
	add.l	#44-(((22-ScreenWidth)/2)*2),d0
	move.l	d0,d1
	add.l	#44*VDec,d1

	move.w	d0,6(a0)
	move.w	d1,14(a0)
	swap	d0
	swap	d1
	move.w	d0,2(a0)
	move.w	d1,10(a0)

ClearCurrentBGraph:
	WaitBlitter
	move.l	#$01000000,BltCon0(a5)
	move.w	#(22-ScreenWidth)*2,BltDmod(a5)
	move.l	CurrentScreen,BltDpth(a5)
	move.w	#64*ScreenHeight+ScreenWidth,BltSize(a5)

DoubleBuffering:
	lea	CurrentScreen(pc),a0
	move.l	(a0),a2
	move.l	4(a0),(a0)
	move.l	a2,4(a0)

Project3D:
	move.l	#$7fff0000,XMin
	lea	SinusTable(pc),a0
	lea	CosinusTable(pc),a1
	lea	SinCosABG(pc),a2
	lea	Matrice(pc),a3

Alpha:
	move.w	#0,d3
	move.w	(a0,d3.w),(a2)
	move.w	(a1,d3.w),2(a2)

Beta:
	move.w	#0,d3
	move.w	(a0,d3.w),4(a2)
	move.w	(a1,d3.w),6(a2)

Gama:
	move.w	#0,d3
	move.w	(a0,d3.w),8(a2)
	move.w	(a1,d3.w),10(a2)

	lea	Coord3D(pc),a0
	lea	Coord2D(pc),a1

Project3DLoop:
	movem.w	(a0)+,d0/d1/d2

	sub.w	#160,d0
	sub.w	#40,d1

MulsMatriceXYZ:

ZoomValue:
	move.w	#ZoomValueStart,d3
	sub.w	d2,d3

To2D:
	divs	d3,d0
	divs	d3,d1

	add.w	#(ScreenWidth*16/2),d0
	add.w	#(ScreenHeight/2),d1

	move.w	d0,(a1)+
	move.w	d1,(a1)+

TestXMin:
	lea	XMin(pc),a4
	cmp.w	(a4),d0
	bge.s	TestXmax

	move.w	d0,(a4)

TestXmax:
	lea	XMax(pc),a4
	cmp.w	(a4),d0
	ble.s	TestCoord3DEnd

	move.w	d0,(a4)

TestCoord3DEnd:
	cmp.w	#$ffff,(a0)
	bne	Project3DLoop

AlphaCtrl:
	add.w	#2*AlphaStep,Alpha+2
	and.w	#(4096*2-1),Alpha+2

BetaCtrl:
	add.w	#2*BetaStep,Beta+2
	and.w	#(4096*2-1),Beta+2

GamaCtrl:
	add.w	#2*GamaStep,Gama+2
	and.w	#(4096*2-1),Gama+2

TraceObject:
	WaitBlitter
	move.w	#$ffff,BltAfwm(a5)
	move.l	#2^16*($ffff)+%1000000000000000,BltBdat(a5)
	move.w	#44,BltCmod(a5)
	move.w	#44,BltDmod(a5)

	lea	Coord2D(pc),a0
	lea	Faces(pc),a3

TraceObjectLoop:
	moveq	#0,d0
	moveq	#0,d6
	move.b	(a3)+,d6

	move.l	CurrentScreen+4(pc),a2

	subq.b	#2,d6
	cmp.b	#$ff-2,d6
	bne.s	DrawFacesLoop

FillObject:
	WaitBlitter
	move.l	#2^16*[(22-ScreenWidth)*2]+(22-ScreenWidth)*2,BltAmod(a5)
	move.l	CurrentScreen+4(pc),a2
	lea	(352*ScreenHeight/8)-2-((22-ScreenWidth)*2)(a2),a2
	move.l	a2,BltApth(a5)
	move.l	a2,BltDpth(a5)
	move.l	#$09f00012,BltCon0(a5)
	move.w	#64*ScreenHeight+ScreenWidth,BltSize(a5)
	rts

DrawFacesLoop:
	moveq	#0,d0
	moveq	#0,d1
	move.b	(a3)+,d0
	move.b	(a3),d1
	move.w	2(a0,d1.w),d3
	move.w	(a0,d1.w),d2
	move.w	2(a0,d0.w),d1
	move.w	(a0,d0.w),d0

DrawLine:
	cmp.w	d1,d3
	bhi.s	FindOct

	exg	d0,d2
	exg	d1,d3

FindOct:
	sub.w	d1,d3
	sub.w	d0,d2
	bpl.s	Searching1

	neg.w	d2
	moveq	#11,d4
	cmp.w	d3,d2
	bcs.s	Searching2

	moveq	#23,d4
	exg	d2,d3
	bra.s	Searching2

Searching1:
	moveq	#3,d4
	cmp.w	d3,d2
	bcs.s	Searching2

	moveq	#19,d4
	exg	d2,d3

Searching2:
	add.w	d2,d2
	move.w	d2,d5
	sub.w	d3,d5
	cmp.w	d2,d3
	bcs.s	OctFound

	or.w	#%0000000001000000,d4

OctFound:
	move.l	a2,a1
	mulu	#44,d1
	add.l	d1,a1
	move.w	d0,d1
	lsr.w	#4,d1
	add.w	d1,d1
	add.w	d1,a1

	and.w	#$000f,d0
	add.w	d0,d0
	move.w	PlotTable(pc,d0.w),d1

	WaitBlitter
	eor.w	d1,(a1)

	lsl.b	#3,d0
	move.b	d0,InitBltCon0+2
	or.b	#$0b,InitBltCon0+2

BlitterInitLine:
	move.l	a1,BltCpth(a5)
	move.l	a1,BltDpth(a5)
	move.w	d5,BltAptl(a5)
	sub.w	d3,d5
	move.w	d5,BltAmod(a5)
	move.w	d2,BltBmod(a5)
	move.w	d4,BltCon1(a5)

InitBltCon0:
	move.w	#$005a,BltCon0(a5)

	addq.w	#1,d3
	lsl.w	#6,d3
	addq.w	#2,d3
	move.w	d3,BltSize(a5)

	dbra	d6,DrawFacesLoop

DrawFacesLoopEnd:
	addq.l	#1,a3
	bra	TraceObjectLoop

CurrentScreen:	dc.l	BGraph1,BGraph2

PlotTable:
	dc.w	%1000000000000000
	dc.w	%0100000000000000
	dc.w	%0010000000000000
	dc.w	%0001000000000000
	dc.w	%0000100000000000
	dc.w	%0000010000000000
	dc.w	%0000001000000000
	dc.w	%0000000100000000
	dc.w	%0000000010000000
	dc.w	%0000000001000000
	dc.w	%0000000000100000
	dc.w	%0000000000010000
	dc.w	%0000000000001000
	dc.w	%0000000000000100
	dc.w	%0000000000000010
	dc.w	%0000000000000001

AgileLogo:
	INCLUDE	TFTSD:Datas/AgileLogo1.S

XMin:	dc.w	$7fff
XMax:	dc.w	0

Coord2D:
	blk.w	[(Coord3DEnd-Coord3D)/2/3]*2,0

SinCosABG:	blk.w	6,0

SaveMuls:	dc.w	0

Matrice:
	blk.w	9,0

		; Column 1

		; sin Alpha * sin Beta
		; cos Alpha * sin Gama - sin Alpha * cos Beta * cos Gama
		; cos Alpha * cos Gama + sin Alpha * cos Beta * sin Gama
		;			 [__________________]

		; Column 2

		; - cos Alpha * sin Beta
		; sin Alpha * sin Gama + cos Alpha * cos Beta * cos Gama
		; sin Alpha * cos Gama - cos Alpha * cos Beta * sin Gama
		;			 [__________________]

		; Column 3
		
		; - cos Beta
		; - sin Beta * cos Gama
		; sin Beta * sin Gama

SinusTable:	incbin	TFTSD:Datas/SinCosTable_A32768_L4096.b
CosinusTable=SinusTable+(4096/4*2)

;; - Save & Restore All Routine -

	INCLUDE	TFTSD:Help/Save&RestoreAll.S

;
;; ---- COPPERLIST ----
;

CopperList:
	dc.w	$0100,$0000
	dc.w	$008e,$2971,$0090,$29e1
	dc.w	$0092,$0030,$0094,$00d8
	dc.w	$0104,$0000
	dc.w	$0108,0,$010a,0

	dc.w	$0180,$0000,$0182,$0888
	dc.w	$0184,$0ddd,$0186,$0aaa

BplCon1Value:
	dc.w	$0102,HDec

	dc.w	$2b09,$fffe

ScreenPointers:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000

	dc.b	LineStart3D,$09
	dc.w	$fffe
	dc.w	$0100,$2200

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

BGraph1:	ds.l	[(352*(ScreenHeight+1)/8)]
BGraph2:	ds.l	[(352*(ScreenHeight+1)/8)]
