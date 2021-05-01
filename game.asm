
					device 		zxspectrum48

					org 		8000h

stack_top:
start:				ld			sp, stack_top
					ld			l, 'X'
					ld			a, 0x47
					ld			c, 4
					ld			b, 4
					call		DrawChar
@halt:				halt
					jp			@halt

					include		"draw.asm"

					savesna 	"game.sna", start
					SLDOPT 		COMMENT WPMEM, LOGPOINT, ASSERTION
