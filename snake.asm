;==============================================================================
; Ziel:
; Man muss versuchen durch das Einsammeln des Futters die Schlange zu sättigen.
; Bei 50 Punkten gewinnt man.
;==============================================================================
; Prinzip:
; Mit WASD kann man die Schlange steuern. Sobald man das Futter einsammelt
; verlängert sich die Schlange und wird nach einer gewissen Groeße schneller.
;==============================================================================
; Unterprogramme:
; Ausgelaggert in procs.asm
;==============================================================================
            .MODEL SMALL
            .486              ;Prozessortyp
video_seg   = 0B800h          ;Adresse der VGA Grafikkarte fuer den Textmodus
            .DATA
;***************************** DATASEGMENT ************************************
;Schlangen-Array
snakeX      DB  5,  6,  7,  8, 60 dup(0) ;"50 duplicates of zero", die ersten 4 indexe haben werte für die positionen,
                                          ;wo die schlange starten soll, der rest ist 0
snakeY      DB 10, 10, 10, 10, 60 dup(0) ;50 weil man bei 50 punkten gewinnt
snakeSize   DW 3                          ;gibt an wie lang die schlange ist

;Scorevariablen
score       DB 0
divrest     DB 0

;Bewegungsvariable
movflag     DB 4                ;standartmässig bewegt sich die schlange nach rechts
speed       DW ?                ;muss WORD sein, weil wir es in BX schreiben wollen

;Futtervariablen
randomX     DB ?
randomY     DB ?

oldIOFF     DW ?                ;? heißt nicht initialisiert
oldISeg     DW ?
counter     DW ?

mode        DB ?                ;Schwierigkeitsgrad
            INCLUDE strings.asm
;*************************** CODESEGMENT ******************************
            .CODE
            INCLUDE procs.asm
;1Ch Interrupt wird alle 18tel Sekunden ausgelöst und dient als Zeitgeber
ISR1Ch:     PUSH DS             ;alle Register die in einer ISR benutzt werden müssen gesichert werden!!!
            PUSH AX
            MOV AX, @data       ;müssen wir nochmal vorsichtshalber laden, weil wir nie wissen von wo dieser Routine aufgerufen wird
            MOV DS, AX
            DEC counter         ;runterzählen des counters
            POP AX              ;und am Ende zurücksichern nicht vergessen!
            POP DS
            iret

start:      MOV AX, @DATA       ;Adresse des Datensegments in das Register „AX“ laden
            MOV DS, AX          ;In das Segmentregister „DS“ uebertragen
                                ;(das DS-Register kann nicht direkt mit einer Konstante beschrieben werden)
            MOV AL, 1Ch
            MOV AH, 35h
            INT 21h             ;Interrupt 21h mit ah auf 35h: Interrupt-Vektor ermitteln ((AL)	Interrupt Nummer)
                                ;Diese Funktion liefert als Resultat den aktuellen Inhalt eines Interrupt-Vektors
                                ;und damit die Adresse der zugehörigen Interrupt-Routine zurück
            MOV oldIOFF, bx
            MOV oldISeg, es     ;in es:bx ist jetzt die alte ISR Adresse und wir sichern diese
            PUSH DS             ;wir müssen der DOS Routine die neue adresse der ISR in DS:DX übergeben
                                ;wir sichern dazu erstmal ds

            PUSH CS             ;unsere Interrupt service Routine steht ihm CodeSegment
                                ;die CodeSegment-Adresse steht in CS, diese sichern wir ebenfalls
            POP DS              ;DS <- CS
            MOV DX, OFFSET ISR1Ch ;Adresse ist jetzt in DS:DX
            MOV AL, 1Ch
            MOV AH, 25h
            INT 21h             ;Interrupt 21h mit ah auf 25h: Interrupt-Vektor setzen ((AL) Interrupt Nummer)
                                ;damit setzen wir jetzt unsere eigens definierte ISR1Ch
            POP DS              ;Datensegment, dahin wo es hingehört

            MOV AH, 00h
            MOV AL, 3h
            INT 10h             ;Wechsle in Videomodus 3

            CALL printLogo
            CALL difficulty

            MOV AH, 01h         ;Cursorform einstellen
            MOV CX, 2607h       ;CX=2607h heißt unsichtbarer Cursor
            INT 10h

            CALL printFrame     ;Aufruf der Prozedur zum Zeichnen des Rahmens
            CALL printScore     ;Aufruf der Prozedur um "Score" zu printen
            CALL printSnake     ;Aufruf der Prozedur zum Zeichnen der Schlange
            CALL deleteTail     ;Aufruf der Prozedur um den Schwanz der Schlange zu loeschen
            CALL randomDL       ;Aufruf der Prozedur um eine Randomzahl für DL zu erzeugen
            CALL randomDH       ;Aufruf der Prozedur um eine Randomzahl für DL zu erzeugen
            CALL printFutter    ;Aufruf der Prozedur um an Randompositionen Futter zu erzeugen

warte:      MOV AH, 0Ch         ;Tastaturbuffer leeren, damit sich schnelle Eingaben nicht stappeln (aus dem Ulbricht Video)
            MOV AL, 0h          ;rueckgabe wert nichts
            INT 21h

            XOR BX, BX
            MOV BX, speed
            MOV counter, bx

warteLoop:  CMP counter, 0
            JNE warteLoop       ;warten bis der Interrupt counter runtergezählt hat

            MOV AH, 01h         ;Keyboard Status ohne Abholung des Zeichens (von Ihnen)
            INT 16h             ;ZF = 1: kein wartendes Zeichen. ZF = 0: ein zeichen steht zur abholung bereit.
            JZ nobutton         ;JMP if ZF gesetzt (ZF = 1).

compare:    MOV AH, 00h         ;Liest das letzte Zeichen aus den Tastaturbuffer aus und speichert es in AL
            INT 16h

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
            JNE nobutton        ;Falls kein Button gedrueckt wurde

;Ueberspringt die INC bzw. DEC der snakeX oder snakeY Arrays
noButton:   CMP movflag, 1
            JE up               ;wird ueberprueft welche movflag derzeit aktiv ist und der letzte zutreffende Fall wird wiederholt
            CMP movflag, 2
            JE down
            CMP movflag, 3
            JE left
            CMP movflag, 4
            JE right

up:         CMP movflag, 2      ;Um zu verhindern, dass man direkt nach down nicht wieder up machen kann
            JE noButton
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
            JE noButton         ;JMP Equal zu noButton (ist dann so als hätte man keinen Button gedrückt)
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

moveUp      PROC                ;Musste ich als Prozedur machen, weil es irgendwann zu weit weg war
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
            MOV AL, 3h
            INT 10h             ;Bildschirm Loeschen
            MOV AH, 4Ch         ;Zurueck zu DOS
            INT 21h
calls:                          ;CALLs die am Ende (egal ob gedrueckter Button oder nicht) gebraucht werden ausgelaggert in ein Label
            CALL collision
            CALL printSnake
            CALL deleteTail
            cmp score, 100      ;weil es ansonsten irgendwann die Zero Flag setzt
            JMP warte           ;Zurueck zur Endlosschleife

ende:       CALL endscreen
            MOV AH, 4Ch         ;Zurueck zu DOS
            INT 21h
            .STACK 100h
            end start
