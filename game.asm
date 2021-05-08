
					device 		zxspectrum48

					define 		GRAPHIC_SNAKE

SCREEN_ATTR = 0
SNAKE_ATTR = 0x44
APPLE_ATTR = 0x46

ROM_BEEP = 949

stack_top:

					include		"irq.asm"

start:				di
					ld			sp, stack_top
					ld			a, 80h
					ld			i, a
					im			2
					ei

					ld			a, SCREEN_ATTR
					call		ClearScreenAttr

					call		Intro

.mainLoop:			call		RunGame
					call		GameOver
					jr			.mainLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitNoKey:			call		DoReadKeys
					jr			nz, WaitNoKey
					ret

WaitAnyKey:			call		DoReadKeys
					jr			z, WaitAnyKey
					ret

DoReadKeys:			ld			c, 0xfe
					ld			hl, .ports
					ld			d, 8
.innerLoop:			ld			b, (hl)
					inc			hl
					in			a, (c)
					and			0x1f
					cp			0x1f
					ret			nz
					dec			d
					jr			nz, .innerLoop
					ret

.ports:				db			0xfe
					db			0xfd
					db			0xfb
					db			0xf7
					db			0xef
					db			0xdf
					db			0xbf
					db			0x7f

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Intro:				ld			a, SCREEN_ATTR
					call		ClearScreenAttr

					ld			ix, .message
					ld			bc, 0x0B0A			; Y = 11, X = 10
					ld			iyl, 0x44			; Яркий зеленый на черном
					call		DrawString
					
					ld			ix, .message2
					ld			bc, 0x0D09			; Y = 13, X = 9
					ld			iyl, 0xC4			; Яркий зеленый на черном, мигающий
					call		DrawString
					
					call		WaitNoKey
					jr			WaitAnyKey

.message:			db			' THE PYTHON ',0
.message2:			db			' PRESS ANY KEY ',0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameOver:			ld			a, SCREEN_ATTR
					call		ClearScreenAttr

					ld			ix, .message
					ld			bc, 0x0C0B			; Y = 12, X = 11
					ld			iyl, 0xC2			; Красный на черном, яркий, мигающий
					call		DrawString

					ld			hl, 497
					ld			de, 208
					call		ROM_BEEP
					ld			hl, 397
					ld			de, 208
					call		ROM_BEEP
					ld			hl, 297
					ld			de, 208
					call		ROM_BEEP
					ld			hl, 197
					ld			de, 208
					call		ROM_BEEP
					
					call		WaitNoKey
					jp			WaitAnyKey

.message:			db			' YOU LOST ',0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunGame:			ld			a, SCREEN_ATTR
					call		ClearScreenAttr
					ld			hl, 0x0100
					ld			(snakeDirX), hl
					ld			hl, 0x000c
					ld			(snakeHead), hl
					ld			hl, 0x0201
					ld			(snakeParts), hl
					ld			hl, 0x0101
					ld			(snakeParts+2), hl
					ld			hl, 0x0102
					ld			(snakeParts+4), hl
					ld			hl, 0x0103
					ld			(snakeParts+6), hl
					ld			hl, 0x0203
					ld			(snakeParts+8), hl
					ld			hl, 0x0303
					ld			(snakeParts+10), hl
					ld			hl, 0x0302
					ld			(snakeParts+12), hl
					xor			a
					ld			(counter), a
					call		SpawnApple
.loop:				halt

					; рисуем яблоко
					ld			bc, (appleCoordX)
					ld			l, 'o'
					ld			a, APPLE_ATTR
					call		DrawChar

					ld			a, (counter)
					inc			a
					ld			(counter), a
					cp			15
					jr			c, .loop
					xor			a
					ld			(counter), a

					; читаем координаты головы
					ld			a, (snakeHead)
					ld			l, a
					inc			a					; сдвигаем голову вперед на 1
					inc			a
					ld			(snakeHead), a
					ld			h, snakeParts / 256
					ld			c, (hl)  			; читаем X и Y головы
					inc			l					; INC L вместо INC HL, т.к. буфер выравнен на 256 байт
					ld			b, (hl)
					inc			l					; INC L вместо INC HL, т.к. буфер выравнен на 256 байт

					; двигаем голову вперед
					ex			de, hl				; DE <= координаты следующей головы в буфере
					ld			hl, (snakeDirX)

					ld			a, l
					add			a, c				; X += DirX
					ld			c, a

					cp			32					; если X>=32, то вышли за правый край
					ret			nc
					;inc			a					; если X был равен -1, то вышли за левый край
					;ret			z

					ld			a, h
					add			a, b				; Y += DirY
					ld			b, a

					cp			24					; если Y>=24, то вышли за нижний край
					ret			nc
					;inc			a					; если Y был равен -1, то вышли за верхний край
					;ret			z

					ex			de, hl
					ld			(hl), c
					inc			l					; INC L вместо INC HL, т.к. буфер выравнен на 256 байт
					ld			(hl), b

					; проверяем, есть ли яблоко на экране
					ld			e, c				; E = X
					ld			l, b				; L = Y
					call		GetScreenAttr

					cp			SNAKE_ATTR
					ret			z					; game over

					ld			(.screenAttr+1), a

					; рисуем голову по новым координатам
	ifndef GRAPHIC_SNAKE
					ld			l, 'X'
					ld			a, SNAKE_ATTR
					call		DrawChar
	endif

					; проверяем, нужно ли двигать хвост и двигаем, если не съели яблоко

					ld			a, APPLE_ATTR
.screenAttr:		cp			0
					jr			z, .isApple

.notApple:			ld			a, (snakeTail)
					ld			l, a
					inc			a
					inc			a					; сдвигаем хвост вперед на 1
					ld			(snakeTail), a		; читаем из snakeTail
					ld			h, snakeParts / 256 ; HL => адрес в snakeParts
					ld			c, (hl)  			; читаем X и Y хвоста
					inc			l					; INC L вместо INC HL, т.к. буфер выравнен на 256 байт
					ld			b, (hl)
					ld			l, ' '
					ld			a, SCREEN_ATTR
					call		DrawChar			; стираем хвост
					jr			.doneApple

.isApple:			ld			hl, 497
					ld			de, 208
					call		ROM_BEEP

					call		SpawnApple

.doneApple:

	ifdef GRAPHIC_SNAKE	

					ld			a, (snakeTail)
					ld			l, a
					ld			h, snakeParts / 256

					; рисуем хвост

					ld			c, (hl)  			; BC - координаты хвоста
					inc			l
					ld			b, (hl)
					inc			l

					ld			e, (hl)				; DE - координаты следующей части
					inc			l
					ld			d, (hl)
					dec			l

					call		GetNeighbors

					push		hl
					ld			l, d
					ld			a, SNAKE_ATTR
					call		DrawUDG
					pop			hl

.drawLoop:			dec			l
					ld			d, (hl)				; DE - координаты предыдущей части
					dec			l
					ld			e, (hl)
					inc			l
					inc			l

					ld			c, (hl)  			; BC - координаты текущей части
					inc			l
					ld			b, (hl)
					dec			l

					call		GetNeighbors

					ld			c, (hl)  			; BC - координаты текущей части
					inc			l
					ld			b, (hl)
					inc			l

					ld			a, (snakeHead)
					inc			a
					inc			a
					cp			l
					jr			z, .drawHead

					ld			ixl, d

					ld			e, (hl)				; DE - координаты следующей части
					inc			l
					ld			d, (hl)
					dec			l

					call		GetNeighbors

					ld			a, d
					or			ixl

					push		hl
					ld			l, a
					ld			a, SNAKE_ATTR
					call		DrawUDG
					pop			hl

					jr			.drawLoop

.drawHead:			
					ld			l, d
					ld			a, SNAKE_ATTR
					call		DrawUDG

	endif

					jp			.loop

	ifdef GRAPHIC_SNAKE

					; Output:
					;   D = neighbor bit mask

GetNeighbors:		ld			a, d
					cp 			b

					ld			d, 0

					jr			z, .skip1
					jr			c, .skip1_1
					set			3, d
					jr			.skip1
.skip1_1:			set			2, d
.skip1:

					ld			a, e
					cp 			c
					jr			z, .skip2
					jr			c, .skip2_1
					set			1, d
					jr			.skip2
.skip2_1:			set			0, d

.skip2:				ret

UDG:				db			0b00000000
					db			0b00000000
					db			0b00000000
					db			0b00011000
					db			0b00011000
					db			0b00000000
					db			0b00000000
					db			0b00000000

					db			0b00000000
					db			0b00000000
					db			0b00000000
					db			0b11111000
					db			0b11111000
					db			0b00000000
					db			0b00000000
					db			0b00000000

					db			0b00000000
					db			0b00000000
					db			0b00000000
					db			0b00011111
					db			0b00011111
					db			0b00000000
					db			0b00000000
					db			0b00000000

					db			0b00000000
					db			0b00000000
					db			0b00000000
					db			0b11111111
					db			0b11111111
					db			0b00000000
					db			0b00000000
					db			0b00000000

					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00000000
					db			0b00000000
					db			0b00000000

					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b11111000
					db			0b11111000
					db			0b00000000
					db			0b00000000
					db			0b00000000

					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011111
					db			0b00011111
					db			0b00000000
					db			0b00000000
					db			0b00000000

					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b11111111
					db			0b11111111 
					db			0b00000000
					db			0b00000000
					db			0b00000000

					db			0b00000000
					db			0b00000000
					db			0b00000000
					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011000

					db			0b00000000
					db			0b00000000
					db			0b00000000
					db			0b11111000
					db			0b11111000
					db			0b00011000
					db			0b00011000
					db			0b00011000

					db			0b00000000
					db			0b00000000
					db			0b00000000
					db			0b00011111
					db			0b00011111
					db			0b00011000
					db			0b00011000
					db			0b00011000

					db			0b00000000
					db			0b00000000
					db			0b00000000
					db			0b11111111
					db			0b11111111
					db			0b00011000
					db			0b00011000
					db			0b00011000

					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011000

					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b11111000
					db			0b11111000
					db			0b00011000
					db			0b00011000
					db			0b00011000

					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b00011111
					db			0b00011111
					db			0b00011000
					db			0b00011000
					db			0b00011000

					db			0b00011000
					db			0b00011000
					db			0b00011000
					db			0b11111111 
					db			0b11111111
					db			0b00011000
					db			0b00011000
					db			0b00011000

	endif

; 111 1111
;     ++++ -- X*2   0..16 => 0,2,4,8,..,30
; +++      -- Y*3   0..7  => 0,3,6,9,..,21

SpawnApple:			ld			a, r	; Берем "случайное" число из R
					and			15		; младшие 4 бита - X
					rlca				; X = X*2
					ld			e, a	; E = X координата яблока
					ld			c, a	; C = X координата яблока
					ld			a, r
					rrca				; старшие 3 бита - Y, сдвигаем их вправо
					rrca
					rrca
					rrca
					and			7		; маскируем 3 бита
					ld			h, a
					rlca				; Y' = Y*2
					add			a, h	; Y' = Y*2 + Y = Y*3
					ld			l, a	; L = Y координата яблока
					ld			b, a	; B = Y координата яблока

					call		GetScreenAttr
					cp			SCREEN_ATTR
					jr			nz, SpawnApple

					ld			(appleCoordX), bc
					ret

snakeDirX			db			0
snakeDirY			db			0

snakeHead			db			0
snakeTail			db			0

appleCoordX			db			0
appleCoordY			db			0

counter				db			0

MAX_SNAKE_LENGTH = 128

					align		256, 0

snakeParts:			dup			MAX_SNAKE_LENGTH
					db			0
					db			0
					edup

					include		"draw.asm"

					savesna 	"game.sna", start
					SLDOPT 		COMMENT WPMEM, LOGPOINT, ASSERTION
