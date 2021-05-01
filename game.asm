
					device 		zxspectrum48

stack_top:

					include		"irq.asm"

start:				di
					ld			sp, stack_top
					ld			a, 80h
					ld			i, a
					im			2
					ei
.loop:				halt


					jp			.loop

snakeDirX			db			0
snakeDirY			db			1

snakeHead			db			2
snakeTail			db			0

MAX_SNAKE_LENGTH = 128

					align		256, 0

snakeParts:			db			4
					db			4
					db			5
					db			4
					db			5
					db			5
					dup			MAX_SNAKE_LENGTH-3
					db			0
					db			0
					edup

					include		"draw.asm"

					savesna 	"game.sna", start
					SLDOPT 		COMMENT WPMEM, LOGPOINT, ASSERTION
