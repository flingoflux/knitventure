---
name: sicherheits-review
description: Prüft einen Diff nur lesend auf Sicherheitslücken anhand einer festen Prüfliste (serverseitige Eingabevalidierung, Mengen und Grenzen, Preis-/Betragsmanipulation, Autorisierung, Injection, Secrets, Logging personenbezogener Daten, Abhängigkeiten), gewichtet jeden Fund nach Eintrittswahrscheinlichkeit × Schaden, benennt Security-Theater und hält Deny-Regeln und Hooks des Agenten-Harness gegen die neuen Dateien. Verwenden, wenn neuer Code vor dem Merge auf Sicherheit geprüft werden soll.
---

# Sicherheits-Review

Du findest und gewichtest. Du änderst nichts – auch keine „offensichtlichen“ Fixes.
Ziel ist nicht die längste Liste, sondern die richtige Reihung: Ein Mensch soll nach zwei Minuten
wissen, was vor dem Merge geklärt werden muss und was nicht.

## 1. Scope

- Diff: `git diff --stat <basis>...HEAD`, dann `git diff <basis>...HEAD` (Basis: übergeben, sonst `main`).
- Dazu nur, was nötig ist, um einen Datenfluss im Diff zu verstehen: Aufrufer, Mapper, Validierung,
  Persistenz der geänderten Daten. Kein Audit des ganzen Repositorys.

## 2. Angriffsfläche kartieren

Kurze Liste, bevor du Funde suchst:
- Neue oder geänderte Einstiegspunkte (HTTP-Endpunkte, Nachrichten, Uploads, Kommandos).
- Welche Felder kommen vom Client? Wohin fließen sie (Berechnung, Datenbank, Antwort, Log)?
- Wer kann den Einstiegspunkt erreichen (anonym, angemeldet, intern)? Unbekannt → als **Annahme** notieren.

## 3. Prüfliste

| # | Prüfpunkt | Leitfragen |
|---|---|---|
| P1 | Eingabevalidierung serverseitig | Hat jede Prüfung im Client ein Gegenstück im Server? Typ, Format, Aufzählungswerte, Pflichtfelder. Ungültige Eingabe → 4xx mit neutraler Meldung, nicht 5xx mit Stacktrace? |
| P2 | Mengen und Grenzen | Gibt es für Anzahlen, Längen, Listen, Größen eine fachliche und technische Obergrenze? Was passiert bei 0, negativ, sehr groß? Kann eine einzelne Anfrage viel Speicher, Rechenzeit oder Datenbankzeilen erzeugen? |
| P3 | Preis- und Betragsmanipulation | Werden Beträge, Rabatte und Summen serverseitig aus eigenen Daten berechnet oder vom Client übernommen? Rundung, negative Werte, Überlauf, Währung. Stimmt die angezeigte Summe mit der berechneten überein? |
| P4 | Autorisierung | Kann man über eine ID fremde Objekte lesen/ändern? Lassen sich Prozessschritte überspringen, wiederholen oder in falschem Zustand auslösen? |
| P5 | Injection | Zusammengesetzte Abfragen (SQL/JPQL/NoSQL), ungeschütztes HTML im Client, Shell-Aufrufe, Dateipfade aus Eingaben, Zeilenumbrüche in Logs. |
| P6 | Secrets | Schlüssel, Tokens, Passwörter, Verbindungszeichenfolgen im Diff, in Testdaten oder Konfiguration? Neue Konfigurationsdateien, die Secrets aufnehmen werden? |
| P7 | Logging personenbezogener Daten | Landen Namen, E-Mail, Zahlungsdaten oder ganze Anfrage-Objekte im Log oder in Fehlermeldungen an den Client? |
| P8 | Abhängigkeiten | Neue oder aktualisierte Pakete: bekannt und gepflegt? Version fixiert? Lizenz? Install-Skripte? Falls im Projekt eingerichtet: Audit-/Scan-Befehl nennen (nicht ungefragt installieren). |

Für jeden Prüfpunkt: Fund(e) **oder** ein Satz, warum nichts gefunden wurde (z. B. „Beträge werden
nur serverseitig aus Stammdaten berechnet, `Datei:Zeile`“). „Nichts gefunden“ ohne Begründung zählt nicht.

## 4. Gewichten: Eintrittswahrscheinlichkeit × Schaden

- **Eintrittswahrscheinlichkeit**: *hoch* = anonym mit einer einfachen Anfrage ausnutzbar;
  *mittel* = braucht Anmeldung, Wissen oder mehrere Schritte; *niedrig* = nur intern oder unter
  unwahrscheinlichen Bedingungen.
- **Schaden**: *hoch* = Geld, fremde Daten, Ausfall des Dienstes; *mittel* = falsche Daten,
  begrenzter Missbrauch, Mehraufwand im Betrieb; *niedrig* = kosmetisch, schnell korrigierbar.

| Wahrscheinlichkeit ↓ / Schaden → | niedrig | mittel | hoch |
|---|---|---|---|
| **hoch** | mittel | hoch | hoch |
| **mittel** | niedrig | mittel | hoch |
| **niedrig** | niedrig | niedrig | mittel |

Jede Einstufung bekommt einen Halbsatz Begründung und – wo nötig – die Annahme, auf der sie beruht
(„Annahme: Endpunkt öffentlich erreichbar“). Annahmen bestätigt der Mensch; ohne Bestätigung
nicht hochstufen, sondern als offen markieren.

## 5. Theater benennen

*Theater* = formal richtig, im konkreten Kontext real irrelevant. Typische Muster:
- Injection-Warnung, wo nur Konstanten oder Aufzählungswerte verarbeitet werden.
- „Secret im Code“ bei offensichtlichen Dummy-Werten in Testdaten.
- Härtungsempfehlung, die eine vorgelagerte Schicht (Proxy, Framework-Default) bereits erfüllt.
- Überlauf- oder Grenzwarnung für Werte, die vorher nachweislich begrenzt werden.
- Allgemeine Best Practices ohne Bezug zu einer Zeile im Diff.

Theater-Funde **trotzdem auflisten**, aber getrennt und mit Begründung, warum irrelevant. So sieht der
Mensch, dass der Punkt geprüft wurde, und kann widersprechen.

## 6. Harness-Gegenprüfung

Der Agent selbst ist Teil der Angriffsfläche. Lies die Agenten-Konfiguration (für Claude Code:
`.claude/settings.json`, ggf. `.claude/settings.local.json`; Hook-Skripte, auf die sie verweist) und prüfe:
1. **Deny-Regeln gegen neue Dateien:** Passen die Muster auf die im Diff neu entstandenen sensiblen
   Dateien (Konfiguration je Umgebung, Zertifikate, Schlüssel, lokale Overrides, Logs)? Neue
   Namensmuster, die nicht abgedeckt sind?
2. **Bash-Umweg:** Deny-Regeln für Datei-Werkzeuge gelten nicht automatisch für Shell-Befehle.
   Blockiert ein Hook Lesezugriffe über `cat`, `grep`, `head`, Kopieren, `git show <rev>:<pfad>`,
   `git diff --no-index`? Matcher des Hooks deckt das Werkzeug wirklich ab?
3. **Gates gegen neue Ordner:** Laufen Test- und Qualitäts-Hooks auch für neu hinzugekommene Module
   oder Verzeichnisse?

**Nicht selbst ausprobieren** – keine Secrets lesen, keine Sperre aktiv umgehen. Schlage stattdessen
eine Gegenprobe vor, die der Mensch mit einer Dummy-Datei ausführt (z. B. Datei mit Platzhalterwert
anlegen, Agent bitten, den Wert auszugeben, Ergebnis notieren).

## 7. Ausgabe

```
Angriffsfläche: <Einstiegspunkte, Felder vom Client, Annahmen zur Erreichbarkeit>

Funde (nach Risiko absteigend)
| # | Datei:Zeile | Prüfpunkt | Fund | Wahrscheinlichkeit | Schaden | Risiko | Begründung / Annahme |

Ohne Fund (je Prüfpunkt ein Satz mit Beleg)
- P1 … P8

Theater
| # | Datei:Zeile | Warnung | Warum hier irrelevant |

Harness
| Regel / Hook | deckt neue Dateien? | möglicher Umweg | Gegenprobe für den Menschen |

Nicht geprüft: <z. B. Laufzeitkonfiguration, Infrastruktur, Abhängigkeiten ohne Scan>
```

## Nicht tun

- Nicht alles „kritisch“ nennen. Höchstens die obersten Funde als *hoch* – Gewichtung ist der Wert dieses Reviews.
- Keine Funde ohne Datei:Zeile (außer „fehlt“-Funde: dann die Stelle, an der es fehlen müsste).
- Keinen Code ändern, keine Pakete installieren, keine Scans gegen fremde Systeme.
