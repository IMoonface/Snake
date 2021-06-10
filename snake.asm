;==============================================================================
;Abschlussprogramm fuer das Modul "Assemblerprogrammierung" bei Prof. Kraemer
;Jahrgang: 18-INB2
;Titel: Snake
;Programmed by: Marc Uxa
;==============================================================================
;Ziel:
;Man muss versuchen durch das Einsammeln des Futters die Schlange zu saettigen.
;==============================================================================
;Prinzip:
;Zuerst waehlt man mit der Maus einen Schwierigkeitsgrad
;    easy (mode = 1):
;            - speed = 4
;            - man muss 30 Punkte erreichen
;            - ab 15 Punkten erhoeht sich die Geschwindigkeit
;    normal (mode = 2):
;            - speed = 3
;            - man muss 40 Punkte erreichen
;            - ab 20 Punkten erhoeht sich die Geschwindigkeit
;    hard (mode = 3):
;            - speed = 2
;            - man muss 50 Punkte erreichen
;            - ab 35 Punkten erhoeht sich die Geschwindigkeit
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
;   - eigene Interrupt Service Routine fuer ISR1Ch
;   - eigene Maus Unterroutine (AH = 0Ch)
;   - Videomodus 3 (VGA-Grafik)
;   - Soundeffekte
;==============================================================================
            .MODEL SMALL
            .386                ;Prozessortyp (Brauch ich nur fuer die IMUL DX, 160 und damit das "escape"-Label erreicht werden kann)
video_seg   = 0B800h            ;Um in den Videospeicher zu schreiben
            .DATA
;***************************** DATASEGMENT ************************************
;Schlangen-Array
snakeX      DB  5,  6,  7,  8, 50 dup(0) ;"50 Duplikate von 0", die ersten 4 Indexe haben Werte fuer die Positionen, wo die Schlange starten soll, der Rest ist 0
snakeY      DB 10, 10, 10, 10, 50 dup(0)
snakeSize   DW 3                         ;Gibt an wie lang die Schlange ist

posMaus     DW ?
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

mode        DB 0                ;Fuer den Schwierigkeitsgrad (ist auf 0, weil wir in diffLoop ja andauern vergleichen)

;Soundvariablen
loserSound  DW 5000, 7250, 8500
soundLength = $ - loserSound    ;$: Assembler Variante von .length() in java, ermittele die Laenge vom dem nach -

winnerSound DW 5000, 3250, 2000
            INCLUDE strings.asm
;*************************** CODESEGMENT ******************************
            .CODE
            INCLUDE procs.asm
            INCLUDE sound.asm
;1Ch Interrupt wird alle 18tel Sekunden ausgeloest und dient als Zeitgeber
ISR1Ch:     PUSH DS             ;Alle Register die in einer ISR benutzt werden muessen gesichert werden!!!
            PUSH AX
            MOV AX, @DATA       ;Muessen wir nochmal vorsichtshalber laden, weil wir nie wissen von wo diese Routine aufgerufen wird
            MOV DS, AX
            DEC counter         ;Runterzaehlen des counters
            POP AX
            POP DS
            IRET

begin:      MOV AX, @DATA       ;Adresse des Datensegments in das Register „AX“ laden
            MOV DS, AX          ;In DS uebertragen
                                ;(das DS-Register kann nicht direkt mit einer Konstante beschrieben werden)
            MOV AL, 1Ch
            MOV AH, 35h
            INT 21h             ;Interrupt 21h mit AH auf 35h: Interrupt-Vektor ermitteln ((AL)	Interrupt Nummer)
                                ;In ES:BX ist jetzt die alte ISR Adresse und wir sichern diese
            MOV oldIOFF, BX
            MOV oldISeg, ES
                                ;Wir muessen der DOS Routine die neue Adresse der ISR in DS:DX uebergeben
            PUSH DS             ;Wir sichern dazu erstmal DS
            PUSH CS             ;Unsere ISR steht ihm CodeSegment. Die CodeSegment-Adresse steht in CS, diese sichern wir ebenfalls
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

            CALL printLogo      ;Aufruf der Prozedur um "Logo" zu printen
            CALL difficulty

            MOV AH, 01h
            MOV CX, 2607h       ;CX=2607h heißt unsichtbarer Cursor
            INT 10h             ;Cursorform einstellen

            CALL printFrame     ;Aufruf der Prozedur zum Zeichnen des Rahmens
            CALL printScore     ;Aufruf der Prozedur um "Score" zu printen
            CALL printSnake     ;Aufruf der Prozedur zum Zeichnen der Schlange
            CALL deleteTail     ;Aufruf der Prozedur um den Schwanz der Schlange zu loeschen
            CALL randomDL       ;Aufruf der Prozedur um eine Randomzahl fuer DL zu erzeugen
            CALL randomDH       ;Aufruf der Prozedur um eine Randomzahl fuer DL zu erzeugen
            CALL printFood      ;Aufruf der Prozedur um an Randompositionen Futter zu erzeugen

waitForKey: MOV AH, 0Ch
            MOV AL, 0
            INT 21h             ;Tastaturbuffer leeren, damit sich schnelle Eingaben nicht stappeln (aus dem Ulbricht Video)

            XOR BX, BX
            MOV BX, speed
            MOV counter, BX

waitLoop:   CMP counter, 0
            JNE waitLoop        ;Warten bis der Interrupt den counter runtergezaehlt hat

            MOV AH, 01h         ;ZF = 1: kein wartendes Zeichen. ZF = 0: ein Zeichen steht zur Abholung bereit.
            INT 16h             ;Keyboard Status ohne Abholung des Zeichens (von Ihnen)
            JZ nobutton         ;JMP if ZF gesetzt (ZF = 1).

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
            JMP nobutton        ;Falls kein Button gedrueckt wurde...

noButton:   CMP movflag, 1
            JE moveUP           ;...wird ueberprueft welche movflag derzeit aktiv ist und der letzte zutreffende Fall wird wiederholt
            CMP movflag, 2
            JE moveDown
            CMP movflag, 3
            JE moveLeft
            CMP movflag, 4
            JE moveRight

moveUp:     CMP movflag, 2      ;Um zu verhindern, dass man direkt nach down nicht wieder up machen kann
            JE noButton         ;JMP Equal zu noButton (ist dann so als haette man keinen Button gedrueckt)
            XOR BX, BX
            MOV BH, -1          ;Kleiner Fix, weil ansonsten das neue Element im Schlangen Array an die Stelle
                                ;der derzeitigen Position geschrieben werden wuerde und man so nochmal warten muesste
                                ;bis sich die Schlange "aktualisiert" (Siehe Erklaerung)
            MOV movflag, 1      ;movflag gibt die zuletzt gegangene Richtung an hier "hoch"
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
;CALLs die am Ende (egal ob gedrueckter Button oder nicht) gebraucht werden ausgelaggert in ein Label
calls:      CALL collision      ;Prozedur um zu gucken ob sich die Schlange selber frisst oder der Rahmen berueht wurde
            CALL printSnake
            CALL deleteTail
            JMP waitForKey      ;Zurueck zur Endlosschleife

ende:       CALL endscreen      ;Aufruf der Prozedur zum Abarbeiten der Sachen die ich am Schluss brauche
            CALL oldISRback     ;Aufruf der Prozedur zum Widerherstellen der alten ISR
            MOV AH, 4Ch
            INT 21h             ;Zurueck zu DOS
            .STACK 100h         ;Wo wir auf den Stack starten wollen
            end begin
