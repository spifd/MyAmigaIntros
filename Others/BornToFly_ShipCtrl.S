; ******************************
; *                            *
; * Title: Born To Fly         *
; *                            *
; * Coder: Spirit & Tex        *
; * Date : April 1990          *
; *                            *
; * Infos: Shoot'em up Scroll  *
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

PHeight		= 10		; Background Pieces Height

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
	move.w	#%1000001111000000,$096(a5)
	move.w	#$7fff,$09a(a5)
	move.w	#%1100000000100000,$09a(a5)

	move.l	#CopperList,$080(a5)
	clr.w	$088(a5)

	ClrMem	BackgrdBpl+(44*(256+PHeight)*0),22,(256+PHeight)*2
	ClrMem	BackgrdBpl+(44*(256+PHeight)*2),22,(256+PHeight)*2
	ClrMem	BackgrdBpl+(44*(256+PHeight)*4),22,(256+PHeight)*2
	ClrMem	BackgrdBpl+(44*(256+PHeight)*6),22,(256+PHeight)*2
	ClrMem	BackgrdBpl+(44*(256+PHeight)*8),22,(256+PHeight)*2

	bsr	InitColorsTable
	bsr	CodeMap

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

	bsr	BackgroundScroll
	bsr	ShipCtrl

GoOnIrq3:
	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Code Map with Offset -

CodeMap:
	lea	Map,a0

CodeMapLoop:
	move.w	(a0),d0
	divu	#20,d0
	move.w	d0,d1
	swap	d0
	and.l	#$0000ffff,d0
	add.l	d0,d0
	mulu	#(40*5*PHeight),d1
	add.l	d1,d0
	move.w	d0,(a0)+
	cmp.l	#MapEnd,a0
	bne.s	CodeMapLoop
	rts

;; - Ship Control Routine -

ShipCtrl:
	move.l	ScreenAddress(pc),d0
	add.l	#44*5*100+22,d0
	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.l	#$09f00000,BltCon0(a5)
	move.l	#(2^16)*0+(22-3)*2,BltAmod(a5)
	move.l	#ShipPic,BltApth(a5)
	move.l	d0,BltDpth(a5)
	move.w	#64*(30*5)+3,BltSize(a5)
	rts

;; - Background Scroll Routine -

BackgroundScroll:
	lea	ScreenPointers(pc),a0
	move.l	ScreenAddress(pc),d0
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
	swap	d0
	add.l	d1,d0
	move.w	d0,30(a0)
	swap	d0
	move.w	d0,26(a0)
	swap	d0
	add.l	d1,d0
	move.w	d0,38(a0)
	swap	d0
	move.w	d0,34(a0)
	swap	d0
	add.l	d1,d0

	sub.l	#44*5,ScreenAddress
	cmp.l	#BackgrdBpl,ScreenAddress
	bne.s	LinesScrolled

	move.l	#BackgrdBpl+[44*5*(1+(256+PHeight)-1)],ScreenAddress
	move.l	#BackgrdBpl,d4
	move.l	#BackgrdBpl+(44*5*(256+PHeight)),d5
	bra.s	PrintMapLine

LinesScrolled:
	subq.b	#1,HowManyLines
	beq.s	WhereToPut
	rts

WhereToPut:
	move.l	ScreenAddress(pc),d4
	move.l	d4,d5
	add.l	#(44*5*(256+PHeight)),d5

PrintMapLine:
	move.b	#PHeight,HowManyLines

InitBlitter:
	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.l	#$09f00000,BltCon0(a5)
	move.l	#(2^16)*[(20-1)*2]+(22-1)*2,BltAmod(a5)

	move.l	PiecePointer(pc),a0
	move.l	#MapPieces+$98,d1
	move.l	ScreenAddress(pc),d2
	sub.l	#(44*5*PHeight),d2
	moveq	#22-1,d3

PrintMapLineLoop:
	moveq	#0,d0
	move.w	(a0)+,d0
	add.l	d1,d0

	WaitBlitter
	move.l	d0,BltApth(a5)
	move.l	d2,BltDpth(a5)
	move.w	#64*(PHeight*5)+1,BltSize(a5)

	addq.l	#2,d2

	dbra	d3,PrintMapLineLoop

	add.l	#(22*2),PiecePointer
	cmp.l	#MapEnd,PiecePointer
	bne.s	CopyToScreen2

	move.l	#Map,PiecePointer

CopyToScreen2:
	WaitBlitter
	move.l	#0,BltAmod(a5)
	move.l	d4,BltApth(a5)
	move.l	d5,BltDpth(a5)
	move.w	#64*(PHeight*5)+22,BltSize(a5)
	rts

ScreenAddress:	dc.l	BackgrdBpl+(44*5)
PiecePointer:	dc.l	Map

Map:
		dc.w	000,001,002,003,004,005,006,007,008,009,010
		dc.w	011,012,013,014,015,016,017,018,019,020,021
		dc.w	100,101,102,103,104,105,106,107,108,109,110
		dc.w	111,112,113,114,115,116,117,118,119,120,121
MapEnd:

HowManyLines:	dc.b	0
		even

;; - Init Colors Table -

InitColorsTable:
	lea	MapPieces+$30,a0
	lea	ColorsTable+2(pc),a1
	moveq	#32-1,d2

ColorsInitLoop:
	clr.l	d0
	clr.l	d1
	move.b	(a0)+,d1
	lsl.w	#4,d1
	add.b	(a0)+,d1
	move.b	(a0)+,d0
	lsr.w	#4,d0
	add.l	d0,d1
	move.w	d1,(a1)
	addq.l	#4,a1

	dbra	d2,ColorsInitLoop
	rts

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
	dc.w	$0108,(44*4),$010a,(44*4)

ColorsTable:
	dc.w	$0180,$0000,$0182,$0000,$0184,$0000,$0186,$0000
	dc.w	$0188,$0000,$018a,$0000,$018c,$0000,$018e,$0000
	dc.w	$0190,$0000,$0192,$0000,$0194,$0000,$0196,$0000
	dc.w	$0198,$0000,$019a,$0000,$019c,$0000,$019e,$0000
	dc.w	$01a0,$0000,$01a2,$0000,$01a4,$0000,$01a6,$0000
	dc.w	$01a8,$0000,$01aa,$0000,$01ac,$0000,$01ae,$0000
	dc.w	$01b0,$0000,$01b2,$0000,$01b4,$0000,$01b6,$0000
	dc.w	$01b8,$0000,$01ba,$0000,$01bc,$0000,$01be,$0000

	dc.w	$2a09,$fffe

ScreenPointers:
	dc.w	$00e0,$0000,$00e2,$0000+(44*5)
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$00f0,$0000,$00f2,$0000

BackgroundStart:
	dc.w	$2b09,$fffe,$0100,$5200

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

ShipPic:	incbin	GDD:Pictures/WingsPlane
MapPieces:	incbin	GDD:Pictures/WingsPieces
BackgrdBpl:	ds.b	[(352*(256+PHeight)/8)*2]
