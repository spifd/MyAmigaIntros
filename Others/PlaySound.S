; ******************************
; *                            *
; * Title: Play Sound          *
; *                            *
; * Coder: Spirit              *
; * Date : May 1991            *
; *                            *
; * Infos: Play Digit Sound    *
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

Length		= 30122/2
Period		= 400
Volume		= 64
NbCycles	= 1

;
;; ---- MAIN PROGRAM ----
;

Start:
	movem.l	d0-d7/a0-a6,-(sp)

	lea	$dff000,a5

	move.w	#%0100000000000000,$09a(a5)
	move.l	$70,OldIrq4
	move.l	#Irq4,$70
	move.w	#%1100000010000000,$09a(a5)

	move.l	#Sound,$0a0(a5)
	move.w	#Length,$0a4(a5)
	move.w	#Period,$0a6(a5)
	move.w	#Volume,$0a8(a5)
	move.w	#%1000001000000001,$096(a5)


LeftButtonTest:
	tst.w	Cycle
	bne.s	LeftButtonTest

End:
	move.w	#%0000000000000001,$096(a5)

	move.w	#%0100000010000000,$09a(a5)
	move.l	OldIrq4(pc),$70
	move.w	#%1100000000000000,$09a(a5)

	movem.l	(sp)+,d0-d7/a0-a6
	rts

;
;; ---- INTERRUPT ----
;

Irq4:
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	$01c(a5),d0
	and.w	$01e(a5),d0

Audio0:
	btst	#7,d0
	beq.s	Irq4End

	subq.w	#1,Cycle

	move.w	#%0000000010000000,$09c(a5)

Irq4End:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

OldIrq4:	dc.l	0
Cycle:		dc.w	NbCycles+1

;
;; ---- MEMORY SPACE ----
;

Sound:	incbin	TFTDD:Modules/Sound1
