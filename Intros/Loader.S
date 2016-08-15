; ******************************
; *                            *
; * Title: Loader              *
; *                            *
; * Coder: Spirit              *
; * Date : May 1991            *
; *                            *
; * Infos: CLI Intro Loader    *
; *        for AgilePackLoader *
; *                            *
; ******************************

;
;; ---- REGISTERS & VALUES ----
;

; - Exec.library -

ExecBase	= 4
OpenLibrary	= -552
CloseLibrary	= -414

; - Dos.library -

Execute		= -222

; - Others -

HighAddress	= $70000

;
;; ---- MAIN PROGRAM ----
;

Start:
	move.l	ExecBase,a6
	lea	DosName(pc),a1
	moveq	#0,d0
	jsr	OpenLibrary(a6)
	move.l	d0,a6

	move.l	#HighAddress,d1
	moveq	#0,d2
	moveq	#0,d3
	jsr	Execute(a6)

	move.l	a6,a1
	move.l	ExecBase,a6
	jsr	CloseLibrary(a6)
	rts

DosName:	dc.b	"dos.library",0
		even
