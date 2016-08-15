----------------------------------------------------------------
  MC 68000		       Clock Cycles		 Number
Instructions		(Number Read/Write Cycles)	Of Bytes
----------------------------------------------------------------

abcd	-(a0),-(a1)		20	(4/1)		    2
abcd	d0,d1			10	(2/0)		    2

add.b	Addr16,d0		12	(3/0)		    4
add.b	(a0),d0			8	(2/0)		    2
add.b	(a0,d1.w),d0		14	(3/0)		    4
add.b	#Data8,d0		8	(2/0)		    4
add.b	d1,d0			4	(1/0)		    2
add.w	#Data16,d0		8	(2/0)		    4
add.w	#Data16,a0		12
add.w	d1,a0			8	(1/0)		    2
add.w	d1,d0			4	(1/0)		    2
add.l	d0,d1			8
add.l	#Data32,d0		16
add.l	#Data32,a0		16

addq.b	#1,(a0,d1.w)		19	(3/1)		    4
addq.b	#1,Addr16		16	(3/1)		    4
addq.b	#1,d0			4	(1/0)		    2
addq.w	#1,d0			4	(1/0)		    2
addq.w	#1,a0			8			    2
addq.l	#1,a0			8	(1/0)		    2
addq.l	#1,d0			8

addx.b	-(a0),-(a1)		18	(3/1)		    2

and.b	Addr16,d0		12	(3/0)		    4
and.b	#Data8,Addr16		20	(4/1)		    6
and.b	#Data8,Addr32		25	(5/1)		    8
and.b	#Data8,d0		8	(2/1)		    4
and.b	#Data8,sr		20	(3/0)		    4
and.b	Disp16(a0),d0		12	(3/0)		    4
and.b	d0,Addr32		20	(4/1)		    6
and.w	#Data16,sr		20	(3/0)		    4
and.l	#Data32,d0		16
and.l	d1,d0			8

asl.w	#1,d0			8
asl.l	#1,d0			10

asr.b	#1,d0			8	(1/0)		    2
asr.w	#1,d0			8
asr.w	#2,d0			10
asr.w	#3,d0			12
asr.l	#1,d0			10
asr.l	#2,d0			12
asr.l	#3,d0			14

bclr	#no.,Addr32		25	(5/1)		    8

bcc.s				10	(2/0)		    2
				8	(1/0)		    2*
bcs.s				10	(2/0)		    2
				8	(1/0)		    2*
beq.s				10	(2/0)		    2
				8	(1/0)		    2*
bhi.s				10	(2/0)		    2
				8	(1/0)		    2*
bls.s				10	(2/0)		    2
				8	(1/0)		    2*
bmi.s				10	(2/0)		    2
				8	(1/0)		    2*
bne.s				10	(2/0)		    2
				8	(1/0)		    2*
bpl.s				10	(2/0)		    2
				8	(1/0)		    2*
bra.s				10	(2/0)		    2

bset	#no.,Addr32		25	(5/1)		    8

bsr.s				18	(2/2)		    2

btst	#no.,Addr32		20	(7/0)		    8

clr.b	Addr16			17	(3/1)		    4
clr.b	Addr32			21	(4/1)		    6
clr.b	(a0,d1.w)		19	(3/1)		    4
clr.b	d0			4	(1/0)		    2
clr.w	Addr16			17	(3/1)		    4
clr.w	d0			4	(1/0)		    2
clr.l	Addr16			17	(3/1)		    4
clr.l	d0			6
clr.l	a0			6

cmp.b	Addr16			12	(3/0)		    4
cmp.b	(a0,d1.w),d0		14	(3/0)		    4
cmp.b	#Data8,Addr16		16	(4/0)		    6
cmp.b	#Data8,Addr32		20	(5/0)		    8
cmp.b	#Data8,d0		8	(2/0)		    4
cmp.w	#Data16,d0		8	(2/0)		    4
cmp.l	#Data32,d0		14
cmp.l	d0,d1			8

dbra	d1,Disp16		10	(2/0)		    4
				14	(3/0)		    4*

divu	#2,d0			144

eor.b	#Data8,Addr16		21	(4/1)		    6
eor.b	#Data8,Addr32		25	(5/1)		    8
eor.b	d0,d3			4	(1/0)		    2

jmp	(a0)			8	(2/0)		    2
jsr	Addr16			18	(2/2)		    4

lea	Addr16,a0		8	(2/0)		    4
lea	Addr32,a0		12	(3/0)		    6
lea	Disp16(a0),a0		8

lsl.b	#1,d0			8	(1/0)		    2
lsl.b	#2,d0			10	(1/0)		    2
lsl.b	#4,d0			14	(1/0)		    2
lsl.w	#1,d0			8	(1/0)		    2
lsl.w	#2,d0			10	(1/0)		    2
lsl.w	#3,d0			12
lsl.l	#1,d0			10
lsl.l	#2,d0			12

lsr.b	#1,d0			8	(1/0)		    2
lsr.b	#2,d0			10	(1/0)		    2
lsr.b	#4,d0			14	(1/0)		    2
lsr.l	#7,d0			22
lsr.l	#8,d0			24
lsr.l	d3,d4			38

move.b	(a0)+,Addr32		20	(4/1)		    6
move.b	(a0),d0			8	(2/0)		    2
move.b	(a0,d1.w),d0		14	(3/0)		    4
move.b	(a0)+,(a1)+		12	(2/1)		    2
move.b	(a0)+,d1		8	(2/0)		    2
move.b	(a0),d1			8	(2/0)		    2
move.b	Addr16,d0		12	(3/0)		    4
move.b	Addr32,(a0)+		20	(4/1)		    6
move.b	Addr32,Addr16		24	(5/1)		    8
move.b	Addr32,Addr32		28	(6/1)		    10
move.b	Addr32,d0		16	(4/0)		    6
move.b	#Data8,Addr32		20	(4/1)		    8
move.b	#Data8,d0		8	(2/0)		    4
move.b	d0,Addr16		12	(2/1)		    4
move.b	d0,Addr32		16	(3/1)		    6
move.b	d0,(a0)			8	(1/1)		    2
move.b	d0,(a0,d1.w)		15	(2/1)		    4
move.b	d0,Disp16(a0)		12	(2/1)		    4
move.b	d0,d2			4	(1/0)		    2
move.b	d0,Addr16		12	(2/1)		    4
move.b	d0,Addr32		16	(3/1)		    6
move.w	(a0),d0			8	(2/0)		    2
move.w	Addr16,d0		12	(3/0)		    4
move.w	#Data16,(a0)+		12	(2/1)		    4
move.w	#Data16,d1		8	(2/0)		    4
move.w	d0,(a0)			8	(1/1)		    2
move.w	d0,-(a7)		8	(1/1)		    2
move.w	d0,Addr16		12	(2/1)		    4
move.w	sr,-(a7)		15	(2/1)		    2
move.l	Addr16,a0		16	(4/0)		    4
move.l	a0,-(a7)		12	(1/2)		    2
move.l	a0,Addr16		16	(4/0)		    4
move.l	(a0,d0.w),a0		18	(4/0)		    4
move.l	(a0),d0			12	(3/0)		    2
move.l	a1,a2			4	(1/0)		    2
move.l	a6,d0			4	(1/0)		    2
move.l	d0,d1			4
move.l	(a7)+,a0		12	(3/0)		    2
move.l	d0,Addr16		12
move.l	a7,Addr16		12	(2/1)		    4
move.l	(a7)+,d6		12	(3/0)		    2
move.l	#Data32,Addr16		28	(5/2)		    8
move.l	#Data32,d6		12	(3/0)		    6
move.l	d6,-(a7)		13	(1/2)		    2
move.l	#Data32,-(sp)		20
move.l	d0,-(sp)		12

movem.l	(a7)+,d0/a0		28	(7/0)		    4
movem.l	(a7)+,d0-d1		28	(7/0)		    4
movem.l	(a7)+,d0/d6		28	(7/0)		    4
movem.l	(a7)+,d5-d6		28	(7/0)		    4
movem.l	d0/a0,-(a7)		24	(2/4)		    4
movem.l	d0-d1,-(a7)		24	(2/4)		    4
movem.l	d0/d6,-(a7)		24	(2/4)		    4
movem.l	d5-d6,-(a7)		24	(2/4)		    4

moveq	#Data8,d0		4	(1/0)		    2

mulu	#2,d0			74

muls	#10,d0			70

nop				4	(1/0)		    2

not.b	Addr16			16	(3/1)		    4
not.b	Addr32			20	(4/1)		    4
not.b	d0			4	(1/0)		    2

or.b	Addr16,d0		12	(3/0)		    4
or.b	#Data8,Addr16		21	(4/1)		    6
or.b	#Data8,Addr32		25	(5/1)		    8
or.b	#Data8,sr		20	(3/0)		    4
or.w	#Data16,sr		20	(3/0)		    4

pea	Data16			16

roxl.b	#1,d0			8	(1/0)		    2

rte				20	(5/0)		    2
rtr				20	(5/0)		    2
rts				16	(4/0)		    2

sbcd	-(a0),-(a1)		18	(3/1)		    2
sbcd	d0,d1			6	(1/0)		    2

sub.b	Addr16,d0		12	(3/0)		    4
sub.b	#Data8,d0		8	(2/0)		    4
sub.w	d0,d1			4
sub.l	#Data32,d0		16
sub.l	d0,d1			6
sub.l	a5,a6			8	(1/0)		    2

subq.b	#1,Addr16		16	(3/1)		    4
subq.b	#1,d2			4	(1/0)		    2
subq.w	#1,d2			4	(1/0)		    2
subq.l	#1,d5			8	(1/0)		    2

swap	d0			4

trap	#14			62	(8/6)		    2

tst.b	Addr16			12	(3/0)		    4
tst.b	Addr32			16	(4/0)		    6
tst.b	d1			4	(1/0)		    2
tst.w	d0			4
tst.l	d0			4
