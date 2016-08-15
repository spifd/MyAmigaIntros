; ******************************
; *                            *
; * Title: Fade Picture        *
; *                            *
; * Coder: Spirit              *
; * Date : May 1991            *
; *                            *
; * Infos: Fade Picture        *
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

; - Others -

PictureStartLine	= $2c
PictureHeight		= 190
FadeDelay		= 4

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

	bsr	InitPicturePointers

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

PicColCtrl:
	bsr	FadePicture

	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Init Screen Pointers -

InitPicturePointers:
	lea	PicturePointers(pc),a0
	move.l	#Picture,d0
	moveq	#40,d1
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
	rts

;; - Fade Pictures Routine -

FadePicture:
	subq.b	#1,FadeFlag
	beq.s	GoAndFade

	rts

GoAndFade:
	move.b	#FadeDelay,FadeFlag

	lea	ScreenColors+2(pc),a0
	lea	PictureColorsTable(pc),a1

	moveq	#32-1,d6
	moveq	#0,d7

Blue:
	move.w	(a0),d0
	move.w	(a1)+,d1
	moveq	#$000f,d4
	moveq	#$0001,d5

	move.w	d0,d2
	move.w	d1,d3

	and.w	d4,d2
	and.w	d4,d3
	cmp.w	d2,d3
	beq.s	Green

	add.w	d5,d0

Green:
	lsl.w	#4,d4
	lsl.w	#4,d5

	move.w	d0,d2
	move.w	d1,d3

	and.w	d4,d2
	and.w	d4,d3
	cmp.w	d2,d3
	beq.s	Red

	add.w	d5,d0

Red:
	lsl.w	#4,d4
	lsl.w	#4,d5

	move.w	d0,d2
	move.w	d1,d3

	and.w	d4,d2
	and.w	d4,d3
	cmp.w	d2,d3
	beq.s	TestIfRGBequal

	add.w	d5,d0

	move.w	d0,(a0)

TestIfRGBequal:
	cmp.w	d0,d1
	bne.s	NotSameColor

	addq.w	#1,d7

NotSameColor:
	addq.l	#4,a0
	dbra	d6,Blue

	cmp.w	#32-1,d7
	beq.s	FadingEnd

	rts

FadingEnd:
	move.l	#$4e714e71,PicColCtrl		; $4e71 = nop
	rts

FadeFlag:	dc.b	FadeDelay
		even

PictureColorsTable:
	dc.w	$0000,$0fff,$0eee,$0ddd
	dc.w	$0ccc,$0bbb,$0aaa,$0999
	dc.w	$0777,$0666,$0555,$0444
	dc.w	$0333,$0222,$0cef,$0f00
	dc.w	$0320,$0420,$0530,$0630
	dc.w	$0740,$0850,$0960,$0a60
	dc.w	$0b70,$0c80,$0c92,$0ca4
	dc.w	$0dc6,$0ed8,$0eea,$0ffd

;; - Save & Restore All Routine -

	INCLUDE	TFTSD:Help/Save&RestoreAll.S

;
;; ---- COPPERLIST ----
;

CopperList:
	dc.w	$0100,$0000
	dc.w	$008e,$2971,$0090,$29e1
	dc.w	$0092,$0038,$0094,$00d0
	dc.w	$0102,$0000,$0104,$0000

	dc.w	$0108,40*4,$010a,40*4

ScreenColors:
	dc.w	$0180,$0000,$0182,$0000,$0184,$0000,$0186,$0000
	dc.w	$0188,$0000,$018a,$0000,$018c,$0000,$018e,$0000
	dc.w	$0190,$0000,$0192,$0000,$0194,$0000,$0196,$0000
	dc.w	$0198,$0000,$019a,$0000,$019c,$0000,$019e,$0000
	dc.w	$01a0,$0000,$01a2,$0000,$01a4,$0000,$01a6,$0000
	dc.w	$01a8,$0000,$01aa,$0000,$01ac,$0000,$01ae,$0000
	dc.w	$01b0,$0000,$01b2,$0000,$01b4,$0000,$01b6,$0000
	dc.w	$01b8,$0000,$01ba,$0000,$01bc,$0000,$01be,$0000

	dc.b	PictureStartLine-1,$e1
	dc.w	$fffe

PicturePointers:
	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000
	dc.w	$00f0,$0000,$00f2,$0000

	dc.b	PictureStartLine,$09
	dc.w	$fffe
	dc.w	$0100,$5200

	dc.w	PictureHeight-($ff-PictureStartLine),$09
	dc.w	$fffe
	dc.w	$0100,$0000

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

Picture:	incbin	TFTDD:Pictures/Robot
