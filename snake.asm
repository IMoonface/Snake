;==============================================================================
;Abschlussprojekt fuer das Modul "Assemblerprogrammierung" bei Prof. Kraemer
;Titel: Snake
;Programmiert von: Marc Uxa (71922) & Benjamin Huber (73964)
;Zum Kompilieren: tasm snake.asm & tlink snake.obj
;Zum Ausfuehren: snake
;Getestet in: DOSBox 0.74-3
;==============================================================================
            .MODEL SMALL
            .386
video_seg   = 0B800h
            .DATA
;***************************** DATASEGMENT ************************************
snakeX      DB  5,  6,  7,  8, 50 dup(0) ;"50 Duplikate von 0"
snakeY      DB 10, 10, 10, 10, 50 dup(0)
snakeSize   DW 3                ;Gibt an wie lang die Schlange ist
posMaus     DW ?
score       DB 0
divrest     DB ?
movflag     DB 4                ;Standartmaessig bewegt sich die Schlange nach rechts
speed       DW ?
randomX     DB ?
randomY     DB ?
oldIOFF     DW ?
oldISeg     DW ?
counter     DW ?
mode        DB 0
loserSound  DW 5000, 7250, 8500
soundLength = $ - loserSound
winnerSound DW 5000, 3250, 2000
            INCLUDE strings.asm
;*************************** CODESEGMENT ******************************
            .CODE
            INCLUDE procs.asm
            INCLUDE sound.asm
            INCLUDE tests.asm

;1Ch Interrupt wird alle 18tel Sekunden ausgeloest und dient als Zeitgeber
ISR1Ch:     PUSH DS
            PUSH AX
            MOV AX, @DATA       ;Muessen wir nochmal vorsichtshalber laden, weil wir nie wissen von wo diese Routine aufgerufen wird
            MOV DS, AX
            DEC counter
            POP AX
            POP DS
            IRET

begin:      MOV AX, @DATA
            MOV DS, AX
            MOV AL, 1Ch
            MOV AH, 35h
            INT 21h             ;Interrupt 21h mit AH auf 35h: Interrupt-Vektor ermitteln ((AL)	Interrupt Nummer)
                                ;In ES:BX ist jetzt die alte ISR Adresse und wir sichern diese
            MOV oldIOFF, BX
            MOV oldISeg, ES
                                ;Wir muessen der DOS Routine die neue Adresse der ISR in DS:DX uebergeben
            PUSH DS
            PUSH CS
            POP DS              ;DS <- CS
            MOV DX, OFFSET ISR1Ch
            MOV AL, 1Ch
            MOV AH, 25h
            INT 21h             ;Interrupt 21h mit AH auf 25h: Interrupt-Vektor setzen ((AL) Interrupt Nummer)
                                ;Damit setzen wir unsere eigens definierte ISR1Ch
            POP DS

            MOV AH, 00h
            MOV AL, 3           ;Videomodus3 -> 640x200 Pixel mit 16 Farben (in 80x25 Bloecken)
            INT 10h             ;Zeichenbildschirm einstellen

            CALL printLogo      ;Aufruf der Prozedur zum Printen des Logos
            CALL difficulty     ;Aufruf der Prozedur um den Schwierigkeitsgrad zu ermitteln

            MOV AH, 01h
            MOV CX, 2607h       ;CX=2607h heißt unsichtbarer Cursor
            INT 10h             ;Cursorform einstellen

            CALL printScore     ;Aufruf der Prozedur um "Score" zu printen
            CALL printFrame     ;Aufruf der Prozedur zum Zeichnen des Rahmens
            CALL printSnake     ;Aufruf der Prozedur um die Schlange zu printen
            CALL deleteTail     ;Aufruf der Prozedur um den Schwanz der Schlange zu loeschen
            CALL randomDL       ;Aufruf der Prozedur um eine Randomzahl fuer DL zu erzeugen
            CALL randomDH       ;Aufruf der Prozedur um eine Randomzahl fuer DH zu erzeugen
            CALL printFood      ;Aufruf der Prozedur um an Randompositionen Futter zu erzeugen

waitForKey: MOV AH, 0Ch
            MOV AL, 0
            INT 21h             ;Tastaturbuffer leeren, damit sich schnelle Eingaben nicht stappeln

            XOR BX, BX
            MOV BX, speed
            MOV counter, BX

waitLoop:   CMP counter, 0
            JNE waitLoop

            MOV AH, 01h         ;ZF = 1: kein wartendes Zeichen. ZF = 0: ein Zeichen steht zur Abholung bereit.
            INT 16h             ;Keyboard Status ohne Abholung des Zeichens
            JZ nobutton         ;JMP if ZF gesetzt (ZF = 1)

            MOV AH, 00h
            INT 16h             ;Liest das letzte Zeichen aus den Tastaturbuffer aus und speichert es in AL

            CMP AL, 77h         ;W
            JE moveUp
            CMP AL, 73h         ;S
            JE moveDown
            CMP AL, 61h         ;A
            JE moveLeft
            CMP AL, 64h         ;D
            JE moveRight
            CMP AL, 1Bh         ;ESC
            JE escape
            JMP nobutton        ;Falls kein Button gedrueckt wurde

;Guckt welcher Move zuletzt gemacht wurde und wiederholt diesen
noButton:   CMP movflag, 1
            JE moveUp
            CMP movflag, 2
            JE moveDown
            CMP movflag, 3
            JE moveLeft
            CMP movflag, 4
            JE moveRight

moveUp:     CMP movflag, 2      ;Um zu verhindern, dass man direkt nach down nicht wieder up machen kann
            JE noButton
            XOR BX, BX
            MOV BH, -1          ;Kleiner Fix, weil ansonsten das neue Element im Schlangen Array an die Stelle
                                ;der derzeitigen Position geschrieben werden wuerde und man so nochmal warten muesste
                                ;bis sich die Schlange "aktualisiert" (Siehe Erklaerung)
            MOV movflag, 1
            CALL checkFood      ;Aufruf der Prozedur um zu sehen ob der Kopf der Schlange mit der Position des Futters uebereinstimmt
            CALL resetSnake     ;Aufruf der Prozedur um den body der Schlange anzupassen
            DEC snakeY[DI]      ;(Siehe Erklaerung)
            JMP calls

moveDown:   CMP movflag, 1      ;Um zu verhindern, dass man direkt nach up nicht wieder down machen kann
            JE noButton
            XOR BX, BX
            MOV BH, 1
            MOV movflag, 2
            CALL checkFood
            CALL resetSnake
            INC snakeY[DI]
            JMP calls

moveLeft:   CMP movflag, 4      ;Um zu verhindern, dass man direkt nach right nicht wieder left machen kann
            JE noButton
            XOR BX, BX
            MOV BL, -1
            MOV movflag, 3
            CALL checkFood
            CALL resetSnake
            DEC snakeX[DI]
            JMP calls

moveRight:  CMP movflag, 3      ;Um zu verhindern, dass man direkt nach left nicht wieder right machen kann
            JE noButton
            XOR BX, BX
            MOV BL, 1
            MOV movflag, 4
            CALL checkFood
            CALL resetSnake
            INC snakeX[DI]
            JMP calls

escape:     CALL oldISRback     ;Aufruf der Prozedur zum Widerherstellen der alten ISR1Ch
            MOV AH, 00h
            MOV AL, 3
            INT 10h             ;Bildschirm Loeschen
            MOV AH, 4Ch
            INT 21h             ;Zurueck zu DOS

calls:      CALL collision      ;Aufruf der Prozedur um zu testen ob sich die Schlange selber frisst oder der Rahmen berueht wurde
            CALL printSnake
            CALL deleteTail
            JMP waitForKey

ende:       CALL endscreen      ;Aufruf der Prozedur zum Abarbeiten der Sachen, die wir am Schluss brauchen
            CALL oldISRback
            MOV AH, 4Ch
            INT 21h             ;Zurueck zu DOS
            .STACK 100h
            end begin
