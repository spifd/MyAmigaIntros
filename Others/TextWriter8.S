; ******************************
; *                            *
; * Title: TextWriter 8        *
; *                            *
; * Coder: Spirit              *
; * Date : January 1991        *
; *                            *
; * Infos: Text Writer         *
; *        8 Width Font        *
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

FontHeight	= 7
LineStep        = 1
TextLinesNumber = 13

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

	ClrMem	BText,22,256
	bsr	InitTextPointers

	move.l	#Message,CharPointer
	move.l	#MessageEnd,CharPointer+4
	bsr	TextCoder
	move.l	#BText,WhatBText
	move.l	#Message,CharPointer
	bsr	TextWriter

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

	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Init Text Pointers -

InitTextPointers:
	lea	TextPointers(pc),a0
	move.l	#BText,d0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	rts

;; - Text Coder Routine -

; CharPointer   = Message Address 
; CharPointer+4 = Message End Address

TextCoder:
	lea	LettersAddresses(pc),a0
	moveq	#0,d0

PutLettersAddresses:
	move.l	d0,d1
	divu	#40,d1
	moveq	#0,d2
	move.w	d1,d2
	mulu	#40*FontHeight,d2
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
	cmp.b	#0,d0
	bne.s	FindCharLoop

	move.b	#$ff,(a0)+
	bra.s	FindCharEnd

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
	dc.b	"ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"		; Chars
	dc.b	"!?nab.c:,`'d&/\%*()[]ef<>=+"			; Max.
LettersEnd:
	even

LettersAddresses:
	blk.l	(LettersEnd-Letters),0

CharPointer:	dc.l	0,0

Message:
	dc.b	"THIS",0
	dc.b	"IS",0
	dc.b	"TEXTWRITER",0
	dc.b	"8",0
	dc.b	"BY",0
	dc.b	"SPIRIT",0
	dc.b	0
	dc.b	0
	dc.b	"ABCDEFGHIJKL",0
	dc.b	"MNOPQRSTUVWX",0
	dc.b	"YZ0123456789",0
	dc.b	"!?nab.c:,`'d",0
	dc.b	"&/\%*()[]ef<>=+",0
MessageEnd:
	even

;; - Text Writer Routine -

; WhatAddress = Bitplane Address
; CharPointer = Message Address

TextWriter:
	clr.w	Y
	move.w	#TextLinesNumber-1,d6

InitBlitter:
	WaitBlitter
	move.w	#$0000,BltAlwm(a5)
	move.w	#$0000,BltCon1(a5)
	move.w	#[20-2]*2,BltAmod(a5)
	move.w	#[22-2]*2,BltBmod(a5)
	move.w	#[22-2]*2,BltDmod(a5)

CenterText:
	move.l	CharPointer(pc),a0
	moveq	#0,d0

CenterTextLoop:
	addq.w	#1,d0
	cmp.b	#$ff,(a0)+
	bne.s	CenterTextLoop	

	subq.w	#1,d0
	move.w	d0,d7
	subq.w	#1,d7

	cmp.w	#-1,d7
	beq.s	GoDown

	lsl.w	#3,d0
	move.w	#352,d1
	sub.w	d0,d1
	lsr.w	#1,d1
	move.w	d1,X

PrintOneLine:
	bsr	WriteChar
	addq.w	#8,X
	addq.l	#1,CharPointer
	dbra	d7,PrintOneLine

GoDown:
	addq.l	#1,CharPointer
	add.w	#(FontHeight+LineStep),Y

	dbra	d6,CenterText
	rts

X:	dc.w	0
Y:	dc.w	0

;; - Write One Char Routine -

WriteChar:
	move.l	CharPointer(pc),a0
	lea	LettersAddresses(pc),a1
	moveq	#0,d1

GetLetterAddress:
	move.b	(a0),d1
	move.l	(a1,d1.w),a0

	move.w	X(pc),d0

	move.w	#$ff00,d3

	lsr.b	#2,d1
	and.b	#1,d1
	beq.s	CalcDestAddress

	move.w	#$00ff,d3
	subq.w	#8,d0

CalcDestAddress:
	move.l	WhatBText(pc),a1
	move.w	Y(pc),d1

	move.w	d0,d2
	lsr.w	#3,d0
	and.l	#$fffe,d0
	and.w	#$000f,d2
	ror.w	#4,d2
	or.w	#$0dfc,d2

	mulu	#44,d1
	add.w	d1,d0
	add.l	d0,a1

Transfer:
	WaitBlitter
	move.w	d3,BltAfwm(a5)
	move.w	d2,BltCon0(a5)
	move.l	a0,BltApth(a5)
	move.l	a1,BltBpth(a5)
	move.l	a1,BltDpth(a5)
	move.w	#64*(FontHeight)+2,BltSize(a5)
	rts

WhatBText:	dc.l	0

;; - Save & Restore All Routine -

	INCLUDE	TFTSD:Help/Save&RestoreAll.S

;
;; ---- COPPERLIST ----
;

CopperList:
	dc.w	$009c,$8010

	dc.w	$0100,$0000
	dc.w	$008e,$2971,$0090,$29e1
	dc.w	$0092,$0030,$0094,$00d8
	dc.w	$0102,$0000,$0104,$0000
	dc.w	$0108,$0000,$010a,$0000

	dc.w	$0180,$0000,$0182,$0fff

	dc.w	$2a09,$fffe

TextPointers:
	dc.w	$00e0,$0000,$00e2,$0000

	dc.w	$2c09,$fffe,$0100,$1200

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

Font:	incbin	TFTDD:Pictures/SubFont1
BText:	ds.b	44*256
