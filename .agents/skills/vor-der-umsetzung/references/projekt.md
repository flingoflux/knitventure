# Projektwissen Kino – für `vor-der-umsetzung`

Nur lesen, wenn die Anforderung Programm, Filme, Altersfreigaben, Sprache oder Filter betrifft.
Build- und Testbefehle stehen in `AGENTS.md`, nicht hier.

## Regeln für Filter im Programm

- **Ort:** Filter, die das Programm eines Tages einschränken, gehören in den Bounded Context
  `filmauswahl`. Die Programmseite liegt im Frontend unter
  `frontend/src/app/filmauswahl/components/programm-page/`, die Tagesauswahl in `kalender/`,
  der Eintrag je Film in `programmeintrag/`. Backend-Weg: `GET /api/programm?datum=…` →
  `filmauswahl/web/ProgrammController` → `filmauswahl/service/ProgrammService` →
  `filmauswahl/data/AktuelleFilme`.
- **Frontend oder Backend?** Vor dem Bauen entscheiden und begründen. Das Programm eines Tages ist
  klein und vollständig im Frontend vorhanden; ein reiner Anzeige-Filter braucht keinen neuen
  Endpunkt. Wer ins Backend geht, ändert die API – das ist eine Rückfrage wert.
- **Verhalten:** Ein Filter ist ein Schalter oder eine Auswahl, standardmäßig *aus* (alles sichtbar).
  Er wirkt auf das Programm des gewählten Tages. Nicht festgelegt und deshalb zu fragen: Bleibt er
  beim Tageswechsel erhalten? Wie wirken mehrere Filter zusammen?
- **Leeres Ergebnis:** Zeigt der Filter nichts mehr an, braucht es einen Hinweis statt einer leeren Seite.

## Drei Film-Modelle (zwei davon relevant für das Programm)

- `filmauswahl/data/Film` (JPA-Entity, `Integer fsk`, `String sprache`) – das liest das Programm.
- `wochenplanung/filmkatalog/Film` (record, Enum `Altersfreigabe`) – Quelle, wird per
  `WochenplanImportService` nach `filmauswahl` übernommen.
- `kartenverkauf/application/domain/vorstellungen/Film` (Value Object, nur `name`) – für das
  Programm nicht relevant.
- Regel: Für Anzeige und Filter im Programm das `filmauswahl`-Modell nehmen. Den Katalog nicht
  ändern, ohne zu fragen.

## Begriffe mit Fallen

- **Kinderfilm (als Filter):** Film mit Altersfreigabe 0 oder 6. Ein Film ohne Freigabe (`fsk` ist
  `null`) ist *kein* Kinderfilm.
- **Kinderfilm (im Glossar):** `VorstellungKategorie` *Kinderfilm* ist eine Preisstufe einer
  Vorstellung – hat mit der Altersfreigabe nichts zu tun. Nicht verwechseln, nicht wiederverwenden.
- **Allgemein:** Klingt ein Wunsch nach einem Begriff aus `docs/Glossar.md`, aber in anderer
  Bedeutung, ist das eine offene Frage, keine Annahme.

## Freitextfelder

- `sprache` ist Freitext (heute z. B. „deutsch“, „englisch“), kein Enum. Es gibt kein OV/OmU-Feld.
- Regel: Vergleiche normalisieren (trimmen, Groß-/Kleinschreibung ignorieren).
- Regel: Auswahlwerte aus den Daten des gewählten Tages ermitteln, nicht fest im Code auflisten.
- Was ein Wert fachlich bedeutet (ist „englisch“ = Originalfassung?), entscheidet ein Mensch.

## Testdaten

- Die Beispieldaten kommen aus `wochenplanung/application/fixtures/WochenplanFixture.java` und
  werden bei jedem Start neu erzeugt. Sie decken Randfälle nicht ab (u. a. kein Film mit Freigabe 0,
  keine fehlenden Werte).
- Regel: Testdaten für Randfälle im Test selbst anlegen. Fixture nicht ändern, um Tests grün zu machen.
- Vorhandene Tests als Vorlage: `programm.component.spec.ts`, `programmeintrag.component.spec.ts`,
  im Backend `filmauswahl/web/ProgrammControllerTest`, `filmauswahl/service/ProgrammServiceIntegrationTest`.
