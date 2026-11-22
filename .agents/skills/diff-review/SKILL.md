---
name: diff-review
description: Prüft einen Diff nur lesend in fester Abfolge – bleibt Bestehendes unverändert, welche Randfälle fehlen im Test, was würde ein Angreifer zuerst versuchen – und liefert jeden Fund mit Datei:Zeile, Kategorie (inhaltlich/stilistisch) und Schwere. Verwenden, wenn der eigene Stand, ein Branch oder ein Pull Request vor dem Teilen reviewt werden soll. Ändert keinen Code.
---

# Diff-Review

Du **findest**, du behebst nicht. Kein Edit, kein Write, kein Commit, keine Formatierung.
Ein Fund, den du selbst „schnell fixen“ könntest, gehört trotzdem nur in die Tabelle.

## 1. Scope festlegen

- Basis: die übergebene Basis, sonst `main`. Diff immer mit drei Punkten:
  `git diff --stat <basis>...HEAD`, danach `git diff <basis>...HEAD`.
  (Drei Punkte = ab dem gemeinsamen Vorfahren; nur die Änderungen dieses Branches.)
- `git status` kurz prüfen: Gibt es nicht committete Änderungen, **nenne sie**, reviewe sie aber nur,
  wenn das ausdrücklich verlangt ist.
- Großer Diff (> ca. 800 Zeilen): erst die Dateiliste nach Risiko ordnen (Einstiegspunkte,
  Datenmodell, Persistenz, Geld/Mengen, Berechtigungen vor Darstellung), dann in dieser Abfolge lesen.
- Für jede geänderte Datei: Aufrufer suchen (Grep nach Klassen-/Funktionsnamen) und die zugehörigen
  Tests öffnen. Ein Diff allein zeigt nicht, wer sich auf das alte Verhalten verlässt.

## 2. Prüfabfolge (immer alle drei, in dieser Abfolge)

### Schritt 1 – Verhält sich Bestehendes unverändert?

- Geänderte Signaturen, Default-Werte, Pflichtfelder, Validierungen, Mappings, Persistenz,
  Serialisierung (neues Pflichtfeld = alte Clients/Daten brechen?).
- Entfernter, umbenannter oder verschobener Code: Wer hat ihn noch benutzt?
- **Geänderte bestehende Tests sind der stärkste Hinweis.** Für jeden angepassten Test fragen:
  Wurde die Erwartung abgeschwächt, eine Assertion entfernt, ein Test übersprungen/deaktiviert,
  Testdaten so geändert, dass der Fall nicht mehr vorkommt? Dann ist das ein inhaltlicher Fund,
  bis das Gegenteil belegt ist.
- Nebenwirkungen: neue Abhängigkeiten, geänderte Konfiguration, andere Log-Ausgaben, geänderte
  Fehlercodes.

### Schritt 2 – Welche Randfälle fehlen im Test?

Für jedes neue oder geänderte Verhalten: Gibt es einen Test für
- null / leer / fehlend, Grenzwerte (unter, auf, über jeder Grenze), ungültige Werte,
- Fehlerpfade (was passiert bei Exception, welcher Statuscode, was sieht der Nutzer),
- Wiederholung und Mehrfachauslösung, Nebenläufigkeit,
- Konsistenz zwischen Schichten (gleiche Regel in Client und Server? nur auf einer Seite geprüft?).

Nenne den **konkreten fehlenden Testfall** (Eingabe → erwartetes Verhalten), nicht „mehr Tests“.

### Schritt 3 – Was würde ein Angreifer zuerst versuchen?

Denke als jemand, der die Oberfläche umgeht und Anfragen direkt schickt:
- Welche Werte kommen vom Client und werden ohne serverseitige Prüfung übernommen
  (Wertebereiche, Mengen, Beträge, IDs, Zustände)?
- Kann man fremde Objekte über IDs ansprechen, Schritte überspringen oder doppelt auslösen?
- Gelangen Eingaben ungeprüft in Abfragen, Templates, Pfade, Logs?

Das ist ein Schnelltest, kein vollständiges Security-Review. Für Tiefe: Skill `sicherheits-review`.

## 3. Einordnen

**Kategorie**
- *inhaltlich*: ändert Verhalten, Korrektheit, Sicherheit, Datenintegrität oder fehlender Test für
  echtes Verhalten. Prüffrage: *Würde ein Nutzer, Betreiber oder Angreifer den Unterschied merken?*
- *stilistisch*: Naming, Formatierung, Kommentare, Geschmack, „könnte man eleganter schreiben“.

**Schwere** (nur für inhaltliche Funde)
- *hoch*: falsches Ergebnis, Datenverlust, Geld, Sicherheit oder gebrochener Bestand – vor dem Merge beheben.
- *mittel*: Randfall falsch oder ungetestet, realistisch erreichbar.
- *niedrig*: theoretisch, schwer erreichbar oder nur Robustheit.

**Belegpflicht:** Jeder Fund zitiert die betroffene Zeile oder den fehlenden Test konkret. Was du
vermutest, aber nicht belegen kannst, kommt als **Frage** in die Tabelle (Schwere „?“), nicht als Fund.

Zeilennummern: aus dem Hunk-Kopf `@@ -a,b +c,d @@` (Zeile `c` = erste Zeile im neuen Stand) ableiten
oder die Datei im aktuellen Stand lesen und nachzählen. Keine geschätzten Zeilennummern.

## 4. Ausgabe

```
Basis: <basis>...HEAD   Dateien: <n>   Zeilen: +<a> / -<b>

| # | Datei:Zeile | Schritt (1/2/3) | Kategorie | Schwere | Fund | Beleg / fehlender Testfall |
|---|-------------|-----------------|-----------|---------|------|----------------------------|

Fragen an den Menschen (nicht belegbar, aber prüfenswert):
- …

Fazit (max. 3 Sätze): größtes Risiko · was dieses Review NICHT geprüft hat (z. B. Laufzeitverhalten,
nicht committete Dateien, Fachregeln, die nirgends stehen).

Anhang – stilistisch (max. 5 Punkte, je eine Zeile, keine Schwere):
- Datei:Zeile – …
```

## Nicht tun

- Keine Stilkritik im Hauptteil – Stil nur im Anhang.
- Kein Nacherzählen des Diffs, kein Lob, keine Zusammenfassung „was der Code macht“.
- Kein Code für Fixes. Höchstens ein Halbsatz zur Richtung („serverseitig begrenzen“, „Test für leere
  Eingabe ergänzen“).
- Keine Funde aus Dateien außerhalb des Diffs – außer sie belegen einen Fund im Diff (dann als Beleg nennen).
