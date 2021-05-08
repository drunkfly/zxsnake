
					org			8000h
						
INTERRUPT = 81h

irq_vectors:		dup			257
					db			INTERRUPT
					edup

					ds			(INTERRUPT*256+INTERRUPT)-$

					org			(INTERRUPT*256+INTERRUPT)

interrupt:			push		af
					push		bc
					push		de
					push		hl
					ex			af, af'
					exx
					push		af
					push		bc
					push		de
					push		hl
					push		ix
					push		iy

					ld			bc, 0fbfeh
					in			a, (c)
					and			1
					jr			nz, .notQ
					ld			hl, 0xff00				; DirX = 0, DirY = -1
					ld			(snakeDirX), hl
.notQ:

					ld			bc, 0fdfeh
					in			a, (c)
					and			1
					jr			nz, .notA
					ld			hl, 0x0100				; DirX = 0, DirY = 1
					ld			(snakeDirX), hl
.notA:

					ld			bc, 0dffeh
					in			a, (c)
					bit			1, a
					jr			nz, .notO
					ex			af, af'
					ld			hl, 0x00ff				; DirX = -1, DirY = 0
					ld			(snakeDirX), hl
					ex			af, af'
.notO:

					and			1
					jr			nz, .notP
					ld			a, 1
					ld			hl, 0x0001				; DirX = 1, DirY = 0
					ld			(snakeDirX), hl
.notP:

.skip:				pop			iy
					pop			ix
					pop			hl
					pop			de
					pop			bc
					pop			af
					ex			af, af'
					exx
					pop			hl
					pop			de
					pop			bc
					pop			af
					ei
					ret
