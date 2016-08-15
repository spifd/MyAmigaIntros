	lea	MotionTable,a0
	lea	MotionTableEnd,a1
	bsr	TransformMotionTable

;; - Transform Vertical Motion Table in Address Offset -

; a0 = Motion Table Start
; a1 = Motion Table End

TransformMotionTable:
	move.w	(a0),d0
	mulu	#44,d0
	move.w	d0,(a0)+
	cmp.l	a0,a1
	bne.s	TransformMotionTable
	rts
