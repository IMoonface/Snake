;========================================================================
; Ziel der Übung ist es, ein Unterprogramm zu schreiben, welches bei
; bestimmten Aktionen mit der Maus aufgerufen wird. Hierzu kann in der
; Maus-Interrupt-Service-Routine (ISR) eine Prozedur eingetragen werden,
; die bei vorgegebenen Bedingungen aufgerufen wird (kein Interrupt).
;
; Schreiben Sie ein Programm, das, beim Drücken der linken Maustaste, an
; der Stelle des Cursors die Koordinaten in Pixeln ausgibt. Das Programm
; durch Eingabe von <esc> abgebrochen werden (s. vorherige Übungen).
;
;========================================================================
; Prinzip:
; Siehe Uebungsblatt 3

;************************************************************************
; Hauptprogramm
;  -> keine Unterprogramme (extern)
;************************************************************************
            .model small
            .486
esc_code    = 1Bh
video_seg   = 0B800h
            .data
            .code
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
            mov ax, 2           ;bevor wir auf den Bildschirm schreiben müssen wir den cursor ausschalten
            mov di, cx
            int 33h
            ;da der Assembler nicht weiß, ob es sich um ein Byte oder Word handelt müssen wir es ihm sagen
            ;0FDBh = Block zeichnen
            mov WORD PTR es:[di], 1h   ;das was wir auf den bildschirm schreiben
            mov ax, 1           ;Cursor wieder ein
            int 33h
            pop di
            pop ds
            leave
            ret
mausProc    ENDP

Beginn:     mov ax, 3
            int 10h             ;Zeichenbildschirm einstellen
            mov cx, 1111110b    ;wir reagieren jetzt auf alle tastenoptionen der maus
            push cs
            pop es
            mov dx, OFFSET mausProc ;wir laden die Adresse von mausProc
            mov ax, 0Ch
            int 33h             ;Maus Interrupt
            mov ax, 1           ;Cursor anschalten
            int 33h             ;nochmal Interrupt
endloop:    xor ah, ah

            ;mauscursor verschieben

            MOV AH, 08h         ;Lese Zeichen und Attribut an der Cursorposition.
                                ;-> AH = 08h, BH = page number, AH = Farbwert, AL = Zeichen
            MOV BH, 0h
            INT 10h

            cmp al, 1h
            je ende
            int 16h             ; Tastaturabfrage
            cmp al, esc_code    ;falls escape
            je short ende
            jmp short endloop

ende:       mov ax, 0           ;Reset Maus
            int 33h
            mov ax, 3
            int 10h             ;Zeichenbildschirm löschen
            mov ah, 4Ch
            int 21h             ;Zurück zu DOS
            .stack 100h
            end Beginn
