SaveAll:
	move.b	#%10000111,$bfd100
	move.l	ExecBase,a6
	jsr	Forbid(a6)
	move.l	$6c,SaveVecteurIrq
	move.w	$01c(a5),SaveIntena
	or.w	#%1100000000000000,SaveIntena
	move.w	$002(a5),SaveDmacon
	or.w	#%1000001000000000,SaveDmacon
	rts

RestoreAll:
	move.l	SaveVecteurIrq(pc),$6c
	move.w	#$7fff,$09a(a5)
	move.w	SaveIntena(pc),$09a(a5)
	move.w	#$7fff,$096(a5)
	move.w	SaveDmacon(pc),$096(a5)
	move.l	ExecBase,a6
	lea	GfxName(pc),a1
	moveq	#0,d0
	jsr	OpenLibrary(a6)
	move.l	d0,a0
	move.l	38(a0),$080(a5)
	clr.w	$088(a5)
	move.l	d0,a1	
	jsr	CloseLibrary(a6)
	jsr	Permit(a6)
	rts

SaveIntena:		dc.w	0
SaveDmacon:		dc.w	0
SaveVecteurIrq:		dc.l	0
GfxName:		dc.b	"graphics.library",0
			even
