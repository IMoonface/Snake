printLogo   PROC                ;Prozedur zum Printen des Logos
            MOV AH, 02h         ;BH = Seitennummer, DL = Spalte, DH = Zeile
            MOV BH, 0
            MOV DL, 0
            MOV DH, 1           ;Position 0,1 (DL = x, DH = y)
            INT 10h             ;Cursor setzen

            MOV AH, 01h
            MOV CX, 2607h       ;CX=2607h heißt unsichtbarer Cursor
            INT 10h             ;Cursorform einstellen

            MOV AH, 09h
            MOV DX, OFFSET logo
            INT 21h
            RET
printLogo   ENDP

mausProc    PROC FAR            ;Muss FAR sein, weil vom Interrupt vorgeschrieben!
            MOV AX, video_seg
            MOV ES, AX          ;Bildschirmadresse laden

                                ;DX = vertical cursor position
            SHR DX, 3           ;Y-Koord/8, weil wir nicht mit den Pixeln arbeiten wollen, sondern mit den Blöcken im Videomodus
            IMUL DX, 160        ;Vorzeichenbehaftete Multiplikation, um die Zeilenbyteadresse auszurechnen y-koord*160 (Siehe Erklaerung)

                                ;CX = horizontal cursor position
            SHR CX, 3           ;X-Koord/8
            SHL CX, 1           ;X-Koord*2, denn ein Block ist ja 2 Bytes lang

            ADD CX, DX          ;In CX steht jetzt unsere Bildschirmposition
            MOV DI, CX          ;Umweg mit DI, weil wir nicht direkt CX benutzen können (Illegal indexing mode)

                                ;Da der Assembler nicht weiß, ob es sich um ein Byte oder Word handelt muessen wir es ihm sagen
            MOV WORD PTR ES:[DI], 1h ;1h = das was wir auf den Bildschirm schreiben
            RET                 ;Zum zurueckspringen
mausProc    ENDP

difficulty  PROC
            MOV AX, 0Ch         ;Benutzerdefinierte Unterroutine und Eingabemaske für die Maus festlegen
            PUSH CS             ;Wir benoetigen ES:DX = far pointer to user interrupt, dazu pushen wir CS
            POP ES              ;und laden es in ES
            MOV CX, 1111110b    ;Wir reagieren jetzt auf alle Tastenoptionen der Maus
            MOV DX, OFFSET mausProc ;Wir laden die Adresse von mausProc
            INT 33h             ;Maus Interrupt

            MOV AX, 01h         ;Zeige Mauszeiger
            INT 33h

logoLoop:   ;HARD
            MOV AH, 02h
            MOV BH, 0
            MOV DL, 58
            MOV DH, 16
            INT 10h             ;Cursor setzen

            MOV AH, 08h         ;-> AH = 08h, BH = Seitennummer, AH = Farbwert, AL = Zeichen
            MOV BH, 0
            INT 10h             ;Lese Zeichen und Attribut an der Cursorposition.

            CMP AL, 1h
            JE hardConfig

            ;NORMAL
            MOV AH, 02h
            MOV BH, 0
            MOV DL, 44
            MOV DH, 16
            INT 10h             ;Cursor setzen

            MOV AH, 08h
            MOV BH, 0
            INT 10h             ;Lese Zeichen und Attribut an der Cursorposition.

            CMP AL, 1h
            JE normConfig

            ;EASY
            MOV AH, 02h
            MOV BH, 0
            MOV DL, 28
            MOV DH, 16
            INT 10h             ;Cursor setzen

            MOV AH, 08h
            MOV BH, 0
            INT 10h             ;Lese Zeichen und Attribut an der Cursorposition.

            CMP AL, 1h
            JE easyConfig
            JMP logoLoop

easyConfig: MOV counter, 4
            MOV speed, 4
            MOV mode, 1         ;Easy
            JMP endStart

normConfig: MOV counter, 3
            MOV speed, 3
            MOV mode, 2         ;Normal
            JMP endStart

hardConfig: MOV counter, 2
            MOV speed, 2
            MOV mode, 3         ;Hard

endStart:   MOV AX, 0h         ;Reset Maus
            INT 33h

            MOV AH, 00h         ;Bildschirm Loeschen
            MOV AL, 3
            INT 10h
            RET
difficulty  ENDP

printFrame  PROC                ;Prozedur zum Zeichnen des Rahmens
            ;Oberer Rand
            MOV AH, 02h
            MOV BH, 0
            MOV DL, 0
            MOV DH, 0
            INT 10h             ;Cursor setzen

            MOV AH, 09h         ;AL = Zeichen, BH = Seitennummer, BL = Farbe, CX = Haeufigkeit, mit der Zeichen gedruckt werden
            MOV AL, 0DBh
            MOV BH, 0
            MOV BL, 00000111b   ;Farbe: Weiss
            MOV CX, 80
            INT 10h             ;Zeichen schreiben

            MOV DH, 1           ;y = 1
;Zeichnet den linken Rand
leftSide:   MOV AH, 02h
            MOV BH, 0
            MOV DL, 0           ;Position 0,1 (DL = x, DH = y)
            INT 10h             ;Cursor setzen

            MOV AH, 09h
            MOV AL, 0DBh        ;0DBh = Block
            MOV BH, 0
            MOV BL, 00000111b
            MOV CX, 1
            INT 10h             ;Zeichen schreiben

            INC DH              ;Addiert auf das DH Register eine 1
            CMP DH, 24          ;Wir gehen 24 Zeilen runter
            JNE leftSide        ;Falls nicht equal -> Weiter mit der linken Seite
;Zeichnet den rechten Rand
rightSide:  MOV AH, 02h
            MOV BH, 0
            MOV DL, 79
            INT 10h             ;Cursor setzen

            MOV AH, 09h
            MOV AL, 0DBh
            MOV BH, 0
            MOV BL, 00000111b
            MOV CX, 1
            INT 10h             ;Zeichen schreiben

            INC DH
            CMP DH, 24
            JNE rightSide       ;Falls nicht equal -> Weiter mit der rechten Seite

            ;Unterer Rand
            MOV AH, 02h
            MOV BH, 0
            MOV DL, 0
            MOV DH, 22
            INT 10h             ;Cursor setzen

            MOV AH, 09h
            MOV AL, 0DBh
            MOV BH, 0
            MOV BL, 00000111b
            MOV CX, 80
            INT 10h             ;Zeichen schreiben

            ;Um eine kleine Gap zulassen für den "score"-String
            MOV AH, 02h
            MOV BH, 0
            MOV DL, 0
            MOV DH, 24
            INT 10h             ;Cursor setzen

            MOV AH, 09h
            MOV AL, 0DBh
            MOV BH, 0
            MOV BL, 00000111b
            MOV CX, 80
            INT 10h             ;Zeichen schreiben
            RET
printFrame  ENDP

printScore  PROC                ;Prozedur um "Score" zu printen
            MOV AH, 02h
            MOV BH, 0
            MOV DL, 35
            MOV DH, 23
            INT 10h             ;Cursor setzen

            MOV DX, OFFSET scoreString
            MOV AH, 09h
            INT 21h             ;Zeichenkette darstellen (in DX muss der OFFSET des Zeigers, der eine mit $ abgeschlossene Zeichenkette angibt drinstehen)
            RET
printScore  ENDP

printPoints PROC                ;Prozedur um die Punktzahl mit Potenzzerlegung zu zerlegen, falls sie zu groß wird um sie auszugeben
            XOR AX, AX
            MOV AL, score
            MOV DL, 42

            CMP AL, 9
            JG zehner           ;Wenn ueber 10 JMP zu Zehner-Potenzzerlegung
            JMP printEiner

zehner:     XOR BL, BL
            MOV BL, 0Ah         ;0Ah = 10
            DIV BL              ;AX/BL. Schreibt das Ergebnis in AL und den Rest in AH
            ADD AL, '0'         ;Addiert eine 48 (ASCII Wert fuer 0), um es als Zeichen darzustellen

            MOV divrest, AH     ;In divrest ist jetzt der Rest der Division

            MOV AH, 02h
            MOV BH, 0
            MOV DH, 23
            INT 10h             ;Cursor setzen

            MOV AH, 09h
            MOV BH, 0
            MOV BL, 00000111b
            MOV CX, 1
            INT 10h             ;Zeichen schreiben

            MOV AL, divrest     ;In AL den Rest der Division schieben
            INC DL              ;DI+1

printEiner: ADD AL, '0'
            MOV AH, 02h
            MOV BH, 0
            MOV DH, 23
            INT 10h             ;Cursor setzen

            MOV AH, 09h
            MOV BH, 0
            MOV BL, 00000111b
            MOV CX, 1
            INT 10h             ;Zeichen schreiben
            RET
printPoints ENDP

printSnake  PROC                ;Prozedur um die Schlange zu printen
            CALL printPoints    ;Prozedur um die Punktzahl zu printen
            XOR DI, DI          ;DI (destination index) wird hier als Zeiger genommen
;Schleife um alle Einträge des snakeX und snakeY Arrays durchzugehen
printLoop:  MOV AH, 02h
            MOV BH, 0
            MOV DL, snakeX[DI]
            MOV DH, snakeY[DI]  ;Setzt den Cursor an snakeX[DI] und snakeY[DI]
            INT 10h

            MOV AH, 09h
            MOV AL, '+'         ;und gibt dort ein '+' aus
            MOV BH, 0
            MOV BL, 00101110b   ;Farbe Gelb und der Hintergrund Gruen
            MOV CX, 1
            INT 10h

            CMP DI, snakeSize   ;Bis DI = snakeSize
            JE endPrint
            INC DI              ;DI hochzaehlen
            JMP printLoop
endPrint:   XOR DI, DI
            RET
printSnake  ENDP

deleteTail  PROC                ;Prozedur um den Schwanz der Schlange zu loeschen, damit keine endlose Spur hinter sich hergezogen wird
            XOR DI, DI

            MOV AH, 02h
            MOV BH, 0
            MOV DL, snakeX[DI]  ;Ersten Eintrag des snakeX-Arrays in DL speichern
            MOV DH, snakeY[DI]  ;Ersten Eintrag des snakeY-Arrays in DH speichern
            INT 10h             ;Cursor setzen

            MOV AH, 09h
            MOV AL, 0DBh
            MOV BH, 0
            MOV BL, 00000000b   ;Farbe: Schwarz
            MOV CX, 1
            INT 10h             ;Zeichen schreiben
            RET
deleteTail  ENDP

resetSnake  PROC                ;Prozedur, um den body der Schlange anzupassen (so sieht es aus als wuerde sie sich bewegen)
            XOR CX, CX
            XOR DI, DI
;Die Werte des Arrays werden "durchgereicht", also der Wert an Indexstelle 0 bekommt den Wert an Indexstelle 1 . Dieser bekommt wiederrum den an Indexstelle 2 usw.
resetLoop:  MOV CL, snakeX[DI+1]
            MOV CH, snakeY[DI+1]
            MOV snakeX[DI], CL
            MOV snakeY[DI], CH
            INC DI
            CMP DI, snakeSize
            JNE resetLoop
            MOV DI, snakeSize   ;Gleich schon setzen, weil wir es im entsprechenden "move*"-label gleich brauchen
            RET
resetSnake  ENDP

collision   PROC                ;Ueberpruefen ob sich die Schlange selber frisst
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
            RET
collision   ENDP

;Quelle: https://stackoverflow.com/questions/17855817/generating-a-random-number-within-range-of-0-9-in-x86-8086-assembly
randomDL    PROC                ;Prozedur um eine Randomzahl für DL zu erzeugen
            MOV AH, 00h         ;Interrupt um die Systemzeit zu erhalten
            INT 1Ah             ;In CX:DX ist jetzt die Anzahl der clock ticks seit Mitternacht

            MOV AX, DX          ;DX in AX rein
            XOR DX, DX          ;DX leeren
            MOV CX, 10          ;CX bekommt die 10
            DIV CX              ;AX/10 weil wir nur die Ganzzahl brauchen
                                ;In DL steht jetzt das Ergebnis der Division
            CMP DL, 0
            JE istNull
            JMP endRandDL

istNull:    INC DL              ;Damit wir keine 0 bekommen

endRandDL:  XOR AX, AX
            XOR BX, BX
            MOV AL, DL
            MOV BL, 8
            MUL BL              ;Multiplikation mit 8, max Wert: 8*9 = 72
            MOV randomX, AL     ;In randomX steht jetzt die Pseudorandomzahl für die x-Achse
            RET
randomDL    ENDP

randomDH    PROC                ;Prozedur um eine Randomzahl für DH zu erzeugen
            MOV AH, 00h
            INT 1Ah

            MOV AX, DX
            XOR DX, DX
            MOV CX, 10
            DIV CX
            CMP DL, 0
            JE istNull2         ;Selbe wie oben
            CMP DL, 1
            JE istEins
            JMP endRandDH

istNull2:   INC DL

istEins:    INC DL              ;Damit wir keine 1 bekommen

endRandDH:  XOR AX, AX
            XOR BX, BX
            MOV AL, DL
            MOV BL, 2
            MUL BL              ;Multiplikation mit 2, max Wert: 2*9 = 18
            MOV randomY, AL
            RET
randomDH    ENDP

printFood   PROC                ;Prozedur um an Randompositionen Futter zu erzeugen
foodStart:
            MOV AH, 02h
            MOV BH, 0
            MOV DL, randomX
            MOV DH, randomY
            INT 10h             ;Cursor setzen (Futterposition)

            MOV AH, 08h
            MOV BH, 0
            INT 10h             ;Zuerst Zeichen an der Stelle lesen denn

            CMP AL, '+'         ;man muss sicherstellen, das das Futter nicht an der Stelle eines Schlangenkoerperteils spawnen kann
            JE unterSnake       ;falls es doch so ist
            JMP endFood

unterSnake: CALL randomDL       ;Neuer Randomwert für DL
            CALL randomDH       ;Neuer Randomwert für DH
            JMP foodStart       ;Von vorne anfangen

endFood:    MOV AH, 09h
            MOV BH, 0
            MOV AL, 0FEh        ;Zeichen: "black square"
            MOV CX, 1
            MOV BL, 00001100b   ;Farbe Rosa (Fleischfarbe)
            INT 10h             ;Zeichen schreiben
            RET
printFood   ENDP

checkScore  PROC                ;Prozedur um zu gucken ob der Punktestand zum Gewinnen erreicht wurde
            cmp mode, 1         ;Easy
            JE easyMode
            cmp mode, 2         ;Normal
            JE normalMode
            cmp mode, 3         ;Hard
            JE hardMode
            JMP endscore

easyMode:   cmp score, 30
            JE ende

normalMode: cmp score, 45
            JE ende

hardMode:   cmp score, 60
            JE ende

endScore:   RET
checkScore  ENDP

checkFood   PROC                ;Prozedur um zu sehen ob der Kopf der Schlange mit der Position des Futters uebereinstimmt
            XOR DI, DI
            MOV DI, snakeSize
            XOR DX, DX
            MOV DL, randomX
            MOV DH, randomY
            CMP snakeX[DI], DL
            JE xstimmt          ;Wenn x Position vom Kopf der Schlange mit der x Position des Futters uebereinstimmt
            JMP endCheck

xstimmt:    CMP snakeY[DI], DH
            JE ystimmt          ;Wenn x und y Positionen vom Kopf der Schlange mit den x und y Positionen des Futters uebereinstimmen
            JMP endCheck

ystimmt:    ADD DL, BL
            ADD DH, BH          ;Einzeln, weil es ansonsten Probleme gab (keine ahnung wieso)
            MOV snakeX[DI+1], DL
            MOV snakeY[DI+1], DH
            INC snakeSize
            INC score
            CALL checkScore
            CALL randomDL
            CALL randomDH
            CALL printFood
            JMP calls           ;Damit die Schlange nicht 2 Pixel springt muss ich early raus (siehe Erklaerung)

endCheck:   XOR DI, DI
            RET
checkFood   ENDP

endscreen   PROC                ;Endroutine
            MOV AH, 00h
            MOV AL, 3
            INT 10h             ;Bildschirm loeschen

            MOV DX, OFFSET lose ;Standartmaessig ist der "lose"-String ausgewaehlt

            cmp mode, 1         ;Easy
            JE easyWinCon
            cmp mode, 2         ;Normal
            JE normWinCon
            cmp mode, 3         ;Hard
            JE hardWinCon
            JMP ausgabe

easyWinCon: CMP score, 30
            JE winScreen        ;Falls man 30 Punkte erreicht kommt der "win"-String
            JMP ausgabe

normWinCon: CMP score, 45
            JE winScreen        ;Falls man 45 Punkte erreicht kommt der "win"-String
            JMP ausgabe

hardWinCon: CMP score, 60
            JE winScreen        ;Falls man 60 Punkte erreicht kommt der "win"-String
            JMP ausgabe

winScreen:  MOV DX, OFFSET win

ausgabe:    MOV AH, 09h
            INT 21h
            RET
endscreen   ENDP
