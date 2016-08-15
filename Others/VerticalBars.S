; ******************************
; *                            *
; * Title: Vertical Bars       *
; *                            *
; * Coder: Spirit              *
; * Date : May 1991            *
; *                            *
; * Infos: Pseudo Vertical     *
; *        Raster Bars         *
; *                            *
; ******************************

;
;; ---- REGISTERS VALUES ----
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

BarsStartLine	= $2c
BarHeightMax	= 256

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

;; - Clear Mem Macro -

; Syntax = ClrMem Address,Width,Height

ClrMem:		MACRO
	WaitBlitter
	move.w	#$0100,BltCon0(a5)
	move.w	#0,BltCon1(a5)
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
	move.w	#%1000001111000000,$096(a5)
	move.w	#$7fff,$09a(a5)
	move.w	#%1100000000100000,$09a(a5)

	move.l	#CopperList,$080(a5)
	clr.w	$088(a5)

	ClrMem	BWork,64,4
	bsr	BuildBarDesign
	bsr	BuildBarsCopperList
	bsr	InitBlitCop
	bsr	InitScreenPointers

	move.w	#%0000000000000010,$02e(a5)

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

	btst	#10,$016(a5)
	beq.s	GoOnIrq3

	bsr	VerticalBars

GoOnIrq3:
	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

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
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	add.l	#64*2,d0
	swap	d0
	move.w	d0,6(a0)
	swap	d0
	add.l	#64*2,d0
	swap	d0
	move.w	d0,10(a0)
	swap	d0
	add.l	#64*2,d0
	swap	d0
	move.w	d0,14(a0)
	rts	

;; - Vertical Bars Routine -

VerticalBars:
	move.l	MotionPointer1(pc),a0
	move.l	MotionPointer2(pc),a1
	lea	BarsCopperList+6(pc),a2
	lea	BWork(pc),a3
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
	lea	BWork(pc),a1
	move.w	#BarHeightMax-1,d0
	move.b	#BarsStartLine,d1
	move.l	#BarMask,d2
	move.l	#330,d3
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
	add.w	#64*2,d4
	move.w	#$00e6,(a0)+
	move.w	d4,(a0)+
	add.w	#64*2,d4
	move.w	#$00ea,(a0)+
	move.w	d4,(a0)+
	add.w	#64*2,d4
	move.w	#$00ee,(a0)+
	move.w	d4,(a0)+
	move.w	#$0102,(a0)+
	move.w	d6,(a0)
	lsl.w	#4,d6
	or.w	d6,(a0)+

BlitterTransferCop:
	move.b	d1,(a0)+
	move.b	#$a1,(a0)+
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
	lea	BarDesign(pc),a0
	move.w	#BarHeightMax-1,d0

BuildBarDesignLoop:
	move.l	#%10101010010101010000000000000000,(a0)+
	move.l	#%01100110001100110000000000000000,(a0)+
	move.l	#%00011110000011110000000000000000,(a0)+
	move.l	#%00000001111111110000000000000000,(a0)+

	dbra	d0,BuildBarDesignLoop
	rts

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
	dc.w	$0108,0,$010a,0

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

ScreenPointers:
	dc.w	$2a09,$fffe
	dc.w	$00e0,$0000		; Must be initialized
	dc.w	$00e4,$0000
	dc.w	$00e8,$0000
	dc.w	$00ec,$0000

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
	dc.w	$0060,(64-2)*2		; BltCmod          Y
	dc.w	$0062,0			; BltBmod          Y
	dc.w	$0064,0			; BltAmod          Y
	dc.w	$0066,(64-2)*2		; BltDmod          Y

	dc.b	BarsStartLine,$09
	dc.w	$fffe
	dc.w	$0100,$4200

BarsCopperList:
	blk.w	(24*BarHeightMax)-12,0

	dc.b	(BarsStartLine+BarHeightMax-$100),$09
	dc.w	$fffe
	dc.w	$0100,$0000

	dc.b	(BarsStartLine+BarHeightMax+8-$100),$09
	dc.w	$fffe
	dc.w	$0100,$0000

ClearLastLine:
	dc.b	(BarsStartLine+BarHeightMax+9-$100),$09
	dc.w	$fffe
	dc.w	$0066,0			; BltDmod          Y
	dc.w	$0040,$0100		; BltCon0          Y
	dc.w	$0042,$0000		; BltCon1          Y
	dc.w	$0056,$0000		; BltDptl          N
	dc.w	$0058,(64*4+64)		; BltSize          Y

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

BarDesign:	blk.l	BarHeightMax*4,0
BarMask:	blk.l	BarHeightMax*4,$ffff0000
BWork:		ds.b	(64*2*4)
