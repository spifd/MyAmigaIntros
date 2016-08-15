; ******************************
; *                            *
; * Title: Vertical Bars Intro *
; *                            *
; * Coder: Spirit              *
; * Date : December 1990       *
; *                            *
; * Infos: Pseudo Vertical     *
; *        Raster Bars         *
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

BarsStartLine	= $2f
BarHeightMax	= 241

BWork		= $50000

BText1		= $60000
BShadow1	= BText1+(88*BarHeightMax*1)
BText2		= BText1+(88*BarHeightMax*2)
BShadow2	= BText1+(88*BarHeightMax*3)
BText3		= BText1+(88*BarHeightMax*4)
BShadow3	= BText1+(88*BarHeightMax*5)
BName		= BText1+(88*BarHeightMax*6)

PauseTime	= 500

HShadow		= 3
VShadow		= 3

FontHeight	= 16
TextLinesNumber	= 12
LineStep	= 3

MotionStep1	= 2
MotionStep2	= 4
MotionStep3	= 8
MotionStep4	= 5

MainCLeft	= $0836
CStepLeft	= $0111
MainCRight	= $0ccc
CStepRight	= -$0110

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

	move.w	#%0000000000000010,$02e(a5)

	ClrMem	BWork,0,0
	ClrMem	BText1,0,0

	bsr	BuildBarDesign
	bsr	BuildBarsCopperList
	bsr	InitBlitCop

	move.l	#Message1,CharPointer
	move.l	#Message1End,CharPointer+4
	bsr	TextCoder
	move.l	#BText1+(88*10)+88+2,WhatBText
	move.l	#Message1,CharPointer
	bsr	TextWriter
	lea	BText1+88,a0
	lea	BShadow1+88,a1
	bsr	HBShadow
	lea	BText1+88,a1
	bsr	IgnoreBend
	lea	BShadow1+88,a1
	bsr	IgnoreBend

	move.l	#Message2,CharPointer
	move.l	#Message2End,CharPointer+4
	bsr	TextCoder
	move.l	#BText2+(88*10)+88+2,WhatBText
	move.l	#Message2,CharPointer
	bsr	TextWriter
	lea	BText2+88,a0
	lea	BShadow2+88,a1
	bsr	HBShadow
	lea	BText2+88,a1
	bsr	IgnoreBend
	lea	BShadow2+88,a1
	bsr	IgnoreBend

	move.l	#Message3,CharPointer
	move.l	#Message3End,CharPointer+4
	bsr	TextCoder
	move.l	#BText3+(88*10)+88+2,WhatBText
	move.l	#Message3,CharPointer
	bsr	TextWriter
	lea	BText3+88,a0
	lea	BShadow3+88,a1
	bsr	HBShadow
	lea	BText3+88,a1
	bsr	IgnoreBend
	lea	BShadow3+88,a1
	bsr	IgnoreBend

	lea	BName+38,a1
	bsr	DisplayCoderName

	move.l	#CopperList,$080(a5)
	clr.w	$088(a5)

	move.l	#Irq3,$6c

LeftButtonTest:
	btst	#6,$bfe001
	bne.s	LeftButtonTest

End:
	move.w	#%0000000000000000,$02e(a5)

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

	bsr	RasterCycle
	bsr	MoveText
	bsr	VerticalBars

	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Move Text Routine -

MoveText:
	cmp.w	#0,ChangeTextFlag
	beq.s	ChangeTextPointers

	cmp.w	#0,Pause
	beq.s	LetsMove

	subq.w	#1,Pause
	rts

ChangeTextPointers:
	move.w	#$0000,NoTwo
	move.w	#2,ChangeTextFlag

	move.l	WhatPagePointer,a0
	move.l	(a0),d0

	move.w	d0,TextPointers+6
	swap	d0
	move.w	d0,TextPointers+2
	swap	d0

	add.l	#(88*BarHeightMax),d0

	move.w	d0,TextPointers+14
	swap	d0
	move.w	d0,TextPointers+10
	swap	d0
	
	add.l	#4,WhatPagePointer
	cmp.l	#WhatPageEnd,WhatPagePointer
	bne.s	NoCycle

	move.l	#WhatPage,WhatPagePointer

NoCycle:
	rts

LetsMove:
	cmp.l	#$00010000,ChangeTextFlag
	bne.s	IncOrDecTextPointers

	move.w	#PauseTime,Pause
	move.w	#$0001,NoTwo
	rts

IncOrDecTextPointers:
	move.w	MotionWay(pc),d0
	add.w	d0,TextPointers+6
	add.w	d0,TextPointers+14
	addq.w	#1,HowStep

	cmp.w	#22,HowStep
	bne.s	NoFinished

	subq.w	#1,ChangeTextFlag
	neg.w	MotionWay
	move.w	#0,HowStep

NoFinished:
	rts

HowStep:		dc.w	0
MotionWay:		dc.w	-2
Pause:			dc.w	0
ChangeTextFlag:		dc.w	0
NoTwo:			dc.w	0
WhatPagePointer:	dc.l	WhatPage
WhatPage:		dc.l	BText1+44,BText2+44,BText3+44
WhatPageEnd:

;; - Vertical Bars Routine -

VerticalBars:
	move.l	MotionPointer1(pc),a0
	move.l	MotionPointer2(pc),a1
	lea	BarsCopperList+6(pc),a2
	move.w	#BarHeightMax-1,d0

VerticalBarsLoop:
	moveq	#0,d2
	move.w	(a0),d1
	add.w	(a1),d1
	lsr.w	#1,d1
	add.w	#270,d1
	move.w	d1,d2

	lsr.w	#3,d2
	and.w	#$fffe,d2

	and.w	#$000f,d1
	ror.w	#4,d1
	move.w	d1,4(a2)

	or.w	#$0fca,d1
	move.w	d1,(a2)

	move.w	d2,8(a2)
	move.w	d2,12(a2)

	add.l	#24*2,a2

MotionControl1:
	add.l	#2*MotionStep1,a0
	cmp.l	#MotionTable1End,a0
	blt.s	MotionControl2

	sub.l	#MotionTable1End-MotionTable1,a0

MotionControl2:
	sub.l	#2*MotionStep3,a1
	cmp.l	#MotionTable2,a1
	bge.s	ContinueBarsLoop

	add.l	#MotionTable2End-MotionTable2,a1

ContinueBarsLoop:
	dbra	d0,VerticalBarsLoop

MotionTable1Control:
	add.l	#2*MotionStep2,MotionPointer1
	cmp.l	#MotionTable1End,MotionPointer1
	blt.s	MotionTable2Control

	sub.l	#MotionTable1End-MotionTable1,MotionPointer1

MotionTable2Control:	
	sub.l	#2*MotionStep4,MotionPointer2
	cmp.l	#MotionTable2,MotionPointer2
	bge.s	VerticalBarsEnd

	add.l	#MotionTable2End-MotionTable2,MotionPointer2

VerticalBarsEnd:	
	rts

MotionPointer1:	dc.l	MotionTable1

MotionTable1:
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
MotionTable1End:

MotionPointer2:	dc.l	MotionTable2End

MotionTable2:
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
MotionTable2End:

BarDesign:
	blk.l	BarHeightMax*4,0

BarMask:
	blk.l	BarHeightMax*4,$ffff0000

;; - Raster Cycle Routine -

RasterCycle:
	WaitBlitter
	move.w	#$ffff,BltAfwm(a5)
	move.w	#$ffff,BltAlwm(a5)
	move.w	#$09f0,BltCon0(a5)
	move.w	#$0000,BltCon1(a5)
	move.w	#2,BltAmod(a5)
	move.w	#2,BltDmod(a5)
	move.l	#FirstCycling+6+4,BltApth(a5)
	move.l	#FirstCycling+6+0,BltDpth(a5)
	move.w	#64*[(352/8)-1]+1,BltSize(a5)

	WaitBlitter
	move.w	#$0002,BltCon1(a5)
	move.l	#SecondCycling+6+[[(352/8)-2]*4],BltApth(a5)
	move.l	#SecondCycling+6+[[(352/8)-1]*4],BltDpth(a5)
	move.w	#64*[(352/8)-1]+1,BltSize(a5)

	move.l	RasterLine(pc),a0
	move.w	(a0),FirstCycling+6+[[(352/8)-1]*4]
	move.w	(a0),SecondCycling+6

	addq.l	#2,RasterLine
	cmp.l	#RasterColorsEnd,RasterLine
	bne.s	RasterCycleEnd

	move.l	#RasterColors,RasterLine

RasterCycleEnd:
	rts

RasterLine:	dc.l	RasterColors

RasterColors:
	dc.w	$0f00,$0f10,$0f20,$0f30,$0f40,$0f50,$0f60,$0f70
	dc.w	$0f80,$0f90,$0fa0,$0fb0,$0fc0,$0fd0,$0fe0,$0ff0
	dc.w	$0ef0,$0df0,$0cf0,$0bf0,$0af0,$09f0,$08f0,$07f0
	dc.w	$06f0,$05f0,$04f0,$03f0,$02f0,$01f0,$00f0,$00f1
	dc.w	$00f2,$00f3,$00f4,$00f5,$00f6,$00f7,$00f8,$00f9
	dc.w	$00fa,$00fb,$00fc,$00fd,$00fe,$00ff,$00ef,$00df
	dc.w	$00cf,$00bf,$00af,$009f,$008f,$007f,$006f,$005f
	dc.w	$004f,$003f,$002f,$001f,$000f,$010f,$020f,$030f
	dc.w	$040f,$050f,$060f,$070f,$080f,$090f,$0a0f,$0b0f
	dc.w	$0c0f,$0d0f,$0e0f,$0f0f,$0f0e,$0f0c,$0f0b,$0f0a
	dc.w	$0f09,$0f08,$0f07,$0f06,$0f05,$0f04,$0f03,$0f02
	dc.w	$0f01,$0f00
RasterColorsEnd:

;; - Text Coder Routine -

; CharPointer   = Message Address 
; CharPointer+4 = Message End Address

TextCoder:
	lea	LettersAddresses(pc),a0
	moveq	#0,d0

PutLettersAddresses:
	move.l	d0,d1
	divu	#20,d1
	moveq	#0,d2
	move.w	d1,d2
	mulu	#40*FontHeight,d2
	swap	d1
	lsl.l	#1,d1
	and.l	#$0000ffff,d1
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
	dc.b	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"			; Chars
	dc.b	"0123456789"					; Max.
	dc.b	"a-.:b/c,()!def?'%&gh=+* "
LettersEnd:
	even

LettersAddresses:
	blk.l	(LettersEnd-Letters),0

CharPointer:	dc.l	0,0

Message1:
	dc.b	"SPIRIT'S ALWAYS",0
	dc.b	"COMPLAINING ABOUT",0
	dc.b	"THE FACT HE NEVER",0
	dc.b	"KNOWS WHAT TO WRITE",0
	dc.b	"POOR GUY!",0
	dc.b	"I'VE NO PROBLEM",0
	dc.b	"WRITING BULLSHIT!",0
	dc.b	"CRAP'S MY LIFE!",0
	dc.b	"g ENJOY! h",0
	dc.b	"EH?",0
	dc.b	"SPIRIT'S GETTING",0
	dc.b	"REAL LAME...",0
Message1End:

Message2:
	dc.b	"WELL, THIS INTRO",0
	dc.b	"LOOKS NICE ANYWAY.",0
	dc.b	"NOT SO HARD, EH?",0
	dc.b	"IS IT?",0
	dc.b	"REALLY?",0
	dc.b	"I CAN'T BELIEVE IT!",0
	dc.b	"I SHAN'T!",0
	dc.b	"BUT...",0
	dc.b	"I MUST ADMIT IT",0
	dc.b	"LOOKS PRETTY NICE",0
	dc.b	"TEXT IS GONNA BE",0
	dc.b	"ccc OVER! ccc",0
Message2End:

Message3:
	dc.b	"NOT EXACTLY...",0
	dc.b	"THERE'S ONE MORE",0
	dc.b	"PAGE TO READ...",0
	dc.b	"IT WON'T BE LONG",0
	dc.b	"JUST FOR YOU...",0
	dc.b	"SOME STARS...",0
	dc.b	"cccccccccccccccc",0
	dc.b	"I THINK I MUST",0
	dc.b	"CONGRATULATE YOU",0
	dc.b	"ccc SPIRIT ccc",0
	dc.b	"REAL NICE INTRO!",0
	dc.b	"g UNREAL h",0
Message3End:
	even

;; - Text Writer Routine -

; WhatAddress = Bitplane Address
; CharPointer = Message Address

TextWriter:
	clr.w	Y
	move.w	#TextLinesNumber-1,d6

InitBlitter:
	WaitBlitter
	move.w	#$ffff,BltAfwm(a5)
	move.w	#$0000,BltAlwm(a5)
	move.w	#$0000,BltCon1(a5)
	move.w	#[20-2]*2,BltAmod(a5)
	move.w	#[44-2]*2,BltBmod(a5)
	move.w	#[44-2]*2,BltDmod(a5)

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

	lsl.w	#4,d0
	move.w	#352,d1
	sub.w	d0,d1
	lsr.w	#1,d1
	move.w	d1,X

PrintOneLine:
	bsr	WriteChar
	add.w	#16,X
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

CalcDestAddress:
	move.l	WhatBText(pc),a1
	move.w	X(pc),d0
	move.w	Y(pc),d1

	move.w	d0,d2
	lsr.w	#3,d0
	and.l	#$fffe,d0
	and.w	#$f,d2
	ror.w	#4,d2
	or.w	#$0dfc,d2

	mulu	#88,d1
	add.w	d1,d0
	add.l	d0,a1

Transfer:
	WaitBlitter
	move.w	d2,BltCon0(a5)
	move.l	a0,BltApth(a5)
	move.l	a1,BltBpth(a5)
	move.l	a1,BltDpth(a5)
	move.w	#64*(FontHeight)+2,BltSize(a5)
	rts

WhatBText:	dc.l	0

;; - Ignore Bend Routine -

; a1 = Bitplane Address

IgnoreBend:
	lea	BarsCopperList+46(pc),a0
	move.w	#(BarHeightMax-1)-1,d0

IgnoreBendLoop:
	move.l	#2,d2
	move.w	(a0),d1
	cmp.w	#0,d1
	bne.s	ContinueBendLoop
	
	clr.l	d2

ContinueBendLoop:
	and.w	#$000f,d1
	move.w	#$10,d3
	sub.w	d1,d3

	lsl.w	#8,d3
	lsl.w	#4,d3
	or.w	#$09f0,d3	

	WaitBlitter
	move.w	#$ffff,BltAfwm(a5)
	move.w	#$ffff,BltAlwm(a5)
	move.w	d3,BltCon0(a5)
	move.w	#$0000,BltCon1(a5)
	move.w	#0,BltAmod(a5)
	move.w	#0,BltDmod(a5)
	move.l	a1,BltApth(a5)
	sub.l	d2,a1
	move.l	a1,BltDpth(a5)
	add.l	d2,a1
	move.w	#(64*1)+44,BltSize(a5)

	add.l	#24*2,a0
	add.l	#88,a1

	dbra	d0,IgnoreBendLoop
	rts

;; - Half-Bright Shadow Maker Routine -

; a0 = Bitplane Text Address
; a1 = Bitplane Shadow Address

HBShadow:
	WaitBlitter
	move.w	#$ffff,BltAfwm(a5)
	move.w	#$ffff,BltAlwm(a5)
	move.w	#$0d0c,BltCon0(a5)
	move.w	#HShadow,d0
	lsl.w	#8,d0
	lsl.w	#4,d0
	move.w	d0,BltCon1(a5)
	move.w	#0,BltAmod(a5)
	move.w	#0,BltBmod(a5)
	move.w	#0,BltDmod(a5)
	move.l	a0,BltApth(a5)
	sub.l	#(88*VShadow),a0
	move.l	a0,BltBpth(a5)
	move.l	a1,BltDpth(a5)
	move.w	#(64*BarHeightMax)+44,BltSize(a5)
	rts

;; - Build Bars CopperList Routine -

BuildBarsCopperList:
	lea	BarsCopperList(pc),a0
	move.w	#BarHeightMax-1,d0
	move.b	#BarsStartLine,d1
	move.l	#BarMask,d2
	moveq	#0,d3
	move.l	#320,d4
	bra.s	BlitterTransferCop

BuildBarsCopperListLoop:
	move.b	d1,(a0)+
	move.b	#$e1,(a0)+
	move.w	#$fffe,(a0)+

	move.w	d4,d5
	move.w	d4,d6

	lsr.w	#3,d5
	and.w	#$fffe,d5

	and.w	#$000f,d6
	move.w	#$000f,d7
	sub.w	d6,d7

	move.w	#$00e2,(a0)+
	move.w	d5,(a0)+
	add.w	#60,d5	
	move.w	#$00e6,(a0)+
	move.w	d5,(a0)+
	add.w	#60,d5	
	move.w	#$00ea,(a0)+
	move.w	d5,(a0)+
	add.w	#60,d5	
	move.w	#$00ee,(a0)+
	move.w	d5,(a0)+
	move.w	#$0102,(a0)+
	move.w	d7,(a0)
	lsl.w	#4,d7
	or.w	d7,(a0)+

	subq.w	#1,d4
	addq.b	#1,d1

BlitterTransferCop:
	move.b	d1,(a0)+
	move.b	#$61,(a0)+
	move.w	#$fffe,(a0)+
	move.l	#$00400fca,(a0)+	; BltCon0
	move.l	#$00420000,(a0)+	; BltCon1
	move.w	#$004a,(a0)+		; BltCptl
	move.w	d3,(a0)+
	move.w	#$0056,(a0)+		; BltDptl
	move.w	d3,(a0)+
	move.w	#$0058,(a0)+		; BltSize
	move.w	#64*4+2,(a0)+

	cmp.b	#38,d3
	beq.s	ContinueBarsCopLoop

	addq.b	#2,d3

ContinueBarsCopLoop:
	dbra	d0,BuildBarsCopperListLoop
	rts

;; - Init Blitter in CopperList -

InitBlitCop:
	move.l	#BarDesign,d0
	move.w	d0,BlitterInit+22
	swap	d0
	move.w	d0,BlitterInit+18

	move.l	#BarMask,d0
	move.w	d0,BlitterInit+30
	swap	d0
	move.w	d0,BlitterInit+26
	rts

;; - Build Bar Design Routine -

BuildBarDesign:
	lea	BarDesign(pc),a0
	move.w	#BarHeightMax-1,d0

BuildBarDesignLoop:
	move.l	#%10101010010101010000000000000000,(a0)+
	move.l	#%01100110001100110000000000000000,(a0)+
	move.l	#%00011110000011110000000000000000,(a0)+
	move.l	#%00000001111111110000000000000000,(a0)+

	dbra	d0,BuildBarDesignLoop
	rts

;; - Display Coder Name Routine -

; a1 = Bitplane Address

DisplayCoderName:
	move.l	CoderName+00(pc),88*0(a1)
	move.l	CoderName+04(pc),88*1(a1)
	move.l	CoderName+08(pc),88*2(a1)
	move.l	CoderName+12(pc),88*3(a1)
	move.l	CoderName+16(pc),88*4(a1)
	rts

CoderName:	
	dc.l	%00001111011110101111010111100000
	dc.l	%00001000010010101001010000100000
	dc.l	%00001111011110101111010000100000
	dc.l	%00000001010000101010010000100000
	dc.l	%00001111010000101001010000100000

;; - Save & Restore All Routine -

	INCLUDE	TFTSD:Help/Save&RestoreAll.S

;
;; ---- COPPERLIST ----
;

CopperList:
	dc.w	$0100,$0000
	dc.w	$008e,$2971,$0090,$29e1
	dc.w	$0092,$0028,$0094,$00d0
	dc.w	$0102,$0000,$0104,$0000
	dc.w	$0108,44,$010a,44

	dc.w	$0180,$0000

	dc.w	$0182,MainCLeft+(CStepLeft*0)
	dc.w	$0184,MainCLeft+(CStepLeft*1)
	dc.w	$0186,MainCLeft+(CStepLeft*2)
	dc.w	$0188,MainCLeft+(CStepLeft*3)
	dc.w	$018a,MainCLeft+(CStepLeft*4)
	dc.w	$018c,MainCLeft+(CStepLeft*5)
	dc.w	$018e,MainCLeft+(CStepLeft*6)
	dc.w	$0190,MainCLeft+(CStepLeft*7)

	dc.w	$0192,MainCRight+(CStepRight*0)
	dc.w	$0194,MainCRight+(CStepRight*1)
	dc.w	$0196,MainCRight+(CStepRight*2)
	dc.w	$0198,MainCRight+(CStepRight*3)
	dc.w	$019a,MainCRight+(CStepRight*4)
	dc.w	$019c,MainCRight+(CStepRight*5)
	dc.w	$019e,MainCRight+(CStepRight*6)

	dc.w	$01a0,$000f,$01a2,$000f,$01a4,$000f
	dc.w	$01a6,$000f,$01a8,$000f,$01aa,$000f
	dc.w	$01ac,$000f,$01ae,$000f,$01b0,$000f
	dc.w	$01b2,$000f,$01b4,$000f,$01b6,$000f
	dc.w	$01b8,$000f,$01ba,$000f,$01bc,$000f
	dc.w	$01be,$000f

ScreenPointers:
	dc.w	$2a09,$fffe
	dc.w	$00e0,(BWork/$10000)
	dc.w	$00e4,(BWork/$10000)
	dc.w	$00e8,(BWork/$10000)
	dc.w	$00ec,(BWork/$10000)

TextPointers:
	dc.w	$00f0,(BText1/$10000),$00f2,88+44
	dc.w	$00f4,(BShadow1/$10000),$00f6,88+(88*BarHeightMax)+44

BlitterInit:				;             Initialized ?
	dc.w	$0044,$ffff		; BltAfwm	   Y
	dc.w	$0046,$0000		; BltAlwm          Y
	dc.w	$0048,(BWork/$10000)	; BltCpth          Y
	dc.w	$004a,$0000		; BltCptl          Y
	dc.w	$004c,$0000		; BltBpth          N
	dc.w	$004e,$0000		; BltBptl          N
	dc.w	$0050,$0000		; BltApth          N
	dc.w	$0052,$0000		; BltAptl          N
	dc.w	$0054,(BWork/$10000)	; BltDpth          Y
	dc.w	$0060,(30-2)*2		; BltCmod          Y
	dc.w	$0062,0			; BltBmod          Y
	dc.w	$0064,0			; BltAmod          Y
	dc.w	$0066,(30-2)*2		; BltDmod          Y

FirstCycling:
	dc.b	BarsStartLine-1,$39
	dc.w	$fffe
	blk.l	[352/8]+1,$01800000

	dc.b	BarsStartLine,$09
	dc.w	$fffe
	dc.w	$0100,$6200

BarsCopperList:
	blk.w	(24*BarHeightMax)-12,0

	dc.b	(BarsStartLine+BarHeightMax-$100),$09
	dc.w	$fffe
	dc.w	$0100,$0000

SecondCycling:
	dc.b	(BarsStartLine+BarHeightMax+1-$100),$39
	dc.w	$fffe
	blk.l	[352/8]+1,$01800000

	dc.b	(BarsStartLine+BarHeightMax+3-$100),$09
	dc.w	$fffe
	dc.w	$0100,$1200
	dc.w	$0182,$0fff
	dc.w	$00e0,(BName/$10000),$00e2,[(88*BarHeightMax*6)-$10000]

	dc.b	(BarsStartLine+BarHeightMax+8-$100),$09
	dc.w	$fffe
	dc.w	$0100,$0000

ClearLastLine:
	dc.b	(BarsStartLine+BarHeightMax+9-$100),$09
	dc.w	$fffe
	dc.w	$0066,$0000		; BltDmod          Y
	dc.w	$0040,$0100		; BltCon0          Y
	dc.w	$0042,$0000		; BltCon1          Y
	dc.w	$004a,$0000		; BltCptl          Y
	dc.w	$0056,$0000		; BltDptl          Y
	dc.w	$0058,(64*4+30)		; BltSize          Y

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

Font:		incbin TFTDD:Pictures/SubFont2
