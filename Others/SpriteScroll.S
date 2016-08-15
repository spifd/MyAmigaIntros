; ******************************
; *                            *
; * Title: Sprite Scrolling    *
; *                            *
; * Coder: Spirit              *
; * Date : October 1991        *
; *                            *
; * Infos:                     *
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

SprScrollStartLine	= $30
SprHeight		= 178

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
	move.w	#%1000001111100000,$096(a5)
	move.w	#$7fff,$09a(a5)
	move.w	#%1100000000100000,$09a(a5)

	ClrMem	BFgrd,20,SprHeight*3
	ClrMem	BFgrd+(320*SprHeight*3/8),20,SprHeight

	bsr	InitScreenPointers
	bsr	InitSpritesPointers

	WaitBlitter

	move.l	#CopperList,$080(a5)
	clr.w	$088(a5)

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

RightButtonTest:
	btst	#10,$016(a5)
	bne.w	GoOnIrq3

	bsr	SpriteScroll

GoOnIrq3:
	move.w	#%0000000000100000,$09c(a5)

Irq3End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;
;; ---- ROUTINES ----
;

;; - Init Screen Pointers -

InitScreenPointers:
	lea	ScreenPointers+4(pc),a0
	move.l	#BFgrd,d0
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
	rts

;; - Init Sprites Pointers -

InitSpritesPointers:
	move.w	#%0000000010000000,Sprite01+(Sprite23-Sprite01)/2+2
	move.w	#%0000000010000000,Sprite23+(Sprite45-Sprite23)/2+2
	move.w	#%0000000010000000,Sprite45+(Sprite67-Sprite45)/2+2
	move.w	#%0000000010000000,Sprite67+(BFgrd-Sprite67)/2+2

	lea	SpritesPointers(pc),a0

	move.l	#Sprite01,d0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)

	move.l	#Sprite01+(Sprite23-Sprite01)/2,d0
	move.w	d0,14(a0)
	swap	d0
	move.w	d0,10(a0)

	move.l	#Sprite23,d0
	move.w	d0,22(a0)
	swap	d0
	move.w	d0,18(a0)

	move.l	#Sprite23+(Sprite45-Sprite23)/2,d0
	move.w	d0,30(a0)
	swap	d0
	move.w	d0,26(a0)

	move.l	#Sprite45,d0
	move.w	d0,38(a0)
	swap	d0
	move.w	d0,34(a0)

	move.l	#Sprite45+(Sprite67-Sprite45)/2,d0
	move.w	d0,46(a0)
	swap	d0
	move.w	d0,42(a0)

	move.l	#Sprite67,d0
	move.w	d0,54(a0)
	swap	d0
	move.w	d0,50(a0)

	move.l	#Sprite67+(BFgrd-Sprite67)/2,d0
	move.w	d0,62(a0)
	swap	d0
	move.w	d0,58(a0)

	rts

;; - Sprite Scroll Routine -

SpriteScroll:
	lea	SpritesPositions+7(pc),a0
	moveq	#0,d3

	cmp.b	#$3f+32,(a0)
	bne.s	ContinueSpriteScroll

	moveq	#1,d3

ContinueSpriteScroll:
	move.w	#SprHeight-1,d2

SpriteScrollLoop1:
	moveq	#5*8-1,d0
	moveq	#0,d1

SpriteScrollLoop2:
	cmp.b	#1,d3
	beq.s	ReStartSprScroll

	addq.b	#1,(a0,d1.w)
	bra.s	ContinueScrollLoop2

ReStartSprScroll:
	sub.b	#32,(a0,d1.w)

ContinueScrollLoop2:
	addq.l	#4,d1
	dbra	d0,SpriteScrollLoop2

	lea	164(a0),a0
	dbra	d2,SpriteScrollLoop1
	rts

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
	dc.w	$0108,40*3,$010a,40*3

BplCon2Value:
	dc.w	$0104
	dc.b	0,%00000000

ColorsMap:
	dc.w	$0180,$0000
	dc.w	$01a0,$0000,$01a2,$0112,$01a4,$0aab,$01a6,$0889
	dc.w	$01a8,$0667,$01aa,$0445,$01ac,$0223,$01ae,$02cd
	dc.w	$01b0,$0000,$01b2,$0003,$01b4,$0004,$01b6,$0005
	dc.w	$01b8,$0007,$01ba,$0009,$01bc,$000b,$01be,$0334

SpritesPointers:
	dc.w	$0120,$0000,$0122,$0000
	dc.w	$0124,$0000,$0126,$0000
	dc.w	$0128,$0000,$012a,$0000
	dc.w	$012c,$0000,$012e,$0000
	dc.w	$0130,$0000,$0132,$0000
	dc.w	$0134,$0000,$0136,$0000
	dc.w	$0138,$0000,$013a,$0000
	dc.w	$013c,$0000,$013e,$0000

ScreenPointers:
	dc.b	SprScrollStartLine,$09
	dc.w	$fffe

	dc.w	$00e0,$0000,$00e2,$0000
	dc.w	$00e4,$0000,$00e6,$0000
	dc.w	$00e8,$0000,$00ea,$0000
	dc.w	$00ec,$0000,$00ee,$0000

	dc.b	SprScrollStartLine,$09
	dc.w	$fffe
	dc.w	$0100,$4200

SpritesPositions:

CurrentLine:	set	SprScrollStartLine

	REPT	SprHeight

	dc.b	CurrentLine,$31
	dc.w	$fffe

	dc.w	$0140,$3000+$3f+(32*0)+(8*0),$0148,$3000+$3f+(32*0)+(8*0)
	dc.w	$0150,$3000+$3f+(32*0)+(8*1),$0158,$3000+$3f+(32*0)+(8*1)
	dc.w	$0160,$3000+$3f+(32*0)+(8*2),$0168,$3000+$3f+(32*0)+(8*2)
	dc.w	$0170,$3000+$3f+(32*0)+(8*3),$0178,$3000+$3f+(32*0)+(8*3)

	dc.w	$0140,$3000+$3f+(32*1)+(8*0),$0148,$3000+$3f+(32*1)+(8*0)
	dc.w	$0150,$3000+$3f+(32*1)+(8*1),$0158,$3000+$3f+(32*1)+(8*1)
	dc.w	$0160,$3000+$3f+(32*1)+(8*2),$0168,$3000+$3f+(32*1)+(8*2)
	dc.w	$0170,$3000+$3f+(32*1)+(8*3),$0178,$3000+$3f+(32*1)+(8*3)

	dc.w	$0140,$3000+$3f+(32*2)+(8*0),$0148,$3000+$3f+(32*2)+(8*0)
	dc.w	$0150,$3000+$3f+(32*2)+(8*1),$0158,$3000+$3f+(32*2)+(8*1)
	dc.w	$0160,$3000+$3f+(32*2)+(8*2),$0168,$3000+$3f+(32*2)+(8*2)
	dc.w	$0170,$3000+$3f+(32*2)+(8*3),$0178,$3000+$3f+(32*2)+(8*3)

	dc.w	$0140,$3000+$3f+(32*3)+(8*0),$0148,$3000+$3f+(32*3)+(8*0)
	dc.w	$0150,$3000+$3f+(32*3)+(8*1),$0158,$3000+$3f+(32*3)+(8*1)
	dc.w	$0160,$3000+$3f+(32*3)+(8*2),$0168,$3000+$3f+(32*3)+(8*2)
	dc.w	$0170,$3000+$3f+(32*3)+(8*3),$0178,$3000+$3f+(32*3)+(8*3)

	dc.w	$0140,$3000+$3f+(32*4)+(8*0),$0148,$3000+$3f+(32*4)+(8*0)
	dc.w	$0150,$3000+$3f+(32*4)+(8*1),$0158,$3000+$3f+(32*4)+(8*1)
	dc.w	$0160,$3000+$3f+(32*4)+(8*2),$0168,$3000+$3f+(32*4)+(8*2)
	dc.w	$0170,$3000+$3f+(32*4)+(8*3),$0178,$3000+$3f+(32*4)+(8*3)

CurrentLine:	set	CurrentLine+1

	ENDR

	dc.b	SprScrollStartLine+SprHeight,$09
	dc.w	$fffe
	dc.w	$0100,$0000

	dc.w	$ffff,$fffe

;
;; ---- MEMORY SPACE ----
;

Sprite01:	incbin	GDD:Pictures/RWSprite01
Sprite23:	incbin	GDD:Pictures/RWSprite23
Sprite45:	incbin	GDD:Pictures/RWSprite45
Sprite67:	incbin	GDD:Pictures/RWSprite67

BFgrd:		ds.b	(320*SprHeight*4/8)
