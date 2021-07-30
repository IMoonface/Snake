printLogo   PROC                ;Prozedur zum Printen des Logos
            MOV AH, 02h
            MOV BH, 0           ;BH = Seitennummer
            MOV DL, 0           ;DL = Spalte
            MOV DH, 0           ;DH = Zeile, Position 0,0 (DL = x, DH = y)
            INT 10h             ;Cursor setzen

            MOV AH, 01h
            MOV CX, 2607h
            INT 10h

            MOV AH, 09h
            MOV DX, OFFSET logo ;Offset des Zeigers, der eine mit $ abgeschlossene Zeichenkette angibt
            INT 21h             ;Zeichenkette darstellen
            RET
printLogo   ENDP

mausProc    PROC FAR            ;Muss FAR sein, weil vom Interrupt vorgeschrieben!
            MOV AX, video_seg
            MOV ES, AX          ;Um in den Videospeicher schreiben zu koennen, setzt man ES auf 0B800h

            ;DX = Vertikale Cursorposition
            SHR DX, 3           ;Y-Koord/8, weil wir nicht mit den Pixeln arbeiten wollen, sondern mit den Bloecken im Videomodus
            IMUL DX, 160        ;Vorzeichenbehaftete Multiplikation, um die Zeilenbyteadresse auszurechnen y-koord*160 (Siehe Erklaerung)

            ;CX = Horizontale Cursorposition
            SHR CX, 3           ;X-Koord/8
            SHL CX, 1           ;X-Koord*2, denn ein Block ist ja 2 Bytes lang

            ADD CX, DX          ;In CX steht jetzt unsere Bildschirmposition
            MOV DI, CX          ;Umweg mit DI, weil wir nicht direkt CX benutzen koennen (Illegal indexing mode)
                                ;Da der Assembler nicht weiß, ob es sich um ein Byte oder Word handelt muessen wir es ihm sagen
            MOV WORD PTR ES:[DI], 1h
            CALL checkPosi      ;Aufruf der Prozedur um zu testen, ob Easy, Normal oder Hard angeklickt wurde

            MOV AX, 01h         ;Zeige Mauszeiger, damit das Zeichen was wir geschrieben haben nicht den Mauszeiger verdeckt
            INT 33h
            RET                 ;Zum zurueckspringen
mausProc    ENDP

difficulty  PROC                ;Prozedur um den Schwierigkeitsgrad zu ermitteln
            MOV AX, 0Ch         ;Benutzerdefinierte Unterroutine und Eingabemaske fuer die Maus festlegen
            PUSH CS             ;Wir benoetigen ES:DX = far pointer to user interrupt, dazu pushen wir CS
            POP ES              ;und laden es in ES
            MOV CX, 1111110b    ;Wir reagieren jetzt auf alle Tastenoptionen der Maus (außer das Bewegen der Maus)
                                ;Routine bei ES: DX wird aufgerufen, wenn ein Ereignis eintritt und das entsprechende Bit in der Benutzermaske gesetzt ist
            MOV DX, OFFSET mausProc ;Wir laden die Adresse von mausProc
            INT 33h             ;Maus Interrupt
            MOV AX, 01h         ;Zeige Mauszeiger
            INT 33h

diffLoop:   CMP mode, 0
            JE diffLoop

endDiff:    MOV AX, 0h          ;Reset Maus
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

            MOV AH, 09h
            MOV AL, 0DBh        ;AL = Zeichen
            MOV BH, 0           ;BH = Seitennummer
            MOV BL, 00000111b   ;BL = Farbe, Farbe: Weiss
            MOV CX, 80          ;CX = Haeufigkeit, mit der Zeichen gedruckt werden
            INT 10h             ;Zeichen schreiben

            MOV DH, 1           ;y = 1

            ;Zeichnet den linken Rand
leftSide:   MOV AH, 02h
            MOV BH, 0
            MOV DL, 0
            INT 10h             ;Cursor setzen

            MOV AH, 09h
            MOV AL, 0DBh        ;0DBh = Block
            MOV BH, 0
            MOV BL, 00000111b
            MOV CX, 1
            INT 10h             ;Zeichen schreiben

            INC DH
            CMP DH, 24          ;Wir gehen 24 Zeilen runter
            JNE leftSide

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

            ;Um eine kleine Gap zulassen fuer den "score"-String
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
            MOV DL, 33
            MOV DH, 23
            INT 10h             ;Cursor setzen

            CMP mode, 1
            JE easyPrint
            CMP mode, 2
            JE medPrint
            CMP mode, 3
            JE hardPrint

easyPrint:  MOV DX, OFFSET easyScore
            JMP goalPrint

medPrint:   MOV DX, OFFSET mediumScore
            JMP goalPrint

hardPrint:  MOV DX, OFFSET hardScore

goalPrint:  MOV AH, 09h
            INT 21h             ;Zeichenkette darstellen
            RET
printScore  ENDP

printPoints PROC                ;Prozedur um die Punktzahl mit Potenzzerlegung zu zerlegen, falls sie zu gross wird, um sie auszugeben
            XOR AX, AX
            MOV AL, score
            MOV DL, 40

            CMP AL, 9
            JG zehner           ;Wenn ueber 10 JMP zu Zehner-Potenzzerlegung
            JMP printEiner      ;Ansonsten printe nur die Einerstelle

zehner:     XOR BL, BL
            MOV BL, 10
            DIV BL              ;Wurde AX durch einen 8-Bit-Wert geteilt, so steht der Quotient im AL-Register und der Rest im AH-Register
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
            INC DL

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
            CALL printPoints    ;Aufruf der Prozedur um die Punktzahl mit Potenzzerlegung zu zerlegen, falls sie zu gross wird, um sie auszugeben
            XOR DI, DI
            DEC DI

;Schleife um alle Eintraege des snakeX und snakeY Arrays durchzugehen
printLoop:  INC DI              ;DI hochzaehlen (mussten wir leider so ungeschickt loesen)
            MOV AH, 02h
            MOV BH, 0
            MOV DL, snakeX[DI]
            MOV DH, snakeY[DI]
            INT 10h

            MOV AH, 09h
            MOV AL, '+'         ;und gibt dort ein '+' aus
            MOV BH, 0
            MOV BL, 00101110b   ;Farbe Gelb (Bits 4-0) und der Hintergrund Gruen (Bits 7-5), 8 Bit fuers Blinken
            MOV CX, 1
            INT 10h

            CMP DI, snakeSize
            JNE printLoop
            RET
printSnake  ENDP

deleteTail  PROC                ;Prozedur um den Schwanz der Schlange zu loeschen (damit keine endlose Spur hinter sich hergezogen wird)
            XOR DI, DI
            MOV AH, 02h
            MOV BH, 0
            MOV DL, snakeX[DI]
            MOV DH, snakeY[DI]
            INT 10h             ;Cursor setzen

            MOV AH, 09h
            MOV AL, '0'         ;Das Zeichen hier ist eig. egal es darf nur nicht '+', Block oder Square sein
            MOV BH, 0
            MOV BL, 00000000b   ;Farbe: Schwarz
            MOV CX, 1
            INT 10h             ;Zeichen schreiben
            RET
deleteTail  ENDP

resetSnake  PROC                ;Prozedur um den body der Schlange anzupassen (so sieht es aus als wuerde sie sich bewegen)
            XOR CX, CX
            XOR DI, DI

;Die Werte des Arrays werden "durchgereicht", also der Wert an Indexstelle 0 bekommt den Wert an
;Indexstelle 1 und dieser bekommt wiederrum den an Indexstelle 2 usw.
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

snakeInc    PROC                ;Prozedur um den body der Schlange zu verlaengern
            XOR DI, DI
            XOR CX, CX
            MOV DI, snakeSize

;Die Werte des Arrays werden "durchgeschoben", also der Wert an der hoechsten Indexstelle+1 bekommt den Wert
;der hoechsten Indexstelle und dieser bekommt wiederrum den Wert an der 2t hoechsten Indexstelle usw.
snakeLoop:  MOV CL, snakeX[DI]
            MOV CH, snakeY[DI]
            MOV snakeX[DI+1], CL
            MOV snakeY[DI+1], CH
            DEC DI
            CMP DI, 0
            JNE snakeLoop
            MOV snakeX[DI], 1h
            MOV snakeY[DI], 1h
            RET
snakeInc    ENDP

;Quelle: https://stackoverflow.com/questions/17855817/generating-a-random-number-within-range-of-0-9-in-x86-8086-assembly
randomDL    PROC                ;Prozedur um eine Randomzahl fuer DL zu erzeugen
            MOV AH, 00h         ;Interrupt um die Systemzeit zu erhalten, CX Hoeherer Teil der Taktzaehlung, DX Niederwertiger Teil der Taktzaehlung
            INT 1Ah             ;Der "System-Timer" (im Unterschied zum realen Zeitschaltuhr) ist der Timer, der eingestellt wird, wenn das System
                                ;gestartet ist. Diese Zeit ist voruebergehend und dauert nur solange das System eingeschaltet ist.

            MOV AX, DX
            XOR DX, DX
            XOR CX, CX
            MOV CX, 10
            DIV CX              ;AX/10 weil wir nur eine Ganzzahl brauchen
                                ;Liegt der <Quelloperand> im 16-Bit-Format vor, dann steht das Ergebnis der Division im Registerpaar AX:DX
                                ;In DL steht der Rest
            CMP DL, 0
            JE istNullDL
            JMP endRandDL

istNullDL:  INC DL              ;Damit wir min. eine 1 bekommen

endRandDL:  SHL DL, 3           ;Sowas wie Multiplikation mit 8, max Wert: 8*9 = 72, min Wert: 8*1 = 8
            MOV randomX, DL
            RET
randomDL    ENDP

randomDH    PROC                ;Prozedur um eine Randomzahl fuer DH zu erzeugen
            MOV AH, 00h
            INT 1Ah

            MOV AX, DX
            XOR DX, DX
            XOR CX, CX
            MOV CX, 10
            DIV CX
            CMP DL, 0
            JE istNullDH        ;Selbe wie oben
            CMP DL, 1
            JE istEins
            JMP endRandDH

istNullDH:  INC DL              ;Damit wir min. eine 1 bekommen

istEins:    INC DL              ;Damit wir min. eine 2 bekommen

endRandDH:  SHL DL, 1           ;Sowas wie Multiplikation mit 2, max Wert: 2*9 = 18, min Wert: 2*2 = 4
            MOV randomY, DL
            RET
randomDH    ENDP

printFood   PROC                ;Prozedur um an Randompositionen Futter zu erzeugen
foodStart:  CALL randomDL
            CALL randomDH
            ;CALL randomTest    ;Nur zum Test der Randomzahlen

            MOV AH, 02h
            MOV BH, 0
            MOV DL, randomX
            MOV DH, randomY
            INT 10h             ;Cursor setzen

            MOV AH, 08h
            MOV BH, 0
            INT 10h             ;Zuerst Zeichen an der Stelle lesen denn
            CMP AL, '+'         ;man muss sicherstellen, das das Futter nicht an der Stelle eines Schlangenkoerperteils spawnen kann
            JE foodStart

            MOV AH, 09h
            MOV BH, 0
            MOV AL, 0FEh        ;Zeichen: "black square"
            MOV CX, 1
            MOV BL, 00001100b   ;Farbe: Rosa (Fleischfarbe)
            INT 10h             ;Zeichen schreiben
            RET
printFood   ENDP

oldISRback  PROC                ;Prozedur zum Wiederherstellen der alten ISR1Ch
            PUSH DS
            MOV DX, oldIOFF
            MOV AX, oldISeg
            MOV DS, AX
            MOV AL, 1Ch
            MOV AH, 25h         ;Interrupt setzen
            INT 21h
            POP DS
            RET
oldISRback  ENDP

endscreen   PROC                ;Prozedur zum Abarbeiten der Sachen, die wir am Schluss brauchen
            CMP DX, OFFSET win  ;Falls der OFFSET des Zeigers der den "win"-String angibt in DX drinsteht (also man den passenden score erreicht hat)
            JE printEnd
            MOV DX, OFFSET lose ;Ansonsten wird der OFFSET des Zeigers der den "lose"-String angibt ausgewaehlt und ausgegeben

printEnd:   MOV AH, 00h
            MOV AL, 3
            INT 10h             ;Bildschirm loeschen

            MOV AH, 09h
            INT 21h
            CALL sound
            RET
endscreen   ENDP
