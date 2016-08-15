; ******************************
; *                            *
; * Title: Special Effects     *
; *                            *
; * Coder: Spirit              *
; * Date : February 1991       *
; *                            *
; * Infos: 2 Playfields Move   *
; *        with Color Conflict *
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

PageWidth	= 64*8
PageHeight	= 50*8

P1MotionStepX	= 1
P1MotionStepY	= 1
P2MotionStepX	= 1
P2MotionStepY	= 1

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
	move.w	#%1000001110000000,$096(a5)
	move.w	#$7fff,$09a(a5)
	move.w	#%1100000000100000,$09a(a5)

	move.l	#CopperList,$080(a5)
	clr.w	$088(a5)

	lea	P1MotionTableY(pc),a0
	lea	P1MotionTableYEnd(pc),a1
	bsr	TransformMotionTable

	lea	P2MotionTableY(pc),a0
	lea	P2MotionTableYEnd(pc),a1
	bsr	TransformMotionTable

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

	bsr	SpecialEffects

GoOnIrq3:
	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Transform Vertical Motion Table in Address Offset -

; a0 = Motion Table Start
; a1 = Motion Table End

TransformMotionTable:
	move.w	(a0),d0
	mulu	#(PageWidth/8),d0
	move.w	d0,(a0)+
	cmp.l	a0,a1
	bne.s	TransformMotionTable
	rts

;; - Special Effects Routine -

SpecialEffects:
	movem.l	Empty,d0/d1/d2/d3/d4

YControl:
	move.l	P1MotionPointerY(pc),a0
	move.l	P2MotionPointerY(pc),a1

	move.w	(a0),d0
	move.w	(a1),d1

XControl:
	move.l	P1MotionPointerX(pc),a0
	move.w	(a0),d2

	move.w	d2,d3
	lsr.w	#3,d2
	and.w	#$fffe,d2
	add.l	d2,d0

	and.w	#$000f,d3
	move.w	#$000f,d4
	sub.w	d3,d4
	move.w	d4,BplCon1Value+2

	move.l	P2MotionPointerX(pc),a0
	move.w	(a0),d2

	move.w	d2,d3
	lsr.w	#3,d2
	and.w	#$fffe,d2
	add.l	d2,d1

	and.w	#$000f,d3
	move.w	#$000f,d4
	sub.w	d3,d4
	lsl.w	#4,d4
	or.w	d4,BplCon1Value+2

ChangeScreenPointers:
	move.l	d0,d2
	move.l	d1,d3
	add.l	#Page1,d0
	add.l	#Page1,d1
	add.l	#Page2,d2
	add.l	#Page2,d3

	move.w	d0,ScreenPointers+6
	move.w	d1,ScreenPointers+14
	swap	d0
	swap	d1
	move.w	d0,ScreenPointers+2
	move.w	d1,ScreenPointers+10

	move.w	d2,ScreenPointers+22
	move.w	d3,ScreenPointers+30
	swap	d2
	swap	d3
	move.w	d2,ScreenPointers+18
	move.w	d3,ScreenPointers+26

ControlMotionPointers:
	add.l	#2*P1MotionStepX,P1MotionPointerX
	add.l	#2*P1MotionStepY,P1MotionPointerY
	add.l	#2*P2MotionStepX,P2MotionPointerX
	add.l	#2*P2MotionStepY,P2MotionPointerY

P1X:
	cmp.l	#P1MotionTableXEnd,P1MotionPointerX
	blt.s	P1Y

	sub.l	#(P1MotionTableXEnd-P1MotionTableX),P1MotionPointerX

P1Y:
	cmp.l	#P1MotionTableYEnd,P1MotionPointerY
	blt.s	P2X

	sub.l	#(P1MotionTableYEnd-P1MotionTableY),P1MotionPointerY

P2X:
	cmp.l	#P2MotionTableXEnd,P2MotionPointerX
	blt.s	P2Y

	sub.l	#(P2MotionTableXEnd-P2MotionTableX),P2MotionPointerX

P2Y:
	cmp.l	#P2MotionTableYEnd,P2MotionPointerY
	blt.s	SpecialEffectsEnd

	sub.l	#(P2MotionTableYEnd-P2MotionTableY),P2MotionPointerY

SpecialEffectsEnd:
	rts

P1MotionPointerX:	dc.l	P1MotionTableX
P1MotionPointerY:	dc.l	P1MotionTableY
P2MotionPointerX:	dc.l	P2MotionTableX
P2MotionPointerY:	dc.l	P2MotionTableY
Empty:			dc.l	0,0,0,0,0

; Motion Tables for the two planes (see MotionSteps in R&V/Others)

; Plane 1 Motion Table X

P1MotionTableX:
	dc.w	40,38,36,34,32,30,28,26,24,22,20,19,17,15,14,12,11
	dc.w	9,8,7,6,5,4,3,2,2,1,0,0,0,0,0,0,0,0,0,1,1,2,2,3,4,5
	dc.w	6,7,8,10,11,12,14,16,17,19,21,22,24,26,28,30,32,34
	dc.w	36,38,40,42,44,46,48,50,52,54,55,57,59,61,62,64,66
	dc.w	67,68,70,71,72,73,74,75,76,77,78,78,79,79,79,79,79
	dc.w	79,79,79,78,78,77,77,76,75,74,73,72,70,69,68,66,65
	dc.w	63,62,60,58,56,54,53,51,49,47,45,43,41
P1MotionTableXEnd:

; Plane 1 Motion Table Y

P1MotionTableY:
	dc.w	99,96,93,90,87,84,81,78,75
	dc.w	72,69,66,63,61,58,55,53,50,47,45,42,40,38,35,33,31,29
	dc.w	26,24,23,21,19,17,15,14,12,11,10,8,7,6,5,4,3,2,2,1,1,0
	dc.w	0,0,0,0,0,0,0,0,0,1,1,2,2,3,4,5,6,7,8,9,11,12,14,15,17
	dc.w	19,20,22,24,26,28,30,33,35,37,40,42,44,47,50,52,55,58
	dc.w	60,63,66,69,72,74,77,80,83,86,89,92,95,98
P1MotionTableYEnd:

; Plane 2 Motion Table X

P2MotionTableX:
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
P2MotionTableXEnd:

; Plane 2 Motion Table Y

P2MotionTableY:
	dc.w	40,38,36,34,32,30,28,26,24,22,20,19,17,15,14,12,11
	dc.w	9,8,7,6,5,4,3,2,2,1,0,0,0,0,0,0,0,0,0,1,1,2,2,3,4,5
	dc.w	6,7,8,10,11,12,14,16,17,19,21,22,24,26,28,30,32,34
	dc.w	36,38,40,42,44,46,48,50,52,54,55,57,59,61,62,64,66
	dc.w	67,68,70,71,72,73,74,75,76,77,78,78,79,79,79,79,79
	dc.w	79,79,79,78,78,77,77,76,75,74,73,72,70,69,68,66,65
	dc.w	63,62,60,58,56,54,53,51,49,47,45,43,41
P2MotionTableYEnd:

;; - Save & Restore All Routine -

	INCLUDE	TFTSD:Help/Save&RestoreAll.S

;
;; ---- COPPERLIST ----
;

CopperList:
	dc.w	$0100,$0000
	dc.w	$008e,$2971,$0090,$29e1
	dc.w	$0092,$0028,$0094,$00d8
	dc.w	$0104,$0000

	dc.w	$0108,(PageWidth/8)-44-2,$010a,(PageWidth/8)-44-2

	dc.w	$0180,$0000

Colors:
	dc.w	$0182,$0490
	dc.w	$0184,$0490
	dc.w	$0186,$0940
	dc.w	$0188,$02c0
	dc.w	$018a,$0770
	dc.w	$018c,$0770
	dc.w	$018e,$0c20
	dc.w	$0190,$02c0
	dc.w	$0192,$0770
	dc.w	$0194,$0770
	dc.w	$0196,$0c20
	dc.w	$0198,$0490
	dc.w	$019a,$0940
	dc.w	$019c,$0940
	dc.w	$019e,$0f00

	dc.w	$2a09,$fffe

ScreenPointers:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000

BplCon1Value:
	dc.w	$0102,$0000

	dc.w	$3509,$fffe
	dc.w	$0180,$00f0
	dc.w	$0100,$4200

	dc.w	$ffe1,$fffe

	dc.w	$2009,$fffe
	dc.w	$0180,$0000
	dc.w	$0100,$0000

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

Page1:		incbin	TFTDD:Pictures/SpecialEffectsPage1
Page2:		incbin	TFTDD:Pictures/SpecialEffectsPage2
