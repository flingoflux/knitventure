---
name: adr
description: Hält eine Architekturentscheidung als ADR im Repository fest (docs/adr/NNNN-slug.md, Status Proposed) – mit breit gedachten Optionen (mindestens drei, inklusive „nichts tun/minimal“), Risiken, Trade-offs, begründeter Entscheidung und Konsequenzen. Nutzen, wenn vor oder während einer Umsetzung eine strukturprägende Entscheidung ansteht („wo lebt X?“, „neues Modul oder bestehendes erweitern?“) oder eine bestehende ADR abgelöst werden soll. Nicht für fachliche Regeln – die gehören in die Spezifikation.
---

# ADR schreiben

Eine Architecture Decision Record (nach Michael Nygard) erklärt, **warum** etwas so entschieden wurde –
Kontext, Optionen, Abwägung. Sie beschreibt nicht, **wie** der Code im Detail aussieht. Ihr Nutzen:
Die Diskussion wird einmal geführt und dann nachgelesen, statt wiederholt. Ein Agent, der die ADR
liest, überschreibt die Entscheidung nicht versehentlich.

Ablage ist **das Repository** (`docs/adr/`), damit die ADR mit dem Code versioniert und im Review
gelesen wird.

## Eingaben

- Die Frage, die entschieden werden soll – in einem Satz. Ist sie unklar oder sind es mehrere
  Fragen, erst nachfragen bzw. aufteilen: **eine Entscheidung pro ADR**.
- Optional: Spezifikation (`specs/…`), Klärungsdokument, bestehende ADRs, Vorgaben des Nutzers
  („wir wollen Option B“).

## Ablauf

1. **Frage schärfen.** Formuliere die Entscheidung als Frage („Wo wird X fachlich verankert?“).
   Lass sie bestätigen, wenn sie nicht offensichtlich aus dem Auftrag folgt.
2. **Kontext als Faktenlage sammeln.** Lies Spezifikation, bestehende ADRs unter `docs/adr/` und den
   betroffenen Code: Module/Pakete, Schnittstellen, Architekturregeln (Architekturtests, Lint-Regeln),
   Persistenz. Nenne Pfade. Was du nicht nachgesehen hast, schreibst du nicht als Fakt.
3. **Entscheidungstreiber benennen.** 3–6 Kriterien, an denen die Optionen gemessen werden
   (z. B. Konsistenz, Modulgrenzen, Aufwand bis zum ersten lauffähigen Slice, Änderbarkeit,
   Sicherheit, Betrieb). Treiber kommen aus Spec und Kontext, nicht aus Vorlieben.
4. **Optionen breit denken – mindestens drei.** Pflicht:
   - eine Option **„nichts tun / minimal“** (kleinster denkbarer Eingriff, auch wenn sie schlecht ist –
     sie zeigt, was die anderen Optionen kosten);
   - eine Option, die du zunächst **nicht** wählen würdest (größerer Schnitt, anderer Ort, neues Modul).
   Optionen müssen sich wirklich unterscheiden, nicht nur in Namen.
5. **Je Option bewerten:**
   - *Risiken*: Was bricht? Welche Regel/welcher Test schlägt an? Was wird schwer umkehrbar?
   - *Trade-offs*: Was gewinnt man, was kostet es (Aufwand, Kopplung, Komplexität)?
   - Eine Vergleichstabelle gegen die Treiber.
6. **Entscheiden und begründen.** Die Begründung verweist auf Treiber und Risiken. Hat der Nutzer
   bereits entschieden, übernimm das und schreibe die Begründung. Ist die Abwägung knapp oder fehlt
   dir eine fachliche Information: Empfehlung formulieren, offene Punkte nennen, **nachfragen statt
   raten**. Fachliche Regeln (Grenzwerte, Fristen, Rückabwicklung) werden hier nicht entschieden –
   sie bleiben in der Spezifikation (offen oder entschieden).
7. **Konsequenzen ehrlich aufschreiben** – positiv, negativ, Folgearbeiten. Was wird einfacher, was
   schwieriger, was muss jetzt jemand tun?
8. **Überprüfbarkeit festlegen.** Welche Tests, Architekturregeln oder Befehle zeigen, dass der Code
   der Entscheidung folgt? Wann wird die Entscheidung erneut geprüft (Wiedervorlage-Auslöser)?
9. **Nummer und Datei bestimmen.**
   - Höchste vorhandene Nummer: `ls docs/adr 2>/dev/null | grep -E '^[0-9]{4}-' | sort | tail -n 1`
   - Nächste = höchste + 1, vierstellig mit führenden Nullen. Ordner leer oder fehlt: `0001`
     (Ordner anlegen).
   - Slug: aus dem Titel, kebab-case, ASCII (ä→ae, ö→oe, ü→ue, ß→ss), höchstens ~6 Wörter.
   - Datei: `docs/adr/NNNN-slug.md`. Niemals eine bestehende Datei überschreiben.
10. **Schreiben.** Lies `adr-template.md` (liegt neben dieser Datei), fülle alle Abschnitte.
    Status: **Proposed**. Datum: heute (`YYYY-MM-DD`). Auf **Accepted** setzen Menschen – im Review.
11. **Antwort**: Pfad, die Entscheidung in einem Satz, die wichtigste negative Konsequenz, offene
    Fragen.

## Ablösen (Supersede)

Ersetzt die neue ADR eine alte:
1. Neue ADR normal anlegen; unter „Kontext“: `Ersetzt ADR-XXXX, weil …`.
2. In der alten ADR nur die Status-Zeile ändern: `Superseded by ADR-NNNN`. Inhalt der alten ADR
   bleibt unverändert – sie ist Geschichte, kein Arbeitsdokument.

## Stil

- Kurz: eine bis zwei Seiten. Wird es länger, sind es vermutlich mehrere Entscheidungen.
- Kontext = Fakten mit Pfaden und Zahlen, keine Wertungen („es war ein großes Problem“).
- Gleiche Begriffe wie Spezifikation, Glossar und Code.
- Optionen fair darstellen – auch die gewählte hat Nachteile.

## Selbstprüfung (vor der Antwort)

- [ ] Genau eine Entscheidung; Titel nennt sie.
- [ ] Mindestens drei Optionen, darunter „nichts tun / minimal“; je Option Risiken und Trade-offs.
- [ ] Begründung bezieht sich auf die Entscheidungstreiber.
- [ ] Mindestens eine negative Konsequenz steht drin.
- [ ] Jeder Pfad, jedes Modul, jede Regel im Kontext wurde nachgesehen.
- [ ] Keine fachliche Regel neu entschieden, die in der Spezifikation offen ist.
- [ ] Überprüfung nennt konkrete Tests oder Befehle.
- [ ] Datei liegt unter `docs/adr/NNNN-slug.md`, Nummer fortlaufend, Status Proposed.
