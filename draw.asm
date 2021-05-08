
CHARS = 23606

				; Input:
				;   A = attribute

ClearScreenAttr:ld		hl, 0x5800		; область атрибутов
				ld      e, l
				ld		d, h
				ld		(hl), a
				inc		de
				ld		bc, 0x2ff		; размер области атрибутов минус 1
				ldir
				ret

                ; Input:
                ;   IX = сообщение
                ;   IYL = атрибут
                ;   BC = координаты

DrawString:		ld		a, (ix)
				or		a
				ret		z
				inc		ix
				ld		l, a
				ld		a, iyl
				push	bc
				call	DrawChar
				pop		bc
				inc		c
				jr		DrawString

                ; Input:
                ;   L = symbol
                ;   A = attribute
                ;   C = X (знакоместо)
                ;   B = Y (знакоместо)

DrawChar:       ; Сохраняем А
                ex      af, af'
                ; Преобразуем координату Y в пикселях в значение в знакоместах
                ld		a, b
                rla
                rla
                rla
                and		0xf8
                ld		b, a
                ; Расчитываем адрес назначения
                call    CalcScreenAddr
                ; Расчитываем адрес символа
                ld      h, 0
                add     hl, hl          ; HL+HL = HL*2
                add     hl, hl          ; (HL*2)+(HL*2) = HL*4
                add     hl, hl          ; HL*8
                ld      bc, (CHARS)
                add     hl, bc          ; HL => адрес пикселей символа
                ; Рисуем
                ld      b, 8
.loop:          ld      a, (hl)
                ld      (de), a
                inc     d
                inc     hl
                djnz    .loop
                ; Расчитываем адрес в области атрибутов
                dec     d
                ld      a, d
                rra
                rra
                rra
                and     0x03
                or      0x58
                ld      d, a
                ; Восстанавливаем A
                ex      af, af'
                ; Записываем атрибут
                ld      (de), a
                ret

                ; Input:
                ;   C = X
                ;   B = Y (пиксели)
                ; Output:
                ;   DE => screen addr

CalcScreenAddr: ld      a, b
                rla                                 ; A = ? |Y5|Y4|Y3| ?| ?| ?| ?
                rla                                 ; A = Y5|Y4|Y3| ?| ?| ?| ?| ?
                and     0xe0            ; 1110 0000 ; A = Y5|Y4|Y3| 0| 0| 0| 0| 0
                or      c               ;             A = Y5|Y4|Y3|X4|X3|X2|X1|X0
                ld      e, a
                ld      a, b
                rra                           
                rra
                rra                                 ; A =  ?| ?| ?|Y7|Y6| ?| ?| ?
                and     0x18                        ; A =  0| 0| 0|Y7|Y6| 0| 0| 0
                ld      d, a
                ld      a, b
                and     0x07                        ; A =  0| 0| 0| 0| 0|Y2|Y1|Y0
                or      d                           ; A =  0| 0| 0|Y7|Y6|Y2|Y1|Y0
                or      0x40                        ; A =  0| 1| 0|Y7|Y6|Y2|Y1|Y0
                ld      d, a
                ret

				; Input:
				;    L = Y
				;    E = X
				; Output:
				;    A = attribute

GetScreenAttr:	ld		h, 0						; HL = Y координата
				ld		d, h						; DE = X координата
				add		hl, hl						; *2
				add		hl, hl						; *2
				add		hl, hl						; *2
				add		hl, hl						; *2
				add		hl, hl						; *2 = Y*32
				add		hl, de						; +X
				ld		de, 0x5800
				add		hl, de
				ld		a, (hl)
				ret
