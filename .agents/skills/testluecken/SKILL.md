---
name: testluecken
description: Findet systematisch fehlende Testfälle für eine Funktion, Regel oder Komponente – Äquivalenzklassen, Grenzwerte, Fehlerpfade, ungültige Eingaben, null/leer, Groß-/Kleinschreibung, Nebenläufigkeit – stellt sie als Tabelle gegen die vorhandenen Tests und schreibt danach genau einen roten Test. Verwenden, wenn Testabdeckung geschärft, Randfälle gesucht oder ein Fehler zuerst per Test nachgestellt werden soll.
---

# Testlücken finden

Die Qualität der Tests hängt von der Frage ab. „Schreib Tests dafür“ liefert drei Happy-Path-Tests.
Dieser Skill stellt die Fragen, die zu Randfall- und Fehlerpfad-Tests führen.

## Grundregel: Test nie an den Code anpassen

- Erwartungswerte kommen aus Spezifikation, Akzeptanzkriterien, Glossar oder einer Antwort des
  Menschen – **nie** aus der aktuellen Ausgabe des Codes.
- Ein roter Test wird nicht „repariert“, indem man die Erwartung ändert, eine Assertion entfernt,
  den Test überspringt/deaktiviert oder das Prüfobjekt wegmockt.
- Hältst du einen Test für falsch: anhalten, begründen, fragen. Der Mensch entscheidet.

## Phase 1 – Verstehen (lesen, nichts ändern)

1. Prüfobjekt eingrenzen: welche Funktion/Komponente, welche Schicht(en). Gibt es dieselbe Regel in
   mehreren Schichten (Client und Server)? Dann beide betrachten.
2. Eingaben und Ausgaben auflisten: Parameter, Felder, Zustände; wer liefert sie (Nutzer, API, Datenbank)?
3. **Wo kommen die Werte in Wirklichkeit her?** Testdaten und Seed-Daten sind oft gutmütiger als die
   Produktion (keine leeren Felder, keine Sonderfälle). Notiere, welche Klassen in den Daten nie vorkommen.
4. Vorhandene Tests lesen und je Test notieren, welchen Fall er abdeckt.
5. Testbefehle aus `AGENTS.md` übernehmen; einmal laufen lassen – Ausgangslage muss grün sein.
   Ist sie rot: melden und stoppen.

## Phase 2 – Fragenkatalog („Engineering in“)

Arbeite jede Kategorie ab. Eine Kategorie, die nicht zutrifft, mit einem Satz begründen statt weglassen.

| Kategorie | Leitfragen |
|---|---|
| Äquivalenzklassen | Welche gültigen Klassen gibt es (je ein Vertreter)? Welche ungültigen? Gibt es eine Klasse „trifft auf keinen Fall zu“ (leeres Ergebnis)? |
| Grenzwerte | Wo liegen Grenzen? Je Grenze: knapp darunter, genau darauf, knapp darüber. Inklusiv oder exklusiv – steht das irgendwo? Minimum/Maximum des Datentyps? |
| null / leer / fehlend | null, leerer String, nur Leerzeichen, leere Liste, Feld fehlt in der Anfrage, optionaler Wert nicht gesetzt. Was ist hier fachlich richtig – ausschließen, einschließen, Fehler? |
| Ungültige Eingaben | Falsches Format, unbekannter Aufzählungswert, negative Zahl, zu lang, Sonderzeichen, Unicode, Manipulation über direkte Anfrage statt Oberfläche. |
| Groß-/Kleinschreibung, Normalisierung | „Wert“ vs. „wert“ vs. „ wert “, Umlaute und ß, Synonyme/Abkürzungen, gemischte Schreibweisen in den Daten. |
| Fehlerpfade | Was passiert bei Exception, Timeout, leerer Antwort? Welcher Statuscode, welche Meldung, was sieht der Nutzer? Teilweiser Erfolg? |
| Kombinationen und Zustand | Mehrere Bedingungen gleichzeitig, Zurücksetzen, Wechsel des Kontexts (z. B. anderes Datum, andere Auswahl), Abhängigkeit von der Abfolge der Aktionen. |
| Nebenläufigkeit | Zwei gleichzeitige Aufrufe, Doppelklick, schnell wechselnde Auswahl im Client (veraltete Antwort überschreibt neuere), gleichzeitiges Ändern derselben Daten. |
| Schichtkonsistenz | Liefert Client und Server für denselben Fall dasselbe? Wird nur auf einer Seite geprüft? |

Fachlich offene Erwartung (niemand hat festgelegt, was richtig ist) **nicht raten**: als
„offen – fachlich klären“ markieren. Ob ein Risiko zählt, entscheidet der Mensch.

## Phase 3 – Tabelle ausgeben, dann STOPP

```
| # | Testfall (Eingabe → Situation) | Klasse/Grenze | erwartet | vorhanden? |
|---|--------------------------------|---------------|----------|------------|
| 1 | …                              | Grenze: …     | …        | ja: <Testname> / nein / teilweise: <was fehlt> |
```

Danach höchstens drei Sätze: welche drei Lücken du für die riskantesten hältst und **warum**
(Wahrscheinlichkeit im echten Betrieb, Folgen). Dann **anhalten** und fragen, welche Zeile als
roter Test nachgestellt werden soll.

## Phase 4 – Genau einen roten Test schreiben

1. Nur Testcode ändern, kein Produktionscode.
2. Testname beschreibt das erwartete Verhalten, nicht die Implementierung.
3. Test ausführen. Er muss **rot aus dem richtigen Grund** sein: die fachliche Assertion schlägt fehl –
   nicht Kompilierfehler, fehlende Testdaten oder Setup-Fehler.
4. Ist er grün: Die Lücke war keine. In der Tabelle vermerken, Test behalten (er schützt jetzt den Fall),
   nichts am Code ändern.
5. Ausgabe: Testname, Befehl, relevante Fehlermeldung (zwei bis fünf Zeilen). Dann **anhalten**:
   Produktionscode erst nach Bestätigung durch den Menschen.
6. Ist ein Stop-Gate aktiv, das bei roten Tests blockiert: den Menschen bitten, es zu pausieren, statt den Test grün zu machen.

## Phase 5 – Minimal fixen (nur nach Bestätigung)

- Kleinste Änderung im Produktionscode, die den roten Test grün macht.
- Den neuen Test nicht anfassen. Alle Tests laufen lassen – vorher grüne Tests müssen grün bleiben.
- Bericht: geänderte Datei(en) mit einem Satz, Testlauf vorher/nachher, verbleibende offene Zeilen der Tabelle.
