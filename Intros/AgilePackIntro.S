; ******************************
; *                            *
; * Title: Agile Pack Intro    *
; *                            *
; * Coder: Spirit              *
; * Date : May 1991            *
; *                            *
; * Infos: First Spirit/Agile  *
; *        Intro               *
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

RasterLineStart = 150
NbChoice	= 5			; Must be < 10

HighAddress	= $70000

LogoLine	= $2d
LogoHeight	= 60

BarsStartLine	= LogoLine+LogoHeight+3
BarHeightMax	= 180

MotionStep1	= 2
MotionStep2	= 4
MotionStep3	= 8
MotionStep4	= 5

MainCLeft	= $0836
CStepLeft	= $0111
MainCRight	= $0ccc
CStepRight	= -$0110

HShadow		= 1
VShadow		= 1

FontHeight	= 7
LineStep        = 3
TextLinesNumber = 17

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

;; - Wait Raster Macro -

; Syntax = WaitRaster RasterLine

WaitRaster:	MACRO
WaitRasterLoop\@:
	cmp.b	#\1,$006(a5)
	bls.s	WaitRasterLoop\@
		ENDM

;; - Menu Color Macro -

MenuColor:	MACRO
	move.w	d0,$1a0(a5)
	move.w	d0,$1a2(a5)
	move.w	d0,$1a4(a5)
	move.w	d0,$1a6(a5)
	move.w	d0,$1a8(a5)
	move.w	d0,$1aa(a5)
	move.w	d0,$1ac(a5)
	move.w	d0,$1ae(a5)
	move.w	d0,$1b0(a5)
	move.w	d0,$1b2(a5)
	move.w	d0,$1b4(a5)
	move.w	d0,$1b6(a5)
	move.w	d0,$1b8(a5)
	move.w	d0,$1ba(a5)
	move.w	d0,$1bc(a5)
	move.w	d0,$1be(a5)
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

	ClrMem	BWork,60,4
	ClrMem	BName,22,5
	ClrMem	BText,22,BarHeightMax
	ClrMem	BShadow,22,BarHeightMax

	bsr	BuildBarDesign
	bsr	BuildBarsCopperList
	lea	BName+38,a1
	bsr	DisplayCoderName

	move.l	#CopperList,$080(a5)
	clr.w	$088(a5)

	move.l	#Message,CharPointer
	move.l	#MessageEnd,CharPointer+4
	bsr	TextCoder
	move.l	#BText+(44*5)+44+2,WhatBText
	move.l	#Message,CharPointer
	bsr	TextWriter
	lea	BText+44,a0
	lea	BShadow+44,a1
	bsr	HBShadow
	lea	BText+44,a1
	bsr	IgnoreBend
	lea	BShadow+44,a1
	bsr	IgnoreBend

	bsr	InitLogoPointers
	bsr	InitBlitCop
	bsr	InitScreenPointers
	bsr	InitTextPointers

	bsr	Mt_Init

	move.w	#%0000000000000010,$02e(a5)

	move.l	#Irq3,$6c

LeftButtonTest:
	btst	#6,$bfe001
	bne.s	LeftButtonTest

End:
	move.w	#%0000000000000000,$02e(a5)

	bsr	CopyName
	bsr	Mt_End

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
	beq	Irq3End

	not.b	LogoCtrlFlag
	beq.s	MusicCtrl

LogoCtrl:
	jsr	LogoColorsCtrl

MusicCtrl:
	nop
	nop
	nop
	lea	$dff000,a5

	bsr	VerticalBars
	bsr	RasterCycle
	bsr	ColorMenu

	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

LogoCtrlFlag:	dc.b	0
		even

;
;; ---- ROUTINES ----
;

;; - Copy File Name to High Chip -

CopyName:
	move.w	ChoicePointer(pc),d0
	add.w	#48,d0	
	move.b	d0,HighAddress
	move.b	#0,HighAddress+1
	rts

;; - Mouse Control Routine -

MouseCtrl:
	move.w	$00a(a5),d0
	and.w	#$ff00,d0
	lsr.w	#8,d0

	move.w	OldMouseY(pc),d1
	move.w	d0,OldMouseY
	sub.w	d1,d0
	cmp.b	#-2,d0
	ble.s	SelectHigher
	cmp.b	#2,d0
	bge.s	SelectLower
	bra.s	NotPossible

SelectHigher:
	cmp.w	#0,ChoicePointer
	beq.s	NotPossible

	subq.w	#1,ChoicePointer
	bra.s	NotPossible

SelectLower:
	cmp.w	#NbChoice-1,ChoicePointer
	beq.s	NotPossible

	addq.w	#1,ChoicePointer

NotPossible:
	move.w	ChoicePointer(pc),d0
	add.w	d0,d0
	move.w	d0,d2
	lea	CxCols(pc,d0.w),a0
	move.w	#$0fff,(a0)

ReplaceAllToBlue:
	moveq	#NbChoice-1,d0

ReplaceAllToBlueLoop:
	move.w	d0,d1
	add.w	d1,d1
	lea	CxCols(pc,d1.w),a0

	cmp.w	#$000f,(a0)
	beq.s	GoOnReplacingToBlue

	sub.w	#$110,(a0)

GoOnReplacingToBlue:
	dbra	d0,ReplaceAllToBlueLoop
	rts

OldMouseY:		dc.w	2
ChoicePointer:		dc.w	0
CxCols:			blk.w	NbChoice,$000f

;; - Color Menu Routine -

ColorMenu:
	lea	CxCols(pc),a0

RasterLine:	set	RasterLineStart

	REPT	NbChoice

	WaitRaster	RasterLine
	move.w	(a0)+,d0
	MenuColor

Rasterline:	set	RasterLine+10

	ENDR

	WaitRaster	RasterLine
	move.w	#$000f,d0
	MenuColor
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
	swap	d1
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

Letters:
	dc.b	"ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"
	dc.b	"!?nab.c:,`'d&/\%*()[]ef<>=+"
LettersEnd:
	even

LettersAddresses:
	blk.l	(LettersEnd-Letters),0

CharPointer:	dc.l	0,0

Message:
	dc.b	"AGILE PROUDLY PRESENTS",0
	dc.b	"ANOTHER PRETTY PACK",0
	dc.b	0
	dc.b	0
	dc.b	"THE HUNT FOR 7TH OCTOBER",0
	dc.b	"ANIMOTION",0
	dc.b	"THIRD DIMENSION",0
	dc.b	"AGILE MUSIC DISK",0
	dc.b	"SPIRIT PACK LOADER INTRO",0
	dc.b	0
	dc.b	0
	dc.b	"CREDITS:",0
	dc.b	0
	dc.b	"LAMER PROXO ..... X RATE FROMAGE ILE",0
	dc.b	"GREAT CODE ...... SPIRIT            ",0
	dc.b	"AMAZING THEME ... TEX               ",0
	dc.b	"LAME GFX ........ DICK              ",0
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
	move.w	#$ffff,BltAfwm(a5)
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
	add.w	#8,X
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

	move.w	#$ff00,d3

	lsr.b	#2,d1
	and.b	#1,d1
	beq.s	GoOnCalculating

	move.w	#$00ff,d3
	sub.w	#8,d0

GoOnCalculating:
	move.w	Y(pc),d1

	move.w	d0,d2
	lsr.w	#3,d0
	and.l	#$fffe,d0
	and.w	#$f,d2
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
Mask:		dc.w	0

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
	
	moveq	#0,d2

ContinueBendLoop:
	and.w	#$000f,d1
	moveq	#$0010,d3
	sub.w	d1,d3

	lsl.w	#8,d3
	lsl.w	#4,d3
	or.w	#$09f0,d3	

	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.w	d3,BltCon0(a5)
	move.w	#$0000,BltCon1(a5)
	move.l	#0,BltAmod(a5)
	move.l	a1,BltApth(a5)
	sub.l	d2,a1
	move.l	a1,BltDpth(a5)
	add.l	d2,a1
	move.w	#(64*1)+22,BltSize(a5)

	lea	24*2(a0),a0
	lea	44(a1),a1

	dbra	d0,IgnoreBendLoop
	rts

;; - Half-Bright Shadow Maker Routine -

; a0 = Bitplane Text Address
; a1 = Bitplane Shadow Address

HBShadow:
	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.w	#$0d0c,BltCon0(a5)
	move.w	#HShadow,d0
	lsl.w	#8,d0
	lsl.w	#4,d0
	move.w	d0,BltCon1(a5)
	move.l	#0,BltAmod(a5)
	move.w	#0,BltBmod(a5)
	move.l	a0,BltApth(a5)
	lea	-(44*VShadow)(a0),a0
	move.l	a0,BltBpth(a5)
	move.l	a1,BltDpth(a5)
	move.w	#(64*BarHeightMax)+22,BltSize(a5)
	rts

;; - Init Text Pointers -

InitTextPointers:
	lea	TextPointers(pc),a0

	move.l	#BText,d0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)

	move.l	#BShadow,d0
	move.w	d0,14(a0)
	swap	d0
	move.w	d0,10(a0)
	rts

;; - Init Logo Pointers -

InitLogoPointers:
	lea	LogoPointers(pc),a0
	move.l	#AgileLogo,d0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#44,d0
	move.w	d0,14(a0)
	swap	d0
	move.w	d0,10(a0)
	swap	d0
	add.l	#44,d0
	move.w	d0,22(a0)
	swap	d0
	move.w	d0,18(a0)
	swap	d0
	add.l	#44,d0
	move.w	d0,30(a0)
	swap	d0
	move.w	d0,26(a0)
	rts

;; - Logo Colors Control -

LogoColorsCtrl:
	jmp	WhitePart

WhitePart:
	lea	LogoColorsValues+6(pc),a0

	cmp.w	#$0fff,(a0)
	beq.s	RealLogoColorsPart

	moveq	#0,d0
	moveq	#15-1,d1

ToWhite:
	add.w	#$0111,(a0)
	addq.l	#4,a0
	dbra	d1,ToWhite
	rts

RealLogoColorsPart:
	move.l	#PutRealLogoColors,LogoColorsCtrl+2

PutRealLogoColors:
	lea	LogoColorsValues+6(pc),a0
	lea	LogoColorsTable(pc),a1
	moveq	#15-1,d2
	moveq	#0,d3

Red:
	move.w	(a0),d0
	and.w	#$0f00,d0
	move.w	(a1),d1
	and.w	#$0f00,d1
	cmp.w	d0,d1
	beq.s	Green

	sub.w	#$0100,(a0)

Green:
	move.w	(a0),d0
	and.w	#$00f0,d0
	move.w	(a1),d1
	and.w	#$00f0,d1
	cmp.w	d0,d1
	beq.s	Blue

	sub.w	#$0010,(a0)

Blue:
	move.w	(a0),d0
	and.w	#$000f,d0
	move.w	(a1),d1
	and.w	#$000f,d1
	cmp.w	d0,d1
	beq.s	NoMore

	sub.w	#$0001,(a0)

NoMore:
	move.w	(a0),d0
	cmp.w	(a1)+,d0
	bne.s	NotSameColor

	addq.w	#1,d3

NotSameColor:
	addq.w	#4,a0
	dbra	d2,Red
	cmp.w	#15,d3
	beq.s	NoMoreRGB
	rts

NoMoreRGB:
	move.w	#$4eb9,LogoCtrl		; $4e71 = nop
	move.l	#MouseCtrl,LogoCtrl+2

MusicOn:
	move.w	#$4eb9,MusicCtrl	; $4eb9 = jsr
	move.l	#Mt_Music,MusicCtrl+2	; jsr	Mt_Music
	rts

LogoColorsTable:
	dc.w	$0eef,$0dde,$0ccd,$0bad,$0aac,$099b,$088a,$0779
	dc.w	$0769,$0658,$0547,$0546,$0436,$0435,$0324

;; - Init Blitter in CopperList -

InitBlitCop:
	lea	BlitterInit(pc),a0
	move.l	#BarDesign,d0
	move.w	d0,22(a0)
	swap	d0
	move.w	d0,18(a0)

	move.l	#BarMask,d0
	move.w	d0,30(a0)
	swap	d0
	move.w	d0,26(a0)

	move.l	#BWork,d0
	move.w	d0,14(a0)
	move.w	d0,ClearLastLine+18
	swap	d0
	move.w	d0,10(a0)
	move.w	d0,34(a0)
	rts

;; - Init ScreenPointers in Copperlist -

InitScreenPointers:
	lea	ScreenPointers+4(pc),a0
	move.l	#BWork,d0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#60*2,d0
	move.w	d0,14(a0)
	swap	d0
	move.w	d0,10(a0)
	swap	d0
	add.l	#60*2,d0
	move.w	d0,22(a0)
	swap	d0
	move.w	d0,18(a0)
	swap	d0
	add.l	#60*2,d0
	move.w	d0,30(a0)
	swap	d0
	move.w	d0,26(a0)
	rts	

;; - Vertical Bars Routine -

VerticalBars:
	move.l	MotionPointer1(pc),a0
	move.l	MotionPointer2(pc),a1
	lea	BarsCopperList+6(pc),a2
	lea	BWork,a3
	move.w	#BarHeightMax-1,d0
	move.l	#$0000fffe,d3
	move.w	#$0fca,d4
	moveq	#$000f,d5

VerticalBarsLoop:
	move.w	(a0),d1
	add.w	(a1),d1
	lsr.w	#1,d1
	add.w	#270,d1
	move.w	d1,d2

	lsr.w	#3,d2
	and.w	d3,d2
	add.w	a3,d2
	move.w	d2,8(a2)
	move.w	d2,12(a2)

	and.w	d5,d1
	ror.w	#4,d1
	move.w	d1,4(a2)

	or.w	d4,d1
	move.w	d1,(a2)

	lea	24*2(a2),a2

MotionControl1:
	lea	2*MotionStep1(a0),a0
	cmp.l	#MotionTable1End,a0
	blt.s	MotionControl2

	lea	-(MotionTable1End-MotionTable1)(a0),a0

MotionControl2:
	lea	-2*MotionStep3(a1),a1
	cmp.l	#MotionTable2,a1
	bge.s	ContinueBarsLoop

	lea	(MotionTable2End-MotionTable2)(a1),a1

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

;; - Build Bars CopperList Routine -

BuildBarsCopperList:
	lea	BarsCopperList(pc),a0
	lea	BWork,a1
	move.w	#BarHeightMax-1,d0
	move.b	#BarsStartLine,d1
	move.l	#BarMask,d2
	move.l	#280,d3
	bra.s	BlitterTransferCop

BuildBarsCopperListLoop:
	move.b	d1,(a0)+
	addq.b	#1,d1
	move.b	#$e1,(a0)+
	move.w	#$fffe,(a0)+

	move.w	d3,d4
	move.w	d3,d5
	subq.w	#1,d3

	lsr.w	#3,d4
	and.w	#$fffe,d4
	add.w	a1,d4

	and.w	#$000f,d5
	move.w	#$000f,d6
	sub.w	d5,d6

	move.w	#$00e2,(a0)+
	move.w	d4,(a0)+
	add.w	#60*2,d4
	move.w	#$00e6,(a0)+
	move.w	d4,(a0)+
	add.w	#60*2,d4
	move.w	#$00ea,(a0)+
	move.w	d4,(a0)+
	add.w	#60*2,d4
	move.w	#$00ee,(a0)+
	move.w	d4,(a0)+
	move.w	#$0102,(a0)+
	move.w	d6,(a0)
	lsl.w	#4,d6
	or.w	d6,(a0)+

BlitterTransferCop:
	move.b	d1,(a0)+
	move.b	#$71,(a0)+
	move.w	#$fffe,(a0)+
	move.l	#$00400fca,(a0)+	; BltCon0
	move.l	#$00420000,(a0)+	; BltCon1
	move.w	#$004a,(a0)+		; BltCptl
	move.w	#$0000,(a0)+
	move.w	#$0056,(a0)+		; BltDptl
	move.w	#$0000,(a0)+
	move.w	#$0058,(a0)+		; BltSize
	move.w	#64*4+2,(a0)+
	dbra	d0,BuildBarsCopperListLoop
	rts

;; - Build Bar Design Routine -

BuildBarDesign:
	lea	BarDesign,a0
	move.w	#BarHeightMax-1,d0

BuildBarDesignLoop:
	move.l	#%10101010010101010000000000000000,(a0)+
	move.l	#%01100110001100110000000000000000,(a0)+
	move.l	#%00011110000011110000000000000000,(a0)+
	move.l	#%00000001111111110000000000000000,(a0)+

	dbra	d0,BuildBarDesignLoop
	rts

;; - Raster Cycle Routine -

RasterCycle:
	WaitBlitter
	move.l	#$ffffffff,BltAfwm(a5)
	move.l	#$09f00000,BltCon0(a5)
	move.l	#2^16*2+2,BltAmod(a5)
	move.l	#FirstCycling+6+4,BltApth(a5)
	move.l	#FirstCycling+6,BltDpth(a5)
	move.w	#64*[(352/8)-1]+1,BltSize(a5)

	WaitBlitter
	move.w	#$0002,BltCon1(a5)
	move.l	#SecondCycling+6+[[(352/8)-2]*4],BltApth(a5)
	move.l	#SecondCycling+6+[[(352/8)-1]*4],BltDpth(a5)
	move.w	#64*[(352/8)-1]+1,BltSize(a5)

	move.l	ColorPointer(pc),a0
	move.w	(a0),FirstCycling+6+[[(352/8)-1]*4]
	move.w	(a0),SecondCycling+6

	addq.l	#2,ColorPointer
	cmp.l	#RasterColorsEnd,ColorPointer
	bne.s	RasterCycleEnd

	move.l	#RasterColors,ColorPointer

RasterCycleEnd:
	rts

ColorPointer:	dc.l	RasterColors

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

;; - Display Coder Name Routine -

; a1 = Bitplane Address

DisplayCoderName:
	move.l	CoderName+00(pc),44*0(a1)
	move.l	CoderName+04(pc),44*1(a1)
	move.l	CoderName+08(pc),44*2(a1)
	move.l	CoderName+12(pc),44*3(a1)
	move.l	CoderName+16(pc),44*4(a1)
	move.l	#BName,d0
	move.w	d0,NamePointers+6
	swap	d0
	move.w	d0,NamePointers+2
	rts

CoderName:	
	dc.l	%00001111011110101111010111100000
	dc.l	%00001000010010101001010000100000
	dc.l	%00001111011110101111010000100000
	dc.l	%00000001010000101010010000100000
	dc.l	%00001111010000101001010000100000

;; - NoiseTracker V2.0 Fast Replay Routine -

Mt_Init:
	lea	Mt_Data,a0
	lea	Mt_Mulu(pc),a1
	move.l	#Mt_Data+$c,d0
	moveq	#$1f,d1
	moveq	#$1e,d3

Mt_Lop4:
	move.l	d0,(a1)+
	add.l	d3,d0
	dbf	d1,Mt_Lop4

	lea	$3b8(a0),a1
	moveq	#$7f,d0
	moveq	#0,d1
	moveq	#0,d2

Mt_Lop2:
	move.b	(a1)+,d1
	cmp.b	d2,d1
	ble.s	Mt_Lop
	move.l	d1,d2

Mt_Lop:
	dbf	d0,Mt_Lop2
	addq.w	#1,d2

	swap	d2
	lsr.l	#6,d2
	lea	4(a1,d2.l),a2
	lea	Mt_Samplestarts(pc),a1
	add.w	#$2a,a0
	moveq	#$1e,d0

Mt_Lop3:
	clr.l	(a2)
	move.l	a2,(a1)+
	moveq	#0,d1
	move.b	d1,2(a0)
	move.w	(a0),d1
	add.l	d1,d1
	add.l	d1,a2
	add.l	d3,a0
	dbf	d0,Mt_Lop3

	move.l	$78.w,Mt_Irq+2-Mt_Samplestarts-$7c(a1)
	or.b	#2,$bfe001
	move.b	#6,Mt_Spd+3-Mt_Samplestarts-$7c(a1)
	moveq	#0,d0
	move.b	d0,Mt_Song+3-Mt_Samplestarts-$7c(a1)
	move.b	d0,Mt_Cou+1-Mt_Samplestarts-$7c(a1)
	move.w	d0,Mt_Patt+2-Mt_Samplestarts-$7c(a1)
	lea	$dff000,a0
	move.w	d0,$a8(a0)
	move.w	d0,$b8(a0)
	move.w	d0,$c8(a0)
	move.w	d0,$d8(a0)
	move.w	#$f,$dff096
	rts

Mt_End:
	moveq	#0,d0
	lea	$dff000,a0
	move.b	d0,$bfde00
	move.b	#$7f,$bfdd00
	move.w	#$2000,$9c(a0)
	move.w	#$2000,$9a(a0)
	move.l	Mt_Irq+2(pc),$78.w
	move.w	d0,$a8(a0)
	move.w	d0,$b8(a0)
	move.w	d0,$c8(a0)
	move.w	d0,$d8(a0)
	move.w	#$f,$dff096
	rts

Mt_Nonew:	
	lea	$dff0a0,a5
	jsr	Mt_Com(pc)
	lea	Mt_Voice2(pc),a4
	lea	$10(a5),a5
	jsr	Mt_Com(pc)
	lea	Mt_Voice3(pc),a4
	lea	$10(a5),a5
	jsr	Mt_Com(pc)
	lea	Mt_Voice4(pc),a4
	lea	$10(a5),a5
	jsr	Mt_Com(pc)
	tst.b	Mt_Brk+3-Mt_Voice4(a4)
	bne.L	Mt_Next
	rts

Mt_Music:	
	move.w	#$fff,d4
	moveq	#$f,d5
	move.w	#$f0,d6
	moveq	#0,d7
	lea	Mt_Voice1(pc),a4
	addq.b	#1,Mt_Cou+1-Mt_Voice1(a4)
	lea	Mt_Data,a0

Mt_Cou:
	moveq	#0,d0

Mt_Spd:
	cmp.b	#6,d0
	blt.s	Mt_Nonew
	move.b	d7,Mt_Cou+1-Mt_Voice1(a4)
	move.w	d7,Mt_Dma+2-Mt_Voice1(a4)
	lea	Mt_Data,a0
	lea	$3b8(a0),a2
	lea	$43c(a0),a0

	moveq	#0,d1
	moveq	#0,d0

Mt_Song:
	move.b	#0,d0
	move.b	(a2,d0.w),d1
	swap	d1
	lsr.l	#6,d1

Mt_Patt:
	add.w	#0,d1
	lea	(a0,d1.l),a0
	lea	$dff0a0,a5
	lea	Mt_Samplestarts-4(pc),a1
	jsr	Mt_Playvoice(pc)
	lea	$10(a5),a5
	lea	Mt_Voice2(pc),a4
	jsr	Mt_Playvoice(pc)
	lea	$10(a5),a5
	lea	Mt_Voice3(pc),a4
	jsr	Mt_Playvoice(pc)
	lea	$10(a5),a5
	lea	Mt_Voice4(pc),a4
	jsr	Mt_Playvoice(pc)

Mt_Dma:
	move.w	#0,d0
	beq.s	Mt_Nodma

	lea	$bfd000,a3
	move.b	#$7f,$d00(a3)
	move.w	#$2000,$dff09c
	move.w	#$a000,$dff09a
	move.l	#Mt_Irq1,$78.w
	move.b	d7,$e00(a3)
	move.b	#$aa,$400(a3)
	move.b	d7,$500(a3)
	or.w	#$8000,Mt_Dma+2-Mt_Voice4(a4)
	move.b	#$11,$e00(a3)
	move.b	#$81,$d00(a3)

Mt_Nodma:	
	add.w	#$10,Mt_Patt+2-Mt_Voice4(a4)
	cmp.w	#$400,Mt_Patt+2-Mt_Voice4(a4)
	bne.s	Mt_Exit

Mt_Next:
	move.w	d7,Mt_Patt+2-Mt_Voice4(a4)
	move.b	d7,Mt_Brk+3-Mt_Voice4(a4)
	addq.b	#1,Mt_Song+3-Mt_Voice4(a4)
	move.b	-2(a2),d0
	cmp.b	Mt_Song+3(pc),d0
	bne.s	Mt_Exit
	move.b	-1(a2),Mt_Song+3-Mt_Voice4(a4)

Mt_Exit:	

Mt_Brk:
	move.b	#0,d0
	bne.s	Mt_Next
	rts

Mt_Irq1:
	tst.b	$bfdd00
	move.w	Mt_Dma+2(pc),$dff096
	move.l	#Mt_Irq2,$78.w
	move.w	#$2000,$dff09c
	rte

Mt_Irq2:
	tst.b	$bfdd00
	movem.l	a3/a4,-(a7)
	lea	Mt_Voice1(pc),a4
	lea	$dff000,a3
	move.l	$a(a4),$a0(a3)
	move.w	$e(a4),$a4(a3)
	move.w	$12(a4),$a8(a3)
	move.l	$28(a4),$b0(a3)
	move.w	$2c(a4),$b4(a3)
	move.w	$30(a4),$b8(a3)
	move.l	$46(a4),$c0(a3)
	move.w	$4a(a4),$c4(a3)
	move.w	$4e(a4),$c8(a3)
	move.l	$64(a4),$d0(a3)
	move.w	$68(a4),$d4(a3)
	move.w	$6c(a4),$d8(a3)
	movem.l	(a7)+,a3/a4
	move.b	#0,$bfde00
	move.b	#$7f,$bfdd00

Mt_Irq:
	move.l	#0,$78.w
	move.w	#$2000,$dff09c
	move.w	#$2000,$dff09a
	rte

Mt_Playvoice:	
	move.l	(a0)+,(a4)
	moveq	#0,d2
	move.b	2(a4),d2
	lsr.b	#4,d2
	move.b	(a4),d0
	and.b	d6,d0
	or.b	d0,d2
	beq.L	Mt_Oldinstr
	add.w	d2,d2
	add.w	d2,d2
	move.l	Mt_Mulu(pc,d2.w),a3
	move.l	(a1,d2.l),4(a4)
	move.w	(a3)+,8(a4)
	move.w	(a3)+,$12(a4)
	move.l	4(a4),d0
	move.w	(a3)+,d3
	beq.L	Mt_Noloop
	ext.l	d3
	add.w	d3,d3
	add.l	d3,d0
	move.l	d0,$a(a4)
	move.w	-2(a3),d0
	add.w	(a3),d0
	move.w	d0,8(a4)
	bra.L	Mt_HejaSverige

Mt_Mulu:
	blk.l	$20,0

Mt_Setport:	
	move.w	(a4),d2
	and.w	d4,d2
	move.w	d2,$16(a4)
	move.w	$10(a4),d0
	move.b	d7,$14(a4)
	cmp.w	d0,d2
	beq.s	Mt_Clrport
	bge.s	Mt_Com2
	move.b	#1,$14(a4)
	bra.s	Mt_Com2

Mt_Clrport:	
	move.w	d7,$16(a4)
	rts

Mt_Noloop:	
	move.l	d0,$a(a4)

Mt_HejaSverige:	
	move.w	(a3),$e(a4)

Mt_Oldinstr:	
	move.w	(a4),d3
	and.w	d4,d3
	beq.s	Mt_Com2
	tst.w	8(a4)
	beq.s	Mt_Stopsound
	move.b	2(a4),d0
	and.b	d5,d0
	subq.b	#3,d0
	beq.s	Mt_Setport
	subq.b	#2,d0
	beq.s	Mt_Setport
	move.w	d3,$10(a4)
	move.w	$1c(a4),$dff096
	move.b	d7,$19(a4)
	move.l	4(a4),(a5)
	move.w	8(a4),4(a5)
	move.w	$10(a4),6(a5)
	move.w	$1c(a4),d0
	or.w	d0,Mt_Dma+2-[Mt_Samplestarts-4](a1)

Mt_Com2:
	move.b	2(a4),d0
	and.b	d5,d0
	beq.s	Mt_Rts2
	sub.b	d5,d0
	beq.s	Mt_Setspeed
	addq.b	#1,d0
	beq.s	Mt_Filter
	addq.b	#1,d0
	beq.s	Mt_Pattbreak
	addq.b	#1,d0
	beq.s	Mt_Setvol
	addq.b	#1,d0
	beq.s	Mt_Songjmp

Mt_Rts2:
	rts

Mt_Stopsound:	
	move.w	$1c(a4),$dff096
	bra.s	Mt_Com2

Mt_Filter:	
	move.b	3(a4),d0
	and.b	#1,d0
	add.b	d0,d0
	and.b	#$fd,$bfe001
	or.b	d0,$bfe001
	rts

Mt_Pattbreak:	
	move.b	#1,Mt_Brk+3-[Mt_Samplestarts-4](a1)
	rts

Mt_Songjmp:	
	move.b	3(a4),d0
	subq.b	#1,d0
	move.b	#1,Mt_Brk+3-[Mt_Samplestarts-4](a1)
	move.b	d0,Mt_Song+3-[Mt_Samplestarts-4](a1)
	rts

Mt_Setvol:	
	moveq	#0,d0
	move.b	3(a4),d0
	cmp.b	#$40,d0
	bls.s	Mt_Sv2
	move.b	#$40,d0

Mt_Sv2:
	move.b	d0,$13(a4)
	move.w	d0,8(a5)
	rts

Mt_Setspeed:	
	move.b	3(a4),d0
	cmp.b	#$1f,d0
	bls.s	Mt_Sp2
	moveq	#$1f,d0

Mt_Sp2:
	tst.w	d0
	bne.s	Mt_Sp3
	moveq	#1,d0

Mt_Sp3:
	move.b	d0,Mt_Spd+3-[Mt_Samplestarts-4](a1)
	rts

Mt_Port:
	move.b	3(a4),d2
	beq.s	Mt_Port2
	move.b	d2,$15(a4)
	clr.b	3(a4)

Mt_Port2:	
	moveq	#0,d0
	tst.w	$16(a4)
	beq.s	Mt_Rts
	move.b	$15(a4),d0
	tst.b	$14(a4)
	bne.s	Mt_Sub
	add.w	d0,$10(a4)
	move.w	$16(a4),d0
	cmp.w	$10(a4),d0
	bgt.s	Mt_Portok
	move.w	$16(a4),$10(a4)
	move.w	d7,$16(a4)

Mt_Portok:	
	move.w	$10(a4),6(a5)

Mt_Rts:
	rts

Mt_Sub:
	sub.w	d0,$10(a4)
	move.w	$16(a4),d0
	cmp.w	$10(a4),d0
	blt.s	Mt_Portok
	move.w	$16(a4),$10(a4)
	move.w	d7,$16(a4)
	move.w	$10(a4),6(a5)
	rts

Mt_Vib:
	move.b	$3(a4),d0
	beq.s	Mt_Vib2
	move.b	d0,$18(a4)

Mt_Vib2:
	move.b	$19(a4),d0
	move.w	d0,d2
	lsr.w	#2,d0
	and.w	#$1f,d0
	move.b	$18(a4),d1
	and.w	d5,d1
	asl.w	#5,d1
	add.w	d1,d0
	moveq	#0,d1
	move.b	Mt_Sin(pc,d0.w),d1

	tst.b	d2
	bmi.s	Mt_Vibsub
	move.w	$10(a4),d2
	add.w	d1,d2
	bra.s	Mt_Vib3

Mt_Vibsub:	
	move.w	$10(a4),d2
	sub.w	d1,d2

Mt_Vib3:
	move.w	d2,6(a5)
	move.b	$18(a4),d0
	lsr.w	#2,d0
	and.w	#$3c,d0
	add.b	d0,$19(a4)
	rts

Mt_Sin:	
	dc.l 0,0,0,0,0,0,0,0
	dc.l $00000000,$00000101,$01010101,$01010101,$01010101,$01010101
	dc.l $01000000,$00000000,$00000001,$01010202,$02030303,$03030303
	dc.l $03030303,$03030303,$02020201,$01010000,$00000101,$02020303
	dc.l $04040405,$05050505,$05050505,$05050404,$04030302,$02010100
	dc.l $00000102,$03030405,$05060607,$07070707,$07070707,$07070606
	dc.l $05050403,$03020100,$00000102,$03040506,$07070808,$09090909
	dc.l $09090909,$09080807,$07060504,$03020100,$00010203,$04050607
	dc.l $0809090a,$0b0b0b0b,$0b0b0b0b,$0b0a0909,$08070605,$04030201
	dc.l $00010204,$05060708,$090a0b0c,$0c0d0d0d,$0d0d0d0d,$0c0c0b0a
	dc.l $09080706,$05040201,$00010304,$0607080a,$0b0c0d0e,$0e0f0f0f
	dc.l $0f0f0f0f,$0e0e0d0c,$0b0a0807,$06040301,$00010305,$0608090b
	dc.l $0c0d0e0f,$10111111,$11111111,$100f0e0d,$0c0b0908,$06050301
	dc.l $00010305,$07090b0c,$0e0f1011,$12131313,$13131313,$1211100f
	dc.l $0e0c0b09,$07050301,$00020406,$080a0c0d,$0f101213,$14141515
	dc.l $15151514,$14131210,$0f0d0c0a,$08060402,$00020406,$090b0d0f
	dc.l $10121315,$16161717,$17171716,$16151312,$100f0d0b,$09060402
	dc.l $00020407,$090c0e10,$12141516,$17181919,$19191918,$17161514
	dc.l $12100e0c,$09070402,$00020508,$0a0d0f11,$13151719,$191a1b1b
	dc.l $1b1b1b1a,$19181715,$13110f0d,$0a080502,$00020508,$0b0e1012
	dc.l $1517181a,$1b1c1d1d,$1d1d1d1c,$1b1a1817,$1512100e,$0b080502

Mt_Arplist:	
	dc.b	0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0
	dc.b	1,2,0,1,2,0,1,2,0,1,2,0,1,2,0,1

Mt_Arp:
	moveq	#0,d0
	move.b	Mt_Cou+1(pc),d0
	move.b	Mt_Arplist(pc,d0.w),d0
	beq.L	Mt_Normper
	subq.b	#2,d0
	beq.s	Mt_Arp2

Mt_Arp1:
	move.b	3(a4),d0
	lsr.w	#4,d0
	bra.s	Mt_Arpdo

Mt_Arp2:
	move.b	3(a4),d0
	and.w	d5,d0

Mt_Arpdo:	
	add.w	d0,d0
	move.w	$10(a4),d1
	lsr.w	#2,d1
	add.b	Mt_Arp3-$1c(pc,d1.w),d0
	lea	Mt_Periods(pc),a0
	move.w	(a0,d0.w),6(a5)
	rts

Mt_Arp3:	
	dc.l $46004442,$0040003e,$003c0000,$3a003800,$00360034,$00003200
	dc.l $00300000,$2e000000,$2c00002a,$00000028,$00000026,$00000024
	dc.l $00000000,$22000000,$20000000,$00001e00,$0000001c,$00000000
	dc.l $001a0000,$00000018,$00000000,$00160000,$00000000,$14000000
	dc.l $00000012,$00000000,$00001000,$00000000,$00000e00,$00000000
	dc.l $0000000c,$00000000,$00000000,$0a000000,$00000000,$00080000
	dc.l $00000000,$00000000,$06000000,$00000000,$00000400,$00000000
	dc.l $00000000,$200,0,0,0

Mt_Normper:	
	move.w	$10(a4),6(a5)
	rts

Mt_Com:
	move.w	2(a4),d0
	and.w	d4,d0
	beq.s	Mt_Normper
	move.b	2(a4),d0
	and.b	d5,d0
	beq.L	Mt_Arp
	subq.b	#1,d0
	beq.s	Mt_Portup
	subq.b	#1,d0
	beq.s	Mt_Portdown
	subq.b	#1,d0
	beq.L	Mt_Port
	subq.b	#1,d0
	beq.L	Mt_Vib
	subq.b	#1,d0
	beq.s	Mt_Volport
	subq.b	#1,d0
	beq.s	Mt_Volvib
	move.w	$10(a4),6(a5)
	subq.b	#4,d0
	beq.s	Mt_Volslide
	rts

Mt_Portup:	
	moveq	#0,d0
	move.b	3(a4),d0
	sub.w	d0,$10(a4)
	move.w	$10(a4),d0
	cmp.w	#$71,d0
	bpl.s	Mt_Portup2
	move.w	#$71,$10(a4)

Mt_Portup2:	
	move.w	$10(a4),6(a5)
	rts

Mt_Portdown:	
	moveq	#0,d0
	move.b	3(a4),d0
	add.w	d0,$10(a4)
	move.w	$10(a4),d0
	cmp.w	#$358,d0
	bmi.s	Mt_Portdown2
	move.w	#$358,$10(a4)

Mt_Portdown2:	
	move.w	$10(a4),6(a5)
	rts

Mt_Volvib:	
	bsr.l	Mt_Vib2
	bra.s	Mt_Volslide

Mt_Volport:	
	bsr.l	Mt_Port2

Mt_Volslide:	
	move.b	3(a4),d0
	move.w	d0,d1
	and.b	d5,d0
	beq.s	Mt_Vol3
	sub.b	d0,$13(a4)
	bpl.s	Mt_Vol2
	move.b	d7,$13(a4)

Mt_Vol2:
	move.w	$12(a4),8(a5)
	rts

Mt_Vol3:
	lsr.b	#4,d1
	add.b	d1,$13(a4)
	cmp.b	#$40,$13(a4)
	bmi.s	Mt_Vol2
	move.b	#$40,$13(a4)
	move.w	$12(a4),8(a5)
	rts

Mt_Periods:	
	dc.w	$358,$328,$2fa,$2d0,$2a6,$280,$25c,$23a,$21a
	dc.w	$1fc,$1e0,$1c5,$1ac,$194,$17d,$168,$153,$140
	dc.w	$12e,$11d,$10d,$fe,$f0,$e2,$d6,$ca,$be,$b4,$aa
	dc.w	$a0,$97,$8f,$87,$7f,$78,$71,0

Mt_Samplestarts:
	blk.l	$1f,0

Mt_Voice1:
	blk.w	14,0
	dc.w	1

Mt_Voice2:
	blk.w	14,0
	dc.w	2

Mt_Voice3:
	blk.w	14,0
	dc.w	4

Mt_Voice4:
	blk.w	14,0
	dc.w	8

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

LogoColorsValues:
	dc.w	$0180,$0000,$0182,$0000,$0184,$0000,$0186,$0000
	dc.w	$0188,$0000,$018a,$0000,$018c,$0000,$018e,$0000
	dc.w	$0190,$0000,$0192,$0000,$0194,$0000,$0196,$0000
	dc.w	$0198,$0000,$019a,$0000,$019c,$0000,$019e,$0000

LogoCop:
	dc.b	LogoLine-1,$09
	dc.w	$fffe

LogoModulos:
	dc.w	$0108,44*3,$010a,44*3

LogoPointers:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000

	dc.b	LogoLine,$09
	dc.w	$fffe
	dc.w	$0100,$4200

	dc.b	LogoLine+LogoHeight,$09
	dc.w	$fffe
	dc.w	$0100,$0000

	dc.w	$0092,$0028,$0094,$00d0
	dc.w	$0108,0,$010a,0

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

	dc.w	$01a0,$000f,$01a2,$000f,$01a4,$000f,$01a6,$000f
	dc.w	$01a8,$000f,$01aa,$000f,$01ac,$000f,$01ae,$000f
	dc.w	$01b0,$000f,$01b2,$000f,$01b4,$000f,$01b6,$000f
	dc.w	$01b8,$000f,$01ba,$000f,$01bc,$000f,$01be,$000f

ScreenPointers:
	dc.b	LogoLine+LogoHeight+1,$09
	dc.w	$fffe
	dc.w	$00e0,$0000,$00e2,$0000	; Must be initialized
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000

TextPointers:
	dc.w	$00f0,$0000,$00f2,$0000
	dc.w	$00f4,$0000,$00f6,$0000

BlitterInit:				;             Initialized ?
	dc.w	$0044,$ffff		; BltAfwm	   Y
	dc.w	$0046,$0000		; BltAlwm          Y
	dc.w	$0048,$0000		; BltCpth	   N
	dc.w	$004a,$0000		; BltCptl          Y
	dc.w	$004c,$0000		; BltBpth          N
	dc.w	$004e,$0000		; BltBptl          N
	dc.w	$0050,$0000		; BltApth          N
	dc.w	$0052,$0000		; BltAptl          N
	dc.w	$0054,$0000		; BltDpth          N
	dc.w	$0060,(60-2)*2		; BltCmod          Y
	dc.w	$0062,0			; BltBmod          Y
	dc.w	$0064,0			; BltAmod          Y
	dc.w	$0066,(60-2)*2		; BltDmod          Y

FirstCycling:
	dc.b	BarsStartLine-1,$39
	dc.w	$fffe
	blk.l	(352/8)+1,$01800000

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
	blk.l	(352/8)+1,$01800000

	dc.b	(BarsStartLine+BarHeightMax+2-$100),$09
	dc.w	$fffe

NamePointers:
	dc.w	$00e0,$0000,$00e2,$0000

	dc.w	$0092,$0030,$0094,$00d8
	dc.w	$0102,$0000
	dc.w	$0108,0,$010a,0
	dc.w	$0182,$0fff

	dc.b	(BarsStartLine+BarHeightMax+3-$100),$09
	dc.w	$fffe

	dc.w	$0100,$1200
	dc.w	$0182,$0fff

	dc.b	(BarsStartLine+BarHeightMax+3+1-$100),$09
	dc.w	$fffe
	dc.w	$0182,$0eee

	dc.b	(BarsStartLine+BarHeightMax+3+2-$100),$09
	dc.w	$fffe
	dc.w	$0182,$0ddd

	dc.b	(BarsStartLine+BarHeightMax+3+3-$100),$09
	dc.w	$fffe
	dc.w	$0182,$0ccc

	dc.b	(BarsStartLine+BarHeightMax+3+4-$100),$09
	dc.w	$fffe
	dc.w	$0182,$0bbb

	dc.b	(BarsStartLine+BarHeightMax+3+5-$100),$09
	dc.w	$fffe
	dc.w	$0100,$0000

ClearLastLine:
	dc.b	(BarsStartLine+BarHeightMax+3+5+1-$100),$09
	dc.w	$fffe
	dc.w	$0066,0			; BltDmod          Y
	dc.w	$0040,$0100		; BltCon0          Y
	dc.w	$0042,$0000		; BltCon1          Y
	dc.w	$0056,$0000		; BltDptl          N
	dc.w	$0058,(64*4+60)		; BltSize          Y

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

Font:		incbin	TFTDD:Pictures/SubFont1
AgileLogo:	incbin	TFTDD:Pictures/AgileLogo1
Mt_Data:	incbin	TFTDD:Modules/mod.Sad-Strings
BarMask:	blk.l	BarHeightMax*4,$ffff0000
BName:		ds.b	(44*5)
BarDesign:	ds.l	BarHeightMax*4
		blk.b	(44*VShadow),0
BText:		ds.b	(44*BarHeightMax)
BShadow:	ds.b	(44*BarHeightMax)
BWork:		ds.b	(60*2*4)
