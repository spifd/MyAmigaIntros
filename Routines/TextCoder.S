	move.l	#Message,CharPointer
	move.l	#MessageEnd,CharPointer+4
	bsr	TextCoder

;; - Text Coder Routine -

; CharPointer   = Message Address 
; CharPointer+4 = Message End Address

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
