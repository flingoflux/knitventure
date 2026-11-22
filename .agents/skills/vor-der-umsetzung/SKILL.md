---
name: vor-der-umsetzung
description: Ziehen, bevor eine neue fachliche Anforderung umgesetzt oder ein bestehendes Verhalten fachlich geändert wird – etwa ein neuer Filter, eine neue Regel, ein neues Feld oder eine neue Ansicht. Klärt Begriffe, Fundstellen und Annahmen, bevor Code entsteht, und arbeitet dann testgetrieben. Nicht für reine Refactorings, Tippfehler oder Abhängigkeits-Updates.
---

# Vor der Umsetzung

Ziel: Nichts Fachliches raten. Jede Annahme wird sichtbar, belegt oder erfragt.

## 1. Begriffe klären
- Zerlege die Anforderung in ihre Fachbegriffe.
- Schlage jeden Begriff in `AGENTS.md` und im Glossar des Projekts nach (Pfad steht in `AGENTS.md`).
- Gibt es den Begriff im Projekt schon in anderer Bedeutung? Dann nicht übernehmen, sondern nachfragen.

## 2. Fundstellen suchen und zeigen
- Finde, wo das betroffene Verhalten heute entsteht (Datenmodell, Schnittstelle, Oberfläche).
- Gibt es mehrere Modelle für denselben Begriff? Benenne, welches du änderst und warum.
- Zeige die Fundstellen mit Pfad, bevor du etwas änderst.
- Ermittle mögliche Werte aus Code und Testdaten, statt sie anzunehmen.

## 3. Annahmen je Kategorie auflisten
Fülle für jede Kategorie mindestens eine Zeile – oder schreibe „keine“:

| Kategorie | Frage |
|---|---|
| Begriff | Was genau bedeutet das Wort hier? |
| Randfall | Was passiert bei leer, unbekannt, fehlend, Groß-/Kleinschreibung, Grenzwert? |
| Ort im Code | In welche Schicht (Oberfläche, Schnittstelle, Datenhaltung) – und warum nicht in eine andere? |
| Verhalten | Standardzustand, Bedienung, Zusammenspiel mit bestehenden Funktionen? |
| Test | Woran erkennt ein Test, dass es stimmt? Welche Testdaten fehlen? |

Gib zu jeder Annahme an: **Quelle** (Fundstelle, Glossar, Nutzer) und **Sicherheit** (hoch/mittel/niedrig).

Eine Annahme ohne Fundstelle im Repository und ohne Aussage des Nutzers gilt immer als „niedrig“.

**Stopp-Regel:** Bei Sicherheit „niedrig“ nicht raten. Stelle die offenen Fragen gesammelt und warte auf Antwort.

## 4. Test zuerst
- Schreibe für jede fachliche Regel einen Test, der jetzt rot ist. Führe ihn aus und zeige das Rot.
- Lege fehlende Testdaten im Test selbst an; verlasse dich nicht auf Beispieldaten.
- Decke die Randfälle aus Schritt 3 ab.

## 5. Umsetzen und prüfen
- Setze minimal um, bis die Tests grün sind.
- Führe die Build- und Testbefehle aus `AGENTS.md` aus – alle betroffenen Teile, nicht nur den neuen Test.

## 6. Abschluss
Berichte kurz: geänderte Dateien, Testergebnis, die Annahmen-Tabelle (aktualisiert) und offene Fragen.
Schlage vor, welche bestätigte Annahme in `AGENTS.md` oder ins Glossar gehört.

## Projektspezifisches
Siehe `references/projekt.md` – nur lesen, wenn das Projekt dort Regeln zu den Begriffen oder Orten
der aktuellen Anforderung hat oder Schritt 1–2 ohne Ergebnis bleiben.
