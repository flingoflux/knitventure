---
name: spezifikation
description: Schreibt aus einem Klärungsdokument (Interview-Ergebnis, Ticket, Notizen, Mockup-Beschreibung) eine überprüfbare Spezifikation nach specs/<slug>.md – mit Wozu, Regeln, nummerierten Akzeptanzszenarien (Given/When/Then), „Fertig, wenn“ aus Befehlen und beobachtbaren Tatsachen und einer Liste offener Punkte. Nutzen, wenn eine geklärte Anforderung vor der Umsetzung festgeschrieben werden soll. Nicht für Architekturentscheidungen (dafür ein ADR) und nicht, solange die Anforderung noch ungeklärt ist (erst klären).
---

# Spezifikation schreiben

Eine Spezifikation macht aus einer Beschreibung ein **überprüfbares Ziel** – für den Agenten, der
umsetzt, und für die Menschen, die abnehmen. Der wichtigste Abschnitt ist „Fertig, wenn“: Er sagt,
woran alle erkennen, dass die Arbeit erledigt ist, ohne jemanden fragen zu müssen.

Du **schreibst auf, was entschieden ist**. Du entscheidest nichts Fachliches selbst.

## Eingaben

- Pfad zum Klärungsdokument (Pflicht). Fehlt er, frag danach – rate nicht.
- Optional: Mockup/Design-Beschreibung, bestehende Specs unter `specs/`, Glossar, `AGENTS.md`.
- Optional: Name/Slug der Spec. Sonst aus dem Titel ableiten (kebab-case, ASCII, Umlaute als ae/oe/ue/ss).

## Ablauf

1. **Klärung lesen und sortieren.** Lege drei Listen an:
   - *Entschieden* – steht ausdrücklich als Antwort/Entscheidung im Dokument.
   - *Offen* – als Frage markiert, widersprüchlich, oder gar nicht erwähnt, aber für die Umsetzung relevant.
   - *Abgeleitet* – folgt zwingend aus Entschiedenem oder aus bestehendem Verhalten im Code
     (Beispiel: Eine Auswahl aus festen Werten ⇒ unbekannte Werte werden abgelehnt). Jede Ableitung
     bekommt in der Spec einen Hinweis, woraus sie folgt.
2. **Bestehendes Verhalten erkunden.** Lies den betroffenen Code (Einstiegspunkte, Schnittstellen,
   Tests). Halte fest, welches heutige Verhalten **unverändert bleiben muss** – mindestens: Wer die
   neue Funktion nicht nutzt, merkt nichts. Daraus werden eigene Szenarien.
3. **Prüfbefehle ermitteln, nicht raten.** Hole Build-, Test- und Architekturprüf-Befehle aus
   `AGENTS.md`, README, Build-Dateien (`pom.xml`, `package.json`, `Makefile` …). Prüfe, dass es
   Skripte/Ziele wirklich gibt. Unsichere Befehle als „unverifiziert“ markieren und nachfragen.
4. **Vorlage füllen.** Lies `spec-template.md` (liegt neben dieser Datei) und fülle sie aus:
   - **Wozu**: 2–4 Sätze. Wer hat welchen Nutzen? Keine Lösung beschreiben.
   - **Begriffe** (optional): Ein Begriff pro Sache, passend zum Glossar und zum Code.
   - **Regeln**: nummeriert (R1, R2 …), je eine prüfbare Aussage, nur *Entschieden* und *Abgeleitet*.
   - **Akzeptanzszenarien**: nummeriert (A1, A2 …), Given/When/Then, konkrete Werte statt „korrekt“.
     Je Regel mindestens ein Szenario; Fehlerfälle als eigene Szenarien; jedes Szenario nennt die
     Regel(n) und den Slice (SL1, SL2 … wie im Klärungsdokument), in dem es umgesetzt wird.
     Ein Szenario = ein Test, der rot werden kann.
   - **Fertig, wenn**: nur **Befehle** (in Backticks, mit Arbeitsverzeichnis) oder **beobachtbare
     Tatsachen** (was sieht/misst man wo?). Gilt für die gesamte Spezifikation; das „Fertig, wenn“
     eines einzelnen Slices steht im Slice-Plan. Pflichtpunkt: „Bestehendes Verhalten unverändert“ –
     mit den Szenarien und/oder einem Befehl, der es zeigt.
   - **Offen (nicht Teil dieser Spezifikation)**: jede offene Frage mit Ansprechpartner und der
     Folge für die Umsetzung („bis zur Klärung: keine Regel“).
   - **Slices**: nur Verweis auf den Slice-Plan und Zuordnung Szenario → Slice. Den Zuschnitt
     übernimmst du aus dem Klärungsdokument, statt neu zu schneiden. Kein Umsetzungsdesign.
5. **Ablegen** unter `specs/<slug>.md`. Existiert die Datei, nicht überschreiben – Unterschiede zeigen
   und fragen.
6. **Selbstprüfung** (unten) durchgehen, Funde korrigieren.
7. **Antwort**: Pfad, Anzahl Regeln/Szenarien, Liste *Offen* und *Abgeleitet*, Rückfragen.

## Harte Regeln

- **Keine Entscheidungen erfinden.** Was die Klärung nicht entscheidet, steht unter *Offen* – auch
  wenn ein „sinnvoller Standard“ naheliegt (Grenzwerte, Fristen, Rückabwicklung, Berechtigungen).
  Offenes wird nicht in Regeln, Szenarien oder „Fertig, wenn“ hineingeschmuggelt.
- **Kein Lösungsdesign.** Klassen, Tabellen, Komponenten gehören in ADR und Slice-Plan. Erlaubt sind
  Fakten an der Außenkante, die die Klärung festlegt oder die bestehende Schnittstelle vorgibt
  (Endpunkt, Feldname, Fehlercode).
- **Keine Weichmacher.** „sollte“, „ggf.“, „möglichst“, „schnell“, „benutzerfreundlich“,
  „korrekt“, „sinnvoll“ ersetzen durch Werte oder streichen.
- **Begriffe stabil halten.** Dieselbe Sache heißt überall gleich (Spec, Code, Glossar, Tests).

## Selbstprüfung (vor der Antwort)

- [ ] Jede Regel lässt sich auf eine Stelle im Klärungsdokument oder auf eine markierte Ableitung zurückführen.
- [ ] Jede Regel hat mindestens ein Szenario; jedes Szenario nennt Regel und Slice.
- [ ] Jedes Szenario hat konkrete Werte im Then und kann als Test fehlschlagen.
- [ ] Jeder Punkt unter „Fertig, wenn“ ist ein Befehl in Backticks oder eine beobachtbare Tatsache –
      nichts, was nur durch Meinung entschieden wird („sauber“, „vollständig“).
- [ ] „Bestehendes Verhalten unverändert“ steht unter „Fertig, wenn“ und hat eigene Szenarien.
- [ ] Jeder offene Punkt aus der Klärung steht unter *Offen* und taucht sonst nirgends als Regel auf:
      Suchbegriffe der offenen Punkte in der Spec suchen (`grep -n '<begriff>' specs/<slug>.md`) –
      Treffer nur im Abschnitt *Offen*.
- [ ] Weichmacher-Check: `grep -nE 'sollte|ggf\.|möglichst|eventuell|benutzerfreundlich|korrekt|sinnvoll' specs/<slug>.md` → keine Treffer außerhalb von Zitaten.
- [ ] Alle Befehle unter „Fertig, wenn“ existieren (Skript/Ziel nachgesehen oder einmal ausgeführt).
