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

	INCLUDE	SRC:ASM/Spirit/Help/BlitterRegisters.S

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

	SECTION CODE_C


Start:
	movem.l	d0-d7/a0-a6,-(sp)

	lea	$dff000,a5

	jsr	SaveAll

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
	jsr	RestoreAll

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

	cmp.b	#$ff,(a0)
	bne.s	TransformFacesOffsetLoop1
	rts

;; - 3D Object Motion Routine -

MoveObject:
	lea	ScreenPointers,a0
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
	lea	CurrentScreen,a0
	move.l	(a0),a2
	move.l	4(a0),(a0)
	move.l	a2,4(a0)

Project3D:
	move.l	#$7fff0000,XMin
	lea	SinusTable,a0
	lea	CosinusTable,a1
	lea	Coord3D,a2
	lea	Coord2D,a3

Project3DLoop:
	movem.w	(a2)+,d0/d1/d2

	sub.w	#160,d0
	sub.w	#40,d1

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
	lea	XMin,a4
	cmp.w	(a4),d0
	bge.s	TestXmax

	move.w	d0,(a4)

TestXmax:
	lea	XMax,a4
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
	move.w	#44,BltCmod(a5)
	move.w	#44,BltDmod(a5)

	lea	Coord2D,a0
	lea	Faces,a3

TraceObjectLoop:
	moveq	#0,d0
	moveq	#0,d6
	move.b	(a3)+,d6

	move.l	CurrentScreen+4,a2

	subq.b	#2,d6
	cmp.b	#$ff-2,d6
	bne.s	DrawFacesLoop

FillObject:
	WaitBlitter
	move.l	#2^16*((22-ScreenWidth)*2)+(22-ScreenWidth)*2,BltAmod(a5)
	move.l	CurrentScreen+4,a2
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

	SECTION DATA_C

AgileLogo:
Coord3D:
	dc.w	60,41,0		;  A (0)
	dc.w	73,54,0		;  B (1)
	dc.w	130,54,0	;  C (2)
	dc.w	117,41,0	;  D (3)

	dc.w	66,39,0		;  E (4)
	dc.w	100,5,0		;  F (5)
	dc.w	174,5,0		;  G (6)
	dc.w	174,16,0	;  H (7)
	dc.w	135,16,0	;  I (8)
	dc.w	127,24,0	;  J (9)
	dc.w	144,41,0	;  K (10)
	dc.w	154,41,0	;  L (11)
	dc.w	166,54,0	;  M (12)
	dc.w	142,54,0	;  N (13)
	dc.w	104,19,0	;  O (14)
	dc.w	84,39,0		;  P (15)

	dc.w	143,21,0	;  Q (16)
	dc.w	143,32,0	;  R (17)
	dc.w	150,32,0	;  S (18)  ???????
	dc.w	176,54,0	;  T (19)
	dc.w	176,62,0	;  U (20)
	dc.w	191,62,0	;  V (21)
	dc.w	191,1,0		;  W (22)
	dc.w	176,1,0		;  X (23)
	dc.w	176,41,0	;  Y (24)
	dc.w	165,30,0	;  Z (25)
	dc.w	165,21,0	; AA (26)

	dc.w	193,5,0		; AB (27)
	dc.w	193,54,0	; AC (28)
	dc.w	252,54,0	; AD (29)
	dc.w	252,47,0	; AE (30)
	dc.w	234,47,0	; AF (31)
	dc.w	226,29,0	; AG (32)
	dc.w	235,29,0	; AH (33)
	dc.w	235,18,0	; AI (34)
	dc.w	209,18,0	; AJ (35)
	dc.w	209,29,0	; AK (36)
	dc.w	222,42,0	; AL (37)
	dc.w	207,42,0	; AM (38)
	dc.w	207,5,0		; AN (39)

	dc.w	209,5,0		; AO (40)
	dc.w	209,16,0	; AP (41)
	dc.w	257,16,0	; AQ (42)
	dc.w	257,5,0		; AR (43)
Coord3DEnd:
	dc.w	$ffff

Faces:
	dc.b	5
	dc.b	0,1,2,3,0
	dc.b	13
	dc.b	4,5,6,7,8,9,10,11,12,13,14,15,4
	dc.b	12
	dc.b	16,17,18,19,20,21,22,23,24,25,26,16
	dc.b	14
	dc.b	27,28,29,30,31,32,33,34,35,36,37,38,39,27
	dc.b	5
	dc.b	40,41,42,43,40
	dc.b	$ff
	even


XMin:	dc.w	$7fff
XMax:	dc.w	0

Coord2D:
	dcb.w	5000,0

SinusTable:	incbin	SRC:ASM/Spirit/Datas/SinCosTable_A32768_L4096.b
CosinusTable=SinusTable+(4096/4*2)

;; - Save & Restore All Routine -

	INCLUDE	SRC:ASM/Spirit/Help/Save&RestoreAll.S

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

BGraph1:	ds.l	((352*(ScreenHeight+1)/8))
BGraph2:	ds.l	((352*(ScreenHeight+1)/8))
