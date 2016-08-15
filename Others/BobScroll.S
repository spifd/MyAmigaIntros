; ******************************
; *                            *
; * Title: Bob Scroll          *
; *                            *
; * Coder: Spirit              *
; * Date : January 1991        *
; *                            *
; * Infos: Simple Bob Scroll   *
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

FontHeight	= 25
BobScrollSpeed	= $0011		; $0011,$0022,$0044,$0088
MotionStep1	= 2
MotionStep2	= 10

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

	ClrMem	BScroll,25,256*3

	move.l	#Message,CharPointer
	move.l	#MessageEnd,CharPointer+4
	bsr	TextCoder
	lea	MotionTable(pc),a0
	lea	MotionTableEnd(pc),a1
	bsr	TransformMotionTable

	lea	ScreenPointers(pc),a0
	move.l	#BScroll,BScrollPointer
	bsr	InitScreenPointers

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

	bsr	BobScroll

GoOnIrq3:
	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Text Coder Routine -

; CharPointer = Message Address , Message End Address

TextCoder:
	lea	LettersAddresses(pc),a0
	moveq	#0,d0

PutLettersAddresses:
	move.l	d0,d1
	divu	#10,d1
	moveq	#0,d2
	move.w	d1,d2
	mulu	#40*FontHeight*3,d2
	swap	d1
	lsl.l	#2,d1
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
	move.b	(a0),d0
	moveq	#0,d1

FindCharLoop:
	cmp.b	(a1,d1),d0
	beq.s	PutLetterOffset
	addq.l	#1,d1
	bra.s	FindCharLoop

PutLetterOffset:
	lsl.l	#2,d1
	move.b	d1,(a0)+
	cmp.l	CharPointer+4(pc),a0
	bne.s	FindChar
	rts

Letters:							; 64
	dc.b	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"			; Chars 
	dc.b	"!?:;0123456789~(),-.'ab "			; Max.
LettersEnd:
	even

LettersAddresses:
	blk.l	(LettersEnd-Letters),0

CharPointer:	dc.l	0,0

Message:
	dc.b	"           "
	dc.b	"SPIRIT IS PROUD TO PRESENT HIS FIRST BOB SCROLL ..."
MessageEnd:
	even

;; - Transform Vertical Motion Table in Address Offset -

; a0 = Motion Table Start
; a1 = Motion Table End

TransformMotionTable:
	move.w	(a0),d0
	mulu	#50*3,d0
	move.w	d0,(a0)+
	cmp.l	a0,a1
	bne.s	TransformMotionTable
	rts

;; - Init Screen Pointers -

InitScreenPointers:
	moveq	#50,d1
	move.l	BScrollPointer(pc),d2
	move.w	d2,6(a0)
	swap	d2
	move.w	d2,2(a0)
	swap	d2
	add.l	d1,d2
	move.w	d2,14(a0)
	swap	d2
	move.w	d2,10(a0)
	swap	d2
	add.l	d1,d2
	move.w	d2,22(a0)
	swap	d2
	move.w	d2,18(a0)
	rts

;; - Bob Scroll Routine -

BobScroll:
	lea	ScreenPointers(pc),a0
	move.l	#(2*MotionStep1),d0

	sub.w	#BobScrollSpeed,BplCon1Value+2
	cmp.w	#-$0011,BplCon1Value+2
	bne.s	ControlMotion

	addq.l	#2,BScrollPointer
	bsr	InitScreenPointers

	move.w	#$00ff,BplCon1Value+2

	cmp.l	#BScroll+4,BScrollPointer
	bne.s	ControlMotion

	move.l	#BScroll,BScrollPointer
	bsr	InitScreenPointers
	
	addq.l	#1,CharPointer
	cmp.l	#MessageEnd,CharPointer
	bne.s	ReplaceMotion

	move.l	#Message,CharPointer

ReplaceMotion:
	move.l	#(2*MotionStep1)+(2*MotionStep2),d0

ControlMotion:
	add.l	d0,MotionPointer
	cmp.l	#MotionTableEnd,MotionPointer
	blt.s	BobsPrint

	sub.l	#(MotionTableEnd-MotionTable),MotionPointer

BobsPrint:
	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.w	#$0000,BltCon1(a5)
	move.l	#2^16*[20-2]*2+[25-2]*2,BltAmod(a5)

	move.l	CharPointer(pc),a0
	lea	LettersAddresses(pc),a1
	move.l	MotionPointer(pc),a2
	lea	LastAddresses(pc),a4
	moveq	#12-1,d0
	moveq	#0,d1
	moveq	#0,d3

BobsPrintLoop:
	move.b	(a0)+,d1
	move.l	(a1,d1.w),a3

	WaitBlitter
	move.w	#$0100,BltCon0(a5)
	move.l	(a4),BltDpth(a5)
	move.w	#64*(FontHeight*3)+2,BltSize(a5)

	move.l	#BScroll,d2
	move.w	(a2),d4
	add.l	d4,d2
	add.l	d3,d2
	move.l	d2,(a4)+

TransferLetter:
	WaitBlitter
	move.w	#$09f0,BltCon0(a5)
	move.l	a3,BltApth(a5)
	move.l	d2,BltDpth(a5)
	move.w	#64*(FontHeight*3)+2,BltSize(a5)

	addq.l	#4,d3

	add.l	#(2*MotionStep2),a2
	cmp.l	#MotionTableEnd,a2
	blt.s	NoMotionTableEnd

	sub.l	#(MotionTableEnd-MotionTable),a2

NoMotionTableEnd:
	cmp.l	#MessageEnd,a0
	bne.s	NoMessageEnd

	lea	Message(pc),a0

NoMessageEnd:
	dbra	d0,BobsPrintLoop
	rts

LastAddresses:	blk.l	12,BScroll

BScrollPointer:	dc.l	BScroll

MotionPointer:	dc.l	MotionTable-(2*MotionStep1)

MotionTable:
	dc.w	100,102,105,108,111,114,117,120,123,126,129,132,135,138
	dc.w	140,143,146,148,151,153,156,158,161,163,165,168,170,172
	dc.w	174,176,178,180,181,183,185,186,188,189,190,192,193,194
	dc.w	195,196,196,197,198,198,199,199,199,199,199,199,199,199
	dc.w	199,199,198,198,197,196,195,194,193,192,191,190,189,187
	dc.w	186,184,183,181,179,177,175,173,171,169,167,165,163,160
	dc.w	158,155,153,150,148,145,142,140,137,134,131,128,125,122
	dc.w	120,117,114,111,108,105,102,99,96,93,90,87,84,81,78,75
	dc.w	72,69,66,63,61,58,55,53,50,47,45,42,40,38,35,33,31,29
	dc.w	26,24,23,21,19,17,15,14,12,11,10,8,7,6,5,4,3,2,2,1,1,0
	dc.w	0,0,0,0,0,0,0,0,0,1,1,2,2,3,4,5,6,7,8,9,11,12,14,15,17
	dc.w	19,20,22,24,26,28,30,33,35,37,40,42,44,47,50,52,55,58
	dc.w	60,63,66,69,72,74,77,80,83,86,89,92,95,98
MotionTableEnd:

;; - Save & Restore All Routine -

	INCLUDE	TFTSD:Help/Save&RestoreAll.S

;
;; ---- COPPERLIST ----
;

CopperList:
	dc.w	$0100,$0000
	dc.w	$008e,$2971,$0090,$29e1
	dc.w	$0092,$0028,$0094,$00d8
	dc.w	$0102,$0000,$0104,$0000
	dc.w	$0108,[(50+2)*2],$010a,[(50+2)*2]
	dc.w	$0180,$0000

	dc.w	$2a09,$fffe

ScreenPointers:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000

BplCon1Value:
	dc.w	$0102,$00ff

ColorsTable:
	dc.w	$0180,$0000,$0182,$0fff,$0184,$0bbb,$0186,$0999
	dc.w	$0188,$0888,$018a,$0666,$018c,$0555,$018e,$0333

	dc.w	$2b09,$fffe
	dc.w	$0100,$3200

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

Font:		incbin TFTDD:Pictures/KnightHawks
BScroll:	ds.b	(50*256*3)
