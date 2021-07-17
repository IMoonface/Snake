randomTest  PROC                ;ZUM TESTEN DER ZUFALLSZAHLEN
            MOV AH, 02h
            MOV BH, 0
            MOV DL, 3
            MOV DH, 23
            INT 10h             ;Cursor setzen (Futterposition)

            MOV AH, 09h
            MOV BH, 0
            MOV AL, randomX
            SHR AL, 3
            ADD AL, '0'
            MOV CX, 1
            MOV BL, 00000111b   ;Farbe Rosa (Fleischfarbe)
            INT 10h             ;Zeichen schreiben

            MOV AH, 02h
            MOV BH, 0
            MOV DL, 4
            MOV DH, 23
            INT 10h             ;Cursor setzen (Futterposition)

            MOV AH, 09h
            MOV BH, 0
            MOV AL, randomY
            SHR AL, 1
            ADD AL, '0'
            MOV CX, 1
            MOV BL, 00000111b   ;Farbe Rosa (Fleischfarbe)
            INT 10h             ;Zeichen schreiben
            RET
randomTest  ENDP
