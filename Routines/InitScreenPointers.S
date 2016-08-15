	bsr	InitScreenPointers

;; - Init Screen Pointers -

InitScreenPointers:
	lea	ScreenPointers(pc),a0
	move.l	#Picture,d0
	moveq	#44,d1
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
	swap	d0
	add.l	d1,d0
	move.w	d0,46(a0)
	swap	d0
	move.w	d0,42(a0)
	rts
