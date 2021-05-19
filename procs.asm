printLogo   PROC
            MOV AH, 02h             ;BH = page number, DH = row, DL = column
            MOV DL, 0
            MOV DH, 1               ;Position 0,0 (DL = x, DH = y)
            MOV BH, 0h
            INT 10h                 ;Cursor setzen

            MOV AH, 01h             ;Cursorform einstellen
            MOV CX, 2607h           ;CX=2607h heißt unsichtbarer Cursor
            INT 10h
            ;eventuell ändern und mit int 10h machen
            MOV AH, 09h
            MOV DX, OFFSET logo
            INT 21h
            RET
printLogo   ENDP

mausProc    PROC FAR
            enter 0, 0
            push ds             ;sicherheitshalber Datensegementregister sichern
            push di
            push ax             ;sichern wir auch, weil wir jetzt das Datensegment laden wollen
            mov ax, video_seg
            mov es, ax          ;Bildschirmadresse laden
            pop ax

            shr dx, 3           ;y-koord/8 (wir wollen unsere Zeilen in 8ter gruppen haben)
            imul dx, 160        ;um die Zeilenbyteadresse auszurechnen y-koord*160 (160 Bytes pro Zeile)
            shr cx, 3           ;x-koord/8
            shl cx, 1           ;x-koord*2 (damit wir eine wortadresse bekommen)
                                ;cx ist nun eine byteadresse auf den Bildschirm
            add cx, dx
            mov di, cx

            ;da der Assembler nicht weiß, ob es sich um ein Byte oder Word handelt müssen wir es ihm sagen
            ;0FDBh = Block zeichnen
            mov WORD PTR es:[di], '#'   ;das was wir auf den bildschirm schreiben
            pop di
            pop ds
            leave
            ret
mausProc    ENDP

difficulty  PROC
            ;EASY
            mov ah, 02h
            mov dl, 28
            mov dh, 16
            int 10h

            mov ah, 09h
            mov bh, 0h
            mov cx, 1
            mov bl, 00000111b
            mov al, '0'
            int 10h

            ;NORMAL
            mov ah, 02h
            mov dl, 44
            mov dh, 16
            int 10h

            mov ah, 09h
            mov bh, 0h
            mov cx, 1
            mov bl, 00000111b
            mov al, '0'
            int 10h

            ;HARD
            mov ah, 02h
            mov dl, 58
            mov dh, 16
            int 10h

            mov ah, 09h
            mov bh, 0h
            mov cx, 1
            mov bl, 00000111b
            mov al, '0'
            int 10h

            mov cx, 1111110b    ;wir reagieren jetzt auf alle tastenoptionen der maus
            push cs
            pop es
            mov dx, OFFSET mausProc ;wir laden die Adresse von mausProc
            mov ax, 0Ch
            int 33h             ;Maus Interrupt
            mov ax, 1           ;Cursor anschalten
            int 33h             ;nochmal Interrupt
logoLoop:
            xor ah, ah

            ;HARD
            mov ah, 02h
            mov dl, 58
            mov dh, 16
            int 10h

            MOV AH, 08h         ;Lese Zeichen und Attribut an der Cursorposition.
                                ;-> AH = 08h, BH = page number, AH = Farbwert, AL = Zeichen
            MOV BH, 0h
            INT 10h

            cmp al, 23h
            je hardConfig

            ;NORMAL
            mov ah, 02h
            mov dl, 44
            mov dh, 16
            int 10h

            MOV AH, 08h         ;Lese Zeichen und Attribut an der Cursorposition.
                                ;-> AH = 08h, BH = page number, AH = Farbwert, AL = Zeichen
            MOV BH, 0h
            INT 10h

            cmp al, 23h
            je normalConfig

            ;EASY
            mov ah, 02h
            mov dl, 28
            mov dh, 16
            int 10h

            MOV AH, 08h         ;Lese Zeichen und Attribut an der Cursorposition.
                                ;-> AH = 08h, BH = page number, AH = Farbwert, AL = Zeichen
            MOV BH, 0h
            INT 10h

            cmp al, 23h
            je easyConfig
            jmp logoLoop
easyConfig:
            MOV counter, 4
            MOV speed, 4
            MOV mode, 1         ;Easy
            JMP endStart
normalConfig:
            MOV counter, 3
            MOV speed, 3
            MOV mode, 2         ;Normal
            JMP endStart
hardConfig:
            MOV counter, 2
            MOV speed, 2
            MOV mode, 3         ;Hard
endStart:
            mov ax, 0           ;Reset Maus
            int 33h
            mov ax, 3
            int 10h             ;Zeichenbildschirm löschen
            RET
difficulty  ENDP

printFrame  PROC                ;Prozedur zum Zeichnen des Rahmens
            ;Oberer Rand
            MOV AH, 02h         ;BH = page number, DH = row, DL = column
            MOV DL, 0h
            MOV DH, 0h          ;Position 0,0 (DL = x, DH = y)
            MOV BH, 0h
            INT 10h             ;Cursor setzen

            MOV AH, 09h         ;AL = character, BH = page number, BL = color,
            MOV BH, 0h
            MOV AL, 0DBh
            MOV CX, 80          ;CX = Haeufigkeit, mit der Zeichen gedruckt werden
            MOV BL, 00000111b
            INT 10h             ;Zeichen schreiben

            MOV DH, 1h          ;y Position (2te zeile)
linkeSeite:                     ;Zeichnet den linken Rand
            MOV AH, 02h
            MOV DL, 0h          ;Position 0,1 (DL = x, DH = y)
            MOV BH, 0h
            INT 10h

            MOV AH, 09h
            MOV BH, 0h
            MOV AL, 0DBh        ;Block als Attribut
            MOV CX, 1
            MOV BL, 00000111b   ;Farbe: Weiss
            INT 10h             ;Zeichen schreiben

            INC DH              ;Addiert auf das DH Register eine 1
            CMP DH, 24          ;Wir gehen 24 Zeilen runter
            JNE linkeSeite      ;Falls nicht gleich weiter mit der linken Seite
rechteSeite:                    ;Zeichnet den rechten Rand
            MOV AH, 02h
            MOV DL, 79          ;Position 0,79 (DL = x, DH = y)
            MOV BH, 0h
            INT 10h

            MOV AH, 09h
            MOV BH, 0h
            MOV AL, 0DBh
            MOV CX, 1
            MOV BL, 00000111b   ;Farbe: Weiss
            INT 10h

            INC DH
            CMP DH, 24
            JNE rechteSeite     ;Falls nicht gleich weiter mit der rechten Seite

            ;Unterer Rand
            MOV AH, 02h
            MOV DL, 0h
            MOV DH, 22          ;Position 0,22 (DL = x, DH = y)
            MOV BH, 0h
            INT 10h

            MOV AH, 09h
            MOV BH, 0h
            MOV AL, 0DBh        ;0 vor dem DBh wegen dem Hexwert
            MOV CX, 80
            MOV BL, 00000111b
            INT 10h

            ;Um eine kleine Gap zulassen für den "score"-String
            MOV AH, 02h
            MOV DL, 0h
            MOV DH, 24          ;Position 0,24 (DL = x, DH = y)
            MOV BH, 0h
            INT 10h

            MOV AH, 09h
            MOV BH, 0h
            MOV AL, 0DBh
            MOV CX, 80
            MOV BL, 00000111b
            INT 10h
            RET                 ;nicht vergessen
printFrame  ENDP

printScore  PROC                ;Prozedur um "Score" zu printen
            MOV AH, 02h
            MOV DL, 35
            MOV DH, 23          ;Position 0,23 (DL = x, DH = y)
            MOV BH, 0h
            INT 10h

            MOV DX, OFFSET scoreString
            MOV AH, 09h
            INT 21h             ;Zeichenkette darstellen (in DX muss der OFFSET des zeigers,
                                ;der eine mit $ abgeschlossene Zeichenkette angibt drinstehen)
            RET
printScore  ENDP

printPoints PROC                ;Prozedur um die Punktzahl mit Potenzzerlegung zu zerlegen, falls er zu groß wird um ihn auszugeben
            XOR AX, AX
            MOV AL, score
            MOV DL, 42

            CMP AL, 9
            JG zehner           ;Wenn über 10 JMP zu Zehner-Potenzzerlegung
            JMP printEiner
zehner:
            XOR BL, BL
            MOV BL, 0Ah         ;=> 10
            DIV BL              ;AX/BL. Schreibt das Ergebnis in AL und den Rest in AH

            ADD AL, '0'         ;Addiert eine 48 (ASCII Wert fuer 0, um es als Zeichen darzustellen)
printZehner:
            MOV divrest, AH     ;in divrest ist jetzt der Rest der Division

            MOV AH, 02h
            MOV DH, 23
            MOV BH, 0h
            INT 10h

            MOV AH, 09h
            MOV BH, 0h
            MOV CX, 1
            MOV BL, 00000111b
            INT 10h

            MOV AL, divrest     ;in AL den Rest der Division schieben
            INC DL
printEiner:
            ADD AL, '0'

            MOV AH, 02h
            MOV DH, 23
            MOV BH, 0h
            INT 10h

            MOV AH, 09h
            MOV BH, 0h
            MOV CX, 1
            MOV BL, 00000111b
            INT 10h
            RET
printPoints ENDP

printSnake  PROC                ;Prozedur um die Schlange zu printen
                                ;Setzt den Cursor an snakeX[DI] und snakeY[DI] und gibt dort ein '+' aus
            CALL printPoints    ;Prozedur um die Punktzahl zu printen
            MOV DI, 0h          ;int x = 0, DI (destination index) wird hier als Zeiger genommen
printLoop:                      ;Schleife um alle Einträge des snakeX und snakeY Arrays durchzugehen
            MOV AH, 02h
            MOV DL, snakeX[DI]
            MOV DH, snakeY[DI]
            MOV BH, 0h
            INT 10h

            MOV AH, 09h
            MOV BH, 0h
            MOV AL, '+'
            MOV CX, 1
            MOV BL, 00101110b   ;Farbe Gelb und der Hintergrund Gruen
            INT 10h

            CMP DI, snakeSize   ;Bis DI = snakeSize
            JE endPrint
            INC DI
            JMP printLoop
endPrint:
            XOR DI, DI
            RET
printSnake  ENDP

deleteTail  PROC                ;Prozedur um den Schwanz der Schlange zu loeschen, damit keine enDLose Spur hinter sich hergezogen wird
            XOR DI, DI

            MOV AH, 2h
            MOV DL, snakeX[DI]  ;Ersten Eintrag des snakeX-Arrays in DL speichern
            MOV DH, snakeY[DI]  ;Ersten Eintrag des snakeY-Arrays in DH speichern
            MOV BH, 0h
            INT 10h

            MOV AH, 09h
            MOV BH, 0h
            MOV AL, 0DBh
            MOV CX, 1
            MOV BL, 00000000b   ;Farbe: Schwarz
            INT 10h
            RET
deleteTail  ENDP

resetSnake  PROC                ;Prozedur, um den body der Schlange anzupassen (so sieht es aus als würde sie sich bewegen)
            XOR CX, CX
            XOR DI, DI
resetLoop:                      ;Die Werte des Arrays werden "durchgereicht", also der Wert an Indexstelle 0
                                ;bekommt den Wert an Indexstelle 1 . Dieser bekommt wiederrum den an Indexstelle 2 usw.
            MOV CL, snakeX[DI+1]
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

            MOV DL, snakeX[DI]
            MOV DH, snakeY[DI]

            MOV AH, 02h         ;Setze Cursor Position. -> AH = 02h, BH = page number, DH = Zeile, DL = Spalte
            MOV BH, 0h
            INT 10h

            MOV AH, 08h         ;Lese Zeichen und Attribut an der Cursorposition.
                                ;-> AH = 08h, BH = page number, AH = Farbwert, AL = Zeichen
            MOV BH, 0h
            INT 10h

            CMP AL, '+'         ;Ueberpruefen ob das Zeichen an der Cursor Position ein Teil der Schlange ist
            JE ende
            XOR DI, DI
            RET
collision   ENDP

;https://stackoverflow.com/questions/17855817/generating-a-random-number-within-range-of-0-9-in-x86-8086-assembly
randomDL    PROC                ;Prozedur um eine Randomzahl für DL zu erzeugen
            MOV AH, 00h         ;Interrupt um die Systemzeit zu erhalten
            INT 1Ah             ;In CX:DX ist jetzt die Anzahl der clock ticks seit Mitternacht

            MOV AX, DX
            XOR DX, DX
            MOV CX, 10
            DIV CX              ;In DX steht dann der Rest der Division -> Range von 0..9

            CMP DL, 0h
            JE istNull
            JMP randomDLend
istNull:                        ;Damit wir keine 0 bekommen
            INC DL
randomDLend:
            XOR AX, AX
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

            MOV AX, DX          ;DX in AX rein
            XOR DX, DX          ;DX leeren
            MOV CX, 10          ;CX bekommt die 10
            DIV CX              ;weil wir nur die Ganzzahl brauchen
            CMP DL, 0h
            JE istNull2         ;Analog zu oben
            JMP randomDHend
istNull2:
            INC DL
randomDHend:
            XOR AX, AX
            XOR BX, BX
            MOV AL, DL
            MOV BL, 2
            MUL BL              ;Multiplikation mit 2, max Wert: 2*9 = 18
            MOV randomY, AL
            RET
randomDH    ENDP

printFutter PROC                ;Prozedur um an Randompositionen Futter zu erzeugen
futterStart:
            MOV AH, 02h
            MOV DL, randomX
            MOV DH, randomY
            MOV BH, 0h
            INT 10h             ;Futterpositionierung

            MOV AH, 08h
            MOV BH, 0h
            INT 10h             ;Zuerst Zeichen an der Stelle lesen denn

            CMP AL, '+'         ;man muss sicherstellen, das das Futter nicht an der Stelle eines Schlangenkoerperteils spawnen kann
            JE unterSchlange    ;falls es doch so ist
            JMP futterEnd
unterSchlange:
            CALL randomDL       ;neuer Randomwert für DL
            CALL randomDH       ;neuer Randomwert für DH
            JMP futterStart
futterEnd:
            MOV AH, 09h
            MOV BH, 0h
            MOV AL, 0FEh        ;Zeichen: "black square"
            MOV CX, 1
            MOV BL, 00001100b   ;Farbe Rosa
            INT 10h             ;Futter printen
            RET
printFutter ENDP

checkScore  PROC
            cmp mode, 1         ;Easy
            je easyMode
            cmp mode, 2         ;normal
            je normalMode
            cmp mode, 3         ;normal
            je hardMode
            jmp endscore
easyMode:
            cmp score, 30
            je ende
normalMode:
            cmp score, 45
            je ende
hardMode:
            cmp score, 60
            je ende
endScore:
            RET
checkScore  ENDP

checkFood   PROC                ;Prozedur um zu sehen ob der Kopf der Schlange mit der Position des Futters uebereinstimmt
            XOR DI, DI
            MOV DI, snakeSize
            XOR DX, DX
            MOV DL, randomX
            MOV DH, randomY
            CMP snakeX[DI], DL
            JE xstimmt
            JMP endCheck
xstimmt:                        ;Wenn x Position vom Kopf der Schlange mit der x Position des Futters uebereinstimmt
            CMP snakeY[DI], DH
            JE ystimmt
            JMP endCheck
ystimmt:                        ;Wenn x und y Positionen vom Kopf der Schlange mit den x und y Positionen des Futters uebereinstimmen
            ADD DL, BL
            ADD DH, BH          ;Einzeln, weil es ansonsten Probleme gab (keine ahnung wieso)
            MOV snakeX[DI+1], DL
            MOV snakeY[DI+1], DH
            INC snakeSize
            INC score
            CALL checkScore
            ;CALL speedDec
            CALL randomDL
            CALL randomDH
            CALL printFutter
            JMP calls           ;Damit die Schlange nicht 2 Pixel springt muss ich early raus (siehe Erklaerung)
endCheck:
            XOR DI, DI
            RET
checkFood   ENDP

speedDec    PROC                ;Prozedur um die speed Variable zu Dekrementieren
            cmp score, 5
            je firstDec
            jmp endSpeed
firstDec:
            DEC speed
endSpeed:
            RET
speedDec    ENDP

endscreen   PROC                ;Endroutine
            MOV AH, 00h
            MOV AL, 3h          ;Videomodus 3
            INT 10h             ;Bildschirm loeschen

            MOV DX, OFFSET lose ;Standartmaessig ist der "lose"-String ausgewaehlt

            cmp mode, 1         ;Easy
            je easyWinCon
            cmp mode, 2         ;normal
            je normalWinCon
            cmp mode, 3         ;normal
            je hardWinCon
            jmp ausgabe
easyWinCon:
            CMP score, 30
            JE winScreen        ;Falls man 50 Punkte erreicht kommt der "win"-String
            jmp goodbye
normalWinCon:
            CMP score, 45
            JE winScreen        ;Falls man 50 Punkte erreicht kommt der "win"-String
            jmp goodbye
hardWinCon:
            CMP score, 60
            JE winScreen        ;Falls man 50 Punkte erreicht kommt der "win"-String
winScreen:
            MOV DX, OFFSET win
ausgabe:
            MOV AH, 09h
            INT 21h
goodbye:
            RET
endscreen   ENDP
