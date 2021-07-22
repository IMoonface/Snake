randomTest  PROC                ;Zum Testen der Zufallszahlen
            MOV AH, 02h
            MOV BH, 0
            MOV DL, 3
            MOV DH, 23
            INT 10h             

            MOV AH, 09h
            MOV BH, 0
            MOV AL, randomX
            SHR AL, 3
            ADD AL, '0'
            MOV CX, 1
            MOV BL, 00000111b
            INT 10h

            MOV AH, 02h
            MOV BH, 0
            MOV DL, 4
            MOV DH, 23
            INT 10h

            MOV AH, 09h
            MOV BH, 0
            MOV AL, randomY
            SHR AL, 1
            ADD AL, '0'
            MOV CX, 1
            MOV BL, 00000111b
            INT 10h
            RET
randomTest  ENDP
