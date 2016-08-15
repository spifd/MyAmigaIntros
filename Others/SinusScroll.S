; ******************************
; *                            *
; * Title: Sinus Scroll        *
; *                            *
; * Coder: Spirit              *
; * Date : February 1991       *
; *                            *
; * Infos: Sinus Scroll        *
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

FontHeight	= 16

MotionStep1	= 1
MotionStep2	= 1

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

	ClrMem	BScroll,23,FontHeight
	ClrMem	BSinus1,22,256*2

	move.l	#Message,CharPointer
	move.l	#MessageEnd,CharPointer+4
	bsr	TextCoder

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

	bsr	SinusScroll

GoOnIrq3:
	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Text Coder Routine -

; CharPointer   = Message Address 
; CharPointer+4 = Message End Address

TextCoder:
	lea	LettersAddresses(pc),a0
	moveq	#0,d0

PutLettersAddresses:
	move.l	d0,d1
	divu	#20,d1
	move.w	d1,d2
	mulu	#40*FontHeight,d2
	swap	d1
	add.l	d1,d1
	swap	d1
	clr.w	d1
	swap	d1
	add.l	d1,d2
	add.l	#Font,d2
	move.l	d2,(a0)+

	addq.l	#1,d0
	cmp.l	#(LettersEnd-Letters),d0
	bne.s	PutLettersAddresses

CodeMessageWithOffset:
	move.l	CharPointer(pc),a0
	lea	Letters(pc),a1

FindChar:
	moveq	#0,d1
	move.b	(a0),d0

FindCharLoop:
	cmp.b	(a1,d1),d0
	beq.s	PutLetterOffset
	addq.l	#1,d1
	bra.s	FindCharLoop

PutLetterOffset:
	lsl.l	#2,d1
	move.b	d1,(a0)+

FindCharEnd:
	cmp.l	CharPointer+4(pc),a0
	bne.s	FindChar
	rts

Letters:							; 64
	dc.b	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"			; Chars
	dc.b	"0123456789"					; Max.
	dc.b	"a-.:b/c,()!def?'%&gh=+* "
LettersEnd:
	even

LettersAddresses:
	blk.l	(LettersEnd-Letters),0

CharPointer:	dc.l	0,0

Message:
	dc.b	"SPIRIT IS PROUD TO PRESENT HIS FIRST SINUS SCROLL ...  "
MessageEnd:
	even

;; - Transform Vertical Motion Table in Offset Address -

TransformMotionTable:
	lea	MotionTable(pc),a0
	move.w	#(MotionTableEnd-MotionTable)/2-1,d1

TransformLoop:
	move.w	(a0),d0
	mulu	#44,d0
	move.w	d0,(a0)+
	dbra	d1,TransformLoop
	rts

;; - Sinus Scroll Routine -

SinusScroll:
	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.l	#$e9f00000,BltCon0(a5)
	move.l	#0,BltAmod(a5)
	move.l	#BScroll,BltApth(a5)
	move.l	#BScroll-2,BltDpth(a5)
	move.w	#64*(FontHeight+1)+23,BltSize(a5)

	subq.b	#1,ScrollCompt
	bne.s	SinusCtrl

TransferLetter:
	move.b	#8,ScrollCompt

	move.l	CharPointer(pc),a0
	lea	LettersAddresses(pc),a1
	moveq	#0,d1
	move.b	(a0),d1

	WaitBlitter
	move.w	#$09f0,BltCon0(a5)
	move.l	#2^16*[(20-1)*2]+(23-1)*2,BltAmod(a5)
	move.l	(a1,d1.w),BltApth(a5)
	move.l	#BScroll+44,BltDpth(a5)
	move.w	#64*(FontHeight)+1,BltSize(a5)

	addq.l	#1,CharPointer
	cmp.l	#MessageEnd,CharPointer
	bne.s	SinusCtrl

	move.l	#Message,CharPointer

SinusCtrl:
	move.l	BSinusAddress(pc),d2
	move.l	BSinusAddress+4(pc),d3

	move.l	d3,BSinusAddress
	move.l	d2,BSinusAddress+4

	lea	ScreenPointers,a0
	move.w	d3,6(a0)
	swap	d3
	move.w	d3,2(a0)
	swap	d3

SinusControlInit:
	lea	BScroll,a0
	move.l	MotionPointer(pc),a2
	move.w	#(22*16)-1,d0
	move.w	#%1000000000000000,d1

	WaitBlitter
	move.w	#$0100,BltCon0(a5)
	move.w	#0,BltDmod(a5)
	move.l	d2,BltDpth(a5)
	move.w	#64*256+22,BltSize(a5)

	WaitBlitter
	move.w	#$0dfc,BltCon0(a5)
	move.l	#2^16*[(23-1)*2]+(22-1)*2,BltAmod(a5)
	move.w	#[22-1]*2,BltBmod(a5)

SinusScrollLoop:
	move.l	d2,a3
	add.w	(a2),a3

	sub.l	#(2*MotionStep2),a2
	cmp.l	#MotionTable,a2
	bge.s	NoMotionTableStart

	add.l	#(MotionTableEnd-MotionTable),a2

NoMotionTableStart:
	WaitBlitter
	move.w	d1,BltAfwm(a5)
	move.l	a0,BltApth(a5)
	move.l	a3,BltBpth(a5)
	move.l	a3,BltDpth(a5)
	move.w	#64*(FontHeight)+1,BltSize(a5)

	ror.w	#1,d1
	cmp.w	#%1000000000000000,d1
	bne.s	SinusScrollLoopEnd

	addq.l	#2,a0
	addq.l	#2,d2

SinusScrollLoopEnd:
	dbra	d0,SinusScrollLoop

	add.l	#(2*MotionStep1),MotionPointer
	cmp.l	#MotionTableEnd,MotionPointer
	blt.s	SinusScrollEnd

	sub.l	#(MotionTableEnd-MotionTable),MotionPointer

SinusScrollEnd:
	rts

BSinusAddress:	dc.l	BSinus1,BSinus2

ScrollCompt:	dc.b	1
		even

MotionPointer:	dc.l	MotionTable

MotionTable:
	dc.w	140,138,136,134,132,130,128,126,124,122,120,119,117,115
	dc.w	114,112,111
	dc.w	109,108,107,106,105,104,103,102,102,101,100,100,100
	dc.w	100,100,100,100,100,100,101,101,102,102,103,104,105
	dc.w	106,107,108,110,111,112,114,116,117,119,121,122,124
	dc.w	126,128,130,132,134
	dc.w	136,138,140,142,144,146,148,150,152,154,155,157,159,161
	dc.w	162,164,166
	dc.w	167,168,170,171,172,173,174,175,176,177,178,178,179,179
	dc.w	179,179,179
	dc.w	179,179,179,178,178,177,177,176,175,174,173,172,170,169
	dc.w	168,166,165
	dc.w	163,162,160,158,156,154,153,151,149,147,145,143,141
MotionTableEnd:

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

	dc.w	$0180,$0000,$0182,$0fff

	dc.w	$2a09,$fffe

ScreenPointers:
	dc.w	$00e0,$0000,$00e2,$0000

	dc.w	$2b09,$fffe
	dc.w	$0100,$1200

	dc.w	$ffe1,$fffe

	dc.w	$2b09,$fffe
	dc.w	$0100,$0000

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

		dc.w	0
BScroll:	ds.b	(46*FontHeight)
BSinus1:	ds.b	(44*256)
BSinus2:	ds.b	(44*256)
Font:		incbin TFTDD:Pictures/SubFont2
