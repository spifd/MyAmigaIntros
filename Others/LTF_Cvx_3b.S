; ******************************
; *                            *
; * Title: Licence To Fill     *
; *                            *
; * Coder: Spirit              *
; * Date : April 1991          *
; *                            *
; * Infos: 3D Convex Object    *
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

ScreenWidth	= 11
ScreenHeight	= 180
LineStart3D	= $2c

ZoomValueStart	= 270
AlphaStep	= 20
BetaStep	= 10
GamaStep	= 20

;
;; ---- MACROS ----
;

;; - Wait Blitter Macro -

WaitBlitter:	MACRO
WaitBlitterLoop\@:
	btst	#14,$002(a5)
	bne.s	WaitBlitterLoop\@
		ENDM

;; - Clear Mem Macro -

; Syntax = ClrMem Address,Width,Height

ClrMem:		MACRO
	WaitBlitter
	move.l	#$01000000,BltCon0(a5)
	move.w	#0,BltDmod(a5)
	move.l	#\1,BltDpth(a5)
	move.w	#64*\3+\2,BltSize(a5)
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

	ClrMem	BGraph1,22,(ScreenHeight+1)*3
	ClrMem	BGraph2,22,(ScreenHeight+1)*3
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
	lea	Faces,a0

TransformFacesOffsetLoop1:
	moveq	#0,d0
	move.b	(a0)+,d0
	subq.b	#1,d0

TransformFacesOffsetLoop2:
	move.b	(a0),d1
	lsl.b	#2,d1
	move.b	d1,(a0)+
	dbra	d0,TransformFacesOffsetLoop2

	addq.l	#1,a0
	cmp.b	#$ff,(a0)
	bne.s	TransformFacesOffsetLoop1
	rts

;; - 3D Object Motion Routine -

MoveObject:
	lea	Screenpointers(pc),a0
	move.l	CurrentScreen+4,d0
	add.l	#(44*3)-(((22-ScreenWidth)/2)*2),d0
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

ClearCurrentBGraph:
	WaitBlitter
	move.l	#$01000000,BltCon0(a5)
	move.w	#(22-ScreenWidth)*2,BltDmod(a5)
	move.l	CurrentScreen,BltDpth(a5)
	move.w	#64*(ScreenHeight*3)+ScreenWidth,BltSize(a5)

DoubleBuffering:
	lea	CurrentScreen(pc),a0
	move.l	(a0),a2
	move.l	4(a0),(a0)
	move.l	a2,4(a0)

Project3D:
	move.l	#$7fff0000,XMin
	lea	SinusTable(pc),a0
	lea	CosinusTable(pc),a1
	lea	Coord3D(pc),a2
	lea	Coord2D(pc),a3

Project3DLoop:
	movem.w	(a2)+,d0/d1/d2

RotateOnZ:
	move.w	d0,d3
	move.w	d1,d4

Alpha:
	move.w	#0,d5
	muls	(a0,d5.w),d0
	muls	(a1,d5.w),d1
	sub.l	d1,d0
	add.l	d0,d0
	swap	d0

	muls	(a1,d5.w),d3
	muls	(a0,d5.w),d4
	add.l	d3,d4
	add.l	d4,d4
	swap	d4
	move.w	d4,d1

RotateOnY:
	move.w	d0,d3
	move.w	d2,d4

Beta:
	move.w	#0,d5
	muls	(a0,d5.w),d0
	muls	(a1,d5.w),d2
	sub.l	d2,d0
	asr.l	#7,d0

	muls	(a1,d5.w),d3
	muls	(a0,d5.w),d4
	add.l	d3,d4
	add.l	d4,d4
	swap	d4
	move.w	d4,d2

RotateOnX:
	move.w	d1,d3
	move.w	d2,d4

Gama:
	move.w	#0,d5
	muls	(a0,d5.w),d1
	muls	(a1,d5.w),d2
	sub.l	d2,d1
	asr.l	#7,d1

	muls	(a1,d5.w),d3
	muls	(a0,d5.w),d4
	add.l	d3,d4
	add.l	d4,d4
	swap	d4
	move.w	d4,d2

ZoomValue:
	move.w	#ZoomValueStart,d3
	sub.w	d2,d3

To2D:
	divs	d3,d0
	divs	d3,d1

	add.w	#(ScreenWidth*16/2),d0
	add.w	#(ScreenHeight/2),d1

	move.w	d0,(a3)+
	move.w	d1,(a3)+

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
	cmp.w	#$ffff,(a2)
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
	move.w	#44*3,BltCmod(a5)
	move.w	#44*3,BltDmod(a5)

	lea	Coord2D(pc),a0
	lea	Faces(pc),a3

TraceObjectLoop:
	moveq	#0,d0
	moveq	#0,d6
	move.b	(a3)+,d6
	move.b	(a3,d6.w),d0

	move.l	CurrentScreen+4(pc),a2
	add.l	d0,a2

	subq.b	#2,d6
	cmp.b	#$ff-2,d6
	bne.s	HiddenFaces

FillObject:
	WaitBlitter
	move.l	#2^16*[(22-ScreenWidth)*2]+(22-ScreenWidth)*2,BltAmod(a5)
	move.l	CurrentScreen+4(pc),a2
	lea	(352*ScreenHeight*3/8)-2-((22-ScreenWidth)*2)(a2),a2
	move.l	a2,BltApth(a5)
	move.l	a2,BltDpth(a5)
	move.l	#$09f00012,BltCon0(a5)
	move.w	#64*(ScreenHeight*3)+ScreenWidth,BltSize(a5)
	rts

HiddenFaces:
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	move.b	(a3),d0
	move.b	1(a3),d1
	move.b	2(a3),d2

	move.w	(a0,d1.w),d3	; Xb
	sub.w	(a0,d0.w),d3	; Xb-Xa

	move.w	2(a0,d2.w),d5	; Yc
	sub.w	2(a0,d0.w),d5	; Yc-Ya

	muls	d3,d5

	move.w	(a0,d2.w),d3	; Xc
	sub.w	(a0,d0.w),d3	; Xc-Xa

	move.w	2(a0,d1.w),d4	; Yb
	sub.w	2(a0,d0.w),d4	; Yb-Ya

	muls	d3,d4

	sub.l	d4,d5
	bge.s	DrawFacesLoop

	addq.b	#2-1,d6
	lea	2(a3,d6),a3
	bra	TraceObjectLoop

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
	mulu	#44*3,d1
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
	addq.l	#2,a3
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

Coord3D:
	dc.w	-50,050,050
	dc.w	-50,-50,050
	dc.w	050,-50,050
	dc.w	050,050,050

	dc.w	-50,050,-50
	dc.w	-50,-50,-50
	dc.w	050,-50,-50
	dc.w	050,050,-50
Coord3DEnd:
	dc.w	$ffff

XMin:	dc.w	$7fff
XMax:	dc.w	0

Coord2D:
	blk.w	[(Coord3DEnd-Coord3D)/2/3]*2,0

Faces:
	dc.b	5
	dc.b	0,1,2,3,0
	dc.b	0

	dc.b	5
	dc.b	5,4,7,6,5
	dc.b	0

	dc.b	5
	dc.b	4,5,1,0,4
	dc.b	44

	dc.b	5
	dc.b	3,2,6,7,3
	dc.b	44

	dc.b	5
	dc.b	4,0,3,7,4
	dc.b	44*2

	dc.b	5
	dc.b	1,5,6,2,1
	dc.b	44*2

	dc.b	$ff
	even

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
	dc.w	$0102,$0000,$0104,$0000
	dc.w	$0108,44*2,$010a,44*2

	dc.w	$0180,$0000,$0182,$0fff,$0184,$0f00,$0186,$000f
	dc.w	$0188,$00f0,$018a,$0ff0,$018c,$00ff,$018e,$0f0f

	dc.w	$2b09,$fffe

ScreenPointers:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000

	dc.b	LineStart3D,$09
	dc.w	$fffe
	dc.w	$0100,$3200

	dc.b	LineStart3D+ScreenHeight,$09
	dc.w	$fffe
	dc.w	$0100,$0000

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

BGraph1:	ds.l	[(352*(ScreenHeight+1)/8)*3]
BGraph2:	ds.l	[(352*(ScreenHeight+1)/8)*3]
