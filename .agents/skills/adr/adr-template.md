# ADR-{{NUMMER}}: {{TITEL}}

- **Datum:** {{YYYY-MM-DD}}
- **Status:** Proposed <!-- Proposed | Accepted | Deprecated | Superseded by ADR-NNNN -->
- **Entscheidung von:** {{Rollen/Personen, die im Review zustimmen}}
- **Bezug:** {{Spezifikation, Ticket, Klärungsdokument; bei Ablösung: „Ersetzt ADR-XXXX“}}

## Kontext

{{Faktenlage: Was ist heute da (mit Pfaden)? Welche Anforderung erzwingt die Entscheidung? Welche
Architekturregeln gelten (Tests, Modulgrenzen)? Was ist ausdrücklich nicht Gegenstand?}}

**Frage:** {{Die Entscheidung als eine Frage formuliert.}}

## Entscheidungstreiber

1. {{Treiber 1}}
2. {{Treiber 2}}
3. {{Treiber 3}}

## Optionen

### Option A – {{Name}}

{{Beschreibung in 2–4 Sätzen.}}

- **Gewinnt:** {{…}}
- **Kostet:** {{…}}
- **Risiken – was bricht?** {{…}}

### Option B – {{Name}}

- **Gewinnt:** {{…}}
- **Kostet:** {{…}}
- **Risiken – was bricht?** {{…}}

### Option C – Nichts tun / minimal: {{Name}}

- **Gewinnt:** {{…}}
- **Kostet:** {{…}}
- **Risiken – was bricht?** {{…}}

### Vergleich

| Treiber | A | B | C |
|---|---|---|---|
| {{Treiber 1}} | {{+ / o / −, kurz begründet}} | | |
| {{Treiber 2}} | | | |

## Entscheidung

{{„Wir wählen Option X: …“ – in 1–3 Sätzen, so formuliert, dass man im Code prüfen kann, ob sie
eingehalten wird.}}

### Begründung

{{Bezug auf Treiber und Risiken. Warum nicht die zweitbeste Option?}}

## Konsequenzen

**Positiv**
- {{…}}

**Negativ**
- {{…}}

**Folgearbeiten**
- {{…}}

## Überprüfung

- {{Test/Regel/Befehl, der zeigt, dass der Code der Entscheidung folgt}}
- **Wiedervorlage, wenn:** {{Auslöser, bei dem die Entscheidung neu geprüft wird}}

## Verweise

- {{Spezifikation, verwandte ADRs, Diagramme}}
