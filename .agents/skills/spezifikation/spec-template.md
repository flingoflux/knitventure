# <Titel der Funktion>

> Quelle: `<Pfad zum Klärungsdokument>` · Stand: <YYYY-MM-DD> · Status: Entwurf | Abgestimmt
> Architekturentscheidung: `<docs/adr/NNNN-slug.md>` (falls vorhanden) · Slices: `<Pfad zum Slice-Plan>`

## Wozu

<2–4 Sätze: Wer bekommt welchen Nutzen? Was soll sich für wen ändern – und für wen ausdrücklich nicht?>

## Begriffe

<Optional. Ein Begriff pro Sache, gleiche Schreibweise wie im Glossar und im Code.>

| Begriff | Bedeutung |
|---|---|
| <Begriff> | <Bedeutung> |

## Regeln

<Nummeriert. Je Regel eine prüfbare Aussage. Abgeleitete Regeln mit Herkunft kennzeichnen.>

- **R1** <Regel>
- **R2** <Regel> *(abgeleitet aus: <Entscheidung / bestehendem Verhalten>)*

## Akzeptanzszenarien

<Nummeriert. Konkrete Werte. Je Szenario ein Test, der rot werden kann. Fehlerfälle als eigene Szenarien.
Bestehendes Verhalten, das unverändert bleiben muss, als eigene Szenarien.>

### A1 – <Bestehendes Verhalten bleibt unverändert> · R<n> · SL<n>
- **Given** <Ausgangslage, so wie heute>
- **When** <Handlung ohne die neue Funktion>
- **Then** <exakt das heutige Ergebnis, mit Werten>

### A2 – <Name> · R<n> · SL<n>
- **Given** <Ausgangslage>
- **When** <eine Handlung>
- **Then** <beobachtbares Ergebnis mit Werten>
- **And** <weiteres Ergebnis, optional>

### A3 – <Fehlerfall> · R<n> · SL<n>
- **Given** <Ausgangslage>
- **When** <ungültige Eingabe / verbotene Handlung>
- **Then** <Fehlerbild: Code, Meldung>
- **And** <was ausdrücklich NICHT passiert, z. B. nichts gespeichert>

## Fertig, wenn

<Nur Befehle (mit Arbeitsverzeichnis) oder beobachtbare Tatsachen. Gilt für die gesamte Spezifikation;
was für einen einzelnen Slice gilt, steht im Slice-Plan.>

- [ ] `<cd <modul> && <build- und testbefehl>>` endet grün.
- [ ] `<architektur- oder lint-befehl>` endet grün.
- [ ] Zu jedem Szenario gibt es einen Test, der die Szenario-Nummer nennt:
      `<grep-befehl über die Testordner>` listet A1 bis A<n>.
- [ ] Bestehendes Verhalten unverändert: Szenarien A<n>–A<m> grün, und bestehende Tests wurden nicht
      abgeschwächt: `<git diff gegen Basis, gefiltert auf entfernte Assertions>` liefert nichts.
- [ ] <Beobachtbare Tatsache im laufenden System: wo, was, welcher Wert>.
- [ ] `git log --oneline <basis>..HEAD` zeigt einen Commit mit Spezifikation (und ADR) und danach genau
      einen Commit pro umgesetztem Slice.

## Offen (nicht Teil dieser Spezifikation)

<Jede offene Frage. Bis zur Klärung wird dazu nichts umgesetzt – weder als Regel noch als Prüfung.>

| # | Frage | Wer klärt | Folge bis zur Klärung |
|---|---|---|---|
| O1 | <Frage> | <Rolle/Person> | <z. B. keine Regel, Verhalten wie heute> |

## Slices

Umsetzung in vertikalen Slices, ein Slice = ein Commit: siehe `<Pfad zum Slice-Plan>`.

| Slice | Szenarien |
|---|---|
| SL1 | A<n>, … |
