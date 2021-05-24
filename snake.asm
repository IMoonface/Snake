;==============================================================================
;Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Krämer
;Jahrgang: 18-INB2
;Titel: Snake
;Programmed by: Marc Uxa
;==============================================================================
;Ziel:
;Man muss versuchen durch das Einsammeln des Futters die Schlange zu sättigen.
;==============================================================================
;Prinzip:
;Zuerst waehlt man einen Schwierigkeitsgrad
;    easy (mode = 1):
;            - speed = 4
;            - man muss 30 Punkte erreichen
;    normal (mode = 2):
;            - speed = 3
;            - man muss 45 Punkte erreichen
;    normal (mode = 2):
;            - speed = 2
;            - man muss 60 Punkte erreichen
;
;Mit WASD kann man dann die Schlange steuern.
;Wenn man das Futter einsammelt verlaengert sich die Schlange.
;Die Schlange darf weder sich noch den Rand fressen. Viel Spass!
;==============================================================================
;Unterprogramme:
;   - Ausgelaggert in procs.asm
;   - moveUp
;   - moveDown
;   - moveLeft
;   - moveRight
;
;Besonderheiten:
;   - eigene Interrupt Service Routine für 1Ch
;==============================================================================
            .MODEL SMALL
            .486              ;Prozessortyp
video_seg   = 0B800h          ;Adresse der VGA Grafikkarte fuer den Textmodus
            .DATA
;***************************** DATASEGMENT ************************************
;Schlangen-Array
snakeX      DB  5,  6,  7,  8, 60 dup(0) ;"60 Duplikate von 0", die ersten 4 Indexe haben Werte fuer die Positionen, wo die Schlange starten soll, der Rest ist 0
snakeY      DB 10, 10, 10, 10, 60 dup(0)
snakeSize   DW 3                         ;Gibt an wie lang die Schlange ist

;Scorevariablen
score       DB 0
divrest     DB ?

;Bewegungsvariable
movflag     DB 4                ;Standartmaessig bewegt sich die Schlange nach rechts
speed       DW ?                ;Muss WORD sein, weil wir es in BX schreiben wollen

;Futtervariablen
randomX     DB ?                ;? heißt nicht initialisiert
randomY     DB ?

oldIOFF     DW ?
oldISeg     DW ?
counter     DW ?

mode        DB ?                ;Fuer den Schwierigkeitsgrad
            INCLUDE strings.asm
;*************************** CODESEGMENT ******************************
            .CODE
            INCLUDE procs.asm
;1Ch Interrupt wird alle 18tel Sekunden ausgeloest und dient als Zeitgeber
ISR1Ch:     PUSH DS             ;Alle Register die in einer ISR benutzt werden muessen gesichert werden!!!
            PUSH AX
            MOV AX, @DATA       ;Muessen wir nochmal vorsichtshalber laden, weil wir nie wissen von wo diese Routine aufgerufen wird
            MOV DS, AX
            DEC counter         ;Runterzaehlen des counters
            POP AX
            POP DS
            IRET

beginn:     MOV AX, @DATA       ;Adresse des Datensegments in das Register „AX“ laden
            MOV DS, AX          ;In das Segmentregister „DS“ uebertragen
                                ;(das DS-Register kann nicht direkt mit einer Konstante beschrieben werden)
            MOV AL, 1Ch
            MOV AH, 35h
            INT 21h             ;Interrupt 21h mit AH auf 35h: Interrupt-Vektor ermitteln ((AL)	Interrupt Nummer)
                                ;Diese Funktion liefert als Resultat den aktuellen Inhalt eines Interrupt-Vektors
                                ;und damit die Adresse der zugehoerigen Interrupt-Routine zurueck
            MOV oldIOFF, BX
            MOV oldISeg, ES     ;In ES:BX ist jetzt die alte ISR Adresse und wir sichern diese
                                ;Wir muessen der DOS Routine die neue Adresse der ISR in DS:DX uebergeben
            PUSH DS             ;Wir sichern dazu erstmal DS

                                ;Unsere ISR steht ihm CodeSegment. Die CodeSegment-Adresse steht in CS, diese sichern wir ebenfalls
            PUSH CS             ;Die CodeSegment-Adresse steht in CS, diese sichern wir ebenfalls
            POP DS              ;DS <- CS
            MOV DX, OFFSET ISR1Ch ;Adresse ist jetzt in DS:DX
            MOV AL, 1Ch
            MOV AH, 25h
            INT 21h             ;Interrupt 21h mit AH auf 25h: Interrupt-Vektor setzen ((AL) Interrupt Nummer)
                                ;Damit setzen wir jetzt unsere eigens definierte ISR1Ch
            POP DS              ;Datensegment, dahin wo es hingehoert

            MOV AH, 00h
            MOV AL, 3           ;Videomodus3 -> 640x200 Pixel mit 16 Farben (in 80x25 Bloecken)
            INT 10h             ;Zeichenbildschirm einstellen

            CALL printLogo
            CALL difficulty

            MOV AH, 01h
            MOV CX, 2607h       ;CX=2607h heißt unsichtbarer Cursor
            INT 10h             ;Cursorform einstellen

            CALL printFrame     ;Aufruf der Prozedur zum Zeichnen des Rahmens
            CALL printScore     ;Aufruf der Prozedur um "Score" zu printen
            CALL printSnake     ;Aufruf der Prozedur zum Zeichnen der Schlange
            CALL deleteTail     ;Aufruf der Prozedur um den Schwanz der Schlange zu loeschen
            CALL randomDL       ;Aufruf der Prozedur um eine Randomzahl für DL zu erzeugen
            CALL randomDH       ;Aufruf der Prozedur um eine Randomzahl für DL zu erzeugen
            CALL printFood      ;Aufruf der Prozedur um an Randompositionen Futter zu erzeugen

waitForKey: MOV AH, 0Ch
            MOV AL, 0
            INT 21h             ;Tastaturbuffer leeren, damit sich schnelle Eingaben nicht stappeln (aus dem Ulbricht Video)

            XOR BX, BX
            MOV BX, speed
            MOV counter, bx

waitLoop:   CMP counter, 0
            JNE waitLoop        ;Warten bis der Interrupt den counter runtergezaehlt hat

            MOV AH, 01h         ;ZF = 1: kein wartendes Zeichen. ZF = 0: ein Zeichen steht zur Abholung bereit.
            INT 16h             ;Keyboard Status ohne Abholung des Zeichens (von Ihnen) ;
            JZ nobutton         ;JMP if ZF gesetzt (ZF = 1).

            MOV AH, 00h
            INT 16h             ;Liest das letzte Zeichen aus den Tastaturbuffer aus und speichert es in AL

            CMP AL, 77h         ;W
            JE up
            CMP AL, 73h         ;S
            JE down
            CMP AL, 61h         ;A
            JE left
            CMP AL, 64h         ;D
            JE right
            CMP AL, 1Bh         ;ESC
            JE escape
            JNE nobutton        ;Falls kein Button gedrueckt wurde...

noButton:   CMP movflag, 1
            JE up               ;...wird ueberprueft welche movflag derzeit aktiv ist und der letzte zutreffende Fall wird wiederholt
            CMP movflag, 2
            JE down
            CMP movflag, 3
            JE left
            CMP movflag, 4
            JE right

up:         CMP movflag, 2      ;Um zu verhindern, dass man direkt nach down nicht wieder up machen kann
            JE noButton         ;JMP Equal zu noButton (ist dann so als haette man keinen Button gedrueckt)
            XOR BX, BX
            MOV BH, -1          ;Kleiner Fix, weil ansonsten das neue Element im Schlangen Array an die Stelle
                                ;der derzeitigen Position geschrieben werden wuerde und man so nochmal warten muesste
                                ;bis sich die Schlange "aktualisiert" (Siehe Erklaerung)
            CALL moveUp
            JMP calls

down:       CMP movflag, 1      ;Um zu verhindern, dass man direkt nach up nicht wieder down machen kann
            JE noButton
            XOR BX, BX
            MOV BH, 1
            CALL moveDown
            JMP calls

left:       CMP movflag, 4      ;Um zu verhindern, dass man direkt nach right nicht wieder left machen kann
            JE noButton
            XOR BX, BX
            MOV BL, -1
            CALL moveLeft
            JMP calls

right:      CMP movflag, 3      ;Um zu verhindern, dass man direkt nach left nicht wieder right machen kann
            JE noButton
            XOR BX, BX
            MOV BL, 1
            CALL moveRight
            JMP calls

moveUp      PROC                ;Musste ich als Prozedur machen, weil es irgendwann zu weit weg war um es mit JE zu erreichen
            MOV movflag, 1
            CALL checkFood      ;Aufruf der Prozedur um zu sehen ob der Kopf der Schlange mit der Position des Futters uebereinstimmt
            CALL resetSnake
            DEC snakeY[DI]
            CMP snakeY[DI], 0   ;Gucken ob die Grenzen getroffen wurden
            JE ende             ;Falls die Grenzen getroffen wurde -> Endroutine
            RET
moveUp      ENDP

moveDown    PROC
            MOV movflag, 2
            CALL checkFood
            CALL resetSnake
            INC snakeY[DI]
            CMP snakeY[DI], 22
            JE ende
            RET
moveDown    ENDP

moveLeft    PROC
            MOV movflag, 3
            CALL checkFood
            CALL resetSnake
            DEC snakeX[DI]
            CMP snakeX[DI], 0
            JE ende
            RET
moveLeft    ENDP

moveRight   PROC
            MOV movflag, 4
            CALL checkFood
            CALL resetSnake
            INC snakeX[DI]
            CMP snakeX[DI], 79
            JE ende
            RET
moveRight   ENDP

escape:     MOV AH, 00h
            MOV AL, 3
            INT 10h             ;Bildschirm Loeschen

            MOV AH, 4Ch
            INT 21h             ;Zurueck zu DOS
;CALLs die am Ende (egal ob gedrueckter Button oder nicht) gebraucht werden ausgelaggert in ein Label
calls:      CALL collision
            CALL printSnake
            CALL deleteTail
            JMP waitForKey      ;Zurueck zur Endlosschleife

ende:       CALL endscreen
            MOV AH, 4Ch
            INT 21h             ;Zurueck zu DOS
            .STACK 100h         ;Wo wir auf den Stack starten wollen
            end beginn
