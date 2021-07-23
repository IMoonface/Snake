sound       PROC                            ;Prozedur um einen Sound entsprechend der Situation zu spielen
            MOV DI, 0
            MOV CX, soundLength             ;Hat Jetzt die Laenge des Arrays, also 2*eintraege = 6
            CMP DX, OFFSET win              ;Falls gewonnen
            JE winnerloop
            CMP DX, OFFSET lose             ;Falls verloren
            JE loserloop
            JMP noFinish                    ;Ansonsten noch nicht fertig

winnerLoop: MOV AX, winnerSound[di]         ;Naechster Eintrag des "winner"-Arrays in AX holen
            CALL soundLoop
            CMP CX, 0                       ;Sobald die Laenge 0 ist wurde der Sound komplett abgespielt
            JNE winnerloop
            JMP endSound

loserLoop:  MOV AX, loserSound[di]          ;Naechster Eintrag des "loserSound"-Arrays in AX holen
            CALL soundLoop
            CMP CX, 0                       ;Sobald die Laenge 0 ist wurde der Sound komplett abgespielt
            JNE loserloop
            JMP endSound

noFinish:   MOV AX, 4000
            MOV CX, 1                       ;dummer fixm, für doe
            CALL soundLoop
endSound:   RET
sound       ENDP

wait4Note   PROC                            ;Prozedur um zu warten bis eine Note abgespielt wurde
            CMP CX, 1                       ;dummer fix
            JE shortNote
            CMP CX, 2                       ;Sobald die Laenge 2 ist
            JE longerNote
            MOV counter, 5
            JMP noteLoop

shortNote:  MOV counter, 1
            JMP noteLoop

longerNote: MOV counter, 8                  ;Die letzte Note bisschen laenger abgespielt

noteLoop:   CMP counter, 0
            JNE noteLoop
            RET
wait4Note   ENDP

soundLoop   PROC                            ;Prozedur um den Lautsprecher Ein- bzw. Auszuschalten
            ;(Port 42h) ist mit dem Lautsprecher des Computers verbunden und gibt Rechteckimpulse aus, die zur Erzeugung von Tönen verwendet werden
            OUT 42h, AL
            MOV AL, AH
            OUT 42h, AL                     ;Highbyte und Lowbyte jeweils nach Port 42h

            ;Lautsprechen einschalten
            IN AL, 61h                      ;Lese ein Byte aus dem Port. Port 61h kontrolliert den Lautsprecher
                                            ;Zur Erzeugung eines Tones müssen die Bits 0 und 1 auf Eins gesetzt werden
            OR AL, 00000011b                ;= 00000011b
            OUT 61h, AL                     ;Schickt die Bits an den Port

            ADD DI, 2                       ;Um einen Eintrag weiterzugehen
            CALL wait4Note

            ;Lautsprecher ausschalten
            IN AL, 61h                      ;Selbe wie oben
            AND AL, 11111100b               ;Soll der Summer ausgeschaltet werden müssen die Bits 0 und 1 auf Null gesetzt werden.
            OUT 61h, AL                     ;Selbe wie oben

            SUB CX, 2                       ;um die Lange des Arrays anzupassen
            RET
soundLoop   ENDP
