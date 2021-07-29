randomTest  PROC                ;Prozedur zum Testen der Zufallszahlen
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

collision   PROC                ;Prozedur um zu testen, ob sich die Schlange selber frisst oder der Rand getroffen wurde
            XOR DI, DI
            XOR DX, DX
            MOV DI, snakeSize

            MOV AH, 02h
            MOV BH, 0
            MOV DL, snakeX[DI]
            MOV DH, snakeY[DI]
            INT 10h             ;Cursor setzen

            MOV AH, 08h
            MOV BH, 0
            INT 10h             ;Lese Zeichen und Attribut an der Cursorposition.

            CMP AL, '+'         ;Ueberpruefen ob das Zeichen an der Cursor Position ein Teil der Schlange ist
            JE ende
            CMP AL, 0DBh        ;Ueberpruefen ob das Zeichen an der Cursor Position ein Teil der Rahmens ist
            JE ende
            RET
collision   ENDP

checkScore  PROC                ;Prozedur um zu testen, ob der Punktestand zum Gewinnen erreicht wurde
            CMP mode, 1         ;Easy
            JE easyMode
            CMP mode, 2         ;Normal
            JE normalMode
            JMP hardMode        ;Hard

easyMode:   CMP score, 15       ;Ab 15 Punkten erhoeht sich die Geschwindigkeit
            JE easyDEC
            CMP score, 30       ;Falls man die Punktezahl 30 erreicht hat gewinnt man
            JNE endScore
            MOV DX, OFFSET win
            JMP ende

easyDEC:    DEC speed
            JMP endScore

normalMode: CMP score, 20       ;Ab 20 Punkten erhoeht sich die Geschwindigkeit
            JE normalDEC
            CMP score, 40       ;Falls man die Punktezahl 40 erreicht hat gewinnt man
            JNE endScore
            MOV DX, OFFSET win
            JMP ende

normalDEC:  DEC speed
            JMP endScore

hardMode:   CMP score, 35       ;Ab 35 Punkten erhoeht sich die Geschwindigkeit
            JE hardDEC
            CMP score, 50       ;Falls man die Punktezahl 50 erreicht hat gewinnt man
            JNE endScore
            MOV DX, OFFSET win
            JMP ende

hardDEC:    DEC speed
endScore:   RET
checkScore  ENDP

checkPosi   PROC                ;Prozedur um zu testen, ob Easy, Normal oder Hard angeklickt wurde
            ;Gucken, ob auf einen Buchstaben in "Hard" geklickt wurde (56-52 checken)
            MOV DL, 56
hardCheck:  MOV AH, 02h
            MOV BH, 0
            MOV DH, 16
            INT 10h             ;Cursor setzen

            MOV AH, 08h         ;-> AH = 08h, BH = Seitennummer
            MOV BH, 0
            INT 10h             ;Lese Zeichen und Attribut an der Cursorposition.
                                ;In AH = Farbwert und AL = Zeichen

            CMP AL, 1h
            JE hardConfig

            DEC DL
            CMP DL, 52
            JNE hardCheck
            ;Gucken, ob auf einen Buchstaben in "Normal" geklickt wurde (42-37 checken)
            SUB DL, 10  	    ;DL = 42
normCheck:  MOV AH, 02h
            MOV BH, 0
            MOV DH, 16
            INT 10h             ;Cursor setzen

            MOV AH, 08h
            MOV BH, 0
            INT 10h             ;Lese Zeichen und Attribut an der Cursorposition.

            CMP AL, 1h
            JE normConfig

            DEC DL
            CMP DL, 36
            JNE normCheck
            ;Gucken, ob auf einen Buchstaben in "Easy" geklickt wurde (26-22 checken)
            SUB DL, 10          ;DL = 26
easyCheck:  MOV AH, 02h
            MOV BH, 0
            MOV DH, 16
            INT 10h             ;Cursor setzen

            MOV AH, 08h
            MOV BH, 0
            INT 10h             ;Lese Zeichen und Attribut an der Cursorposition.

            CMP AL, 1h
            JE easyConfig

            DEC DL
            CMP DL, 22
            JNE easyCheck
            JMP endPosi         ;Falls es an keiner Posi eine Uebereinstimmung gab

easyConfig: MOV counter, 4
            MOV speed, 4
            MOV mode, 1         ;Easy
            JMP endPosi

normConfig: MOV counter, 3
            MOV speed, 3
            MOV mode, 2         ;Normal
            JMP endPosi

hardConfig: MOV counter, 2
            MOV speed, 2
            MOV mode, 3         ;Hard
endPosi:    RET
checkPosi   ENDP

checkFood   PROC                ;Prozedur um zu Testen, ob der Kopf der Schlange mit der Position des Futters uebereinstimmt
            XOR DI, DI
            XOR DX, DX
            MOV DI, snakeSize

            MOV AH, 02h
            MOV BH, 0
            MOV DL, randomX
            MOV DH, randomY
            INT 10h             ;Cursor setzen

            MOV AH, 08h
            MOV BH, 0
            INT 10h             ;Lese Zeichen und Attribut an der Cursorposition.

            CMP AL, '+'         ;Ueberpruefen ob das Zeichen an der Cursor Position ein Teil der Schlange ist
            JE foodHit
            JMP endCheck

foodHit:    ADD DL, BL
            ADD DH, BH
            MOV snakeX[DI+1], DL
            MOV snakeY[DI+1], DH
            INC snakeSize
            INC score
            CALL checkScore
            CALL sound          ;Aufruf der Prozedur um einen Sound entsprechend der Situation zu spielen
            CALL printFood
            JMP calls           ;Damit die Schlange nicht 2 Pixel springt muss man early raus (siehe Erklaerung)
endCheck:   RET
checkFood   ENDP
