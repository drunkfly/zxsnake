
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
					ld			a, -1
					ld			(snakeDirY), a
.notQ:

					ld			bc, 0fdfeh
					in			a, (c)
					and			1
					jr			nz, .notA
					ld			a, 1
					ld			(snakeDirY), a
.notA:

					ld			bc, 0dffeh
					in			a, (c)
					bit			1, a
					jr			nz, .notO
					ex			af, af'
					ld			a, -1
					ld			(snakeDirX), a
					ex			af, af'
.notO:

					and			1
					jr			nz, .notP
					ld			a, 1
					ld			(snakeDirX), a
.notP:

					ld			a, (counter)
					inc			a
					ld			(counter), a
					cp			50
					jr			c, .skip
					xor			a
					ld			(counter), a

					ld			a, (snakeTail)
					ld			l, a
					inc			a
					inc			a					; сдвигаем хвост вперед на 1
					ld			(snakeTail), a
					ld			h, snakeParts / 256 ; HL => адрес в snakeParts
					ld			c, (hl)  			; читаем X и Y хвоста
					inc			hl
					ld			b, (hl)
					ld			l, ' '
					ld			a, 0x47
					call		DrawChar			; стираем хвост

					ld			a, (snakeHead)
					ld			l, a
					inc			a					; сдвигаем голову вперед на 1
					inc			a
					ld			(snakeHead), a
					ld			h, snakeParts / 256
					ld			c, (hl)  			; читаем X и Y головы
					inc			hl
					ld			b, (hl)
					inc			hl
					ex			de, hl				; DE <= координаты следующей головы в буфере
					ld			hl, (snakeDirX)
					add			hl, bc				; HL = новые координаты
					ex			de, hl
					ld			(hl), e
					inc			hl
					ld			(hl), d
					ld			l, 'X'				; рисуем голову
					ld			a, 0x47
					ld			c, e
					ld			b, d
					call		DrawChar

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

counter				db			0
