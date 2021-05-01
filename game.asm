
					device 		zxspectrum128
					SLDOPT 		COMMENT WPMEM, LOGPOINT, ASSERTION

					org 		8000h

stack_top:
start:				ld			sp, stack_top
					halt
					jp			start

					savesna 	"game.sna", start
