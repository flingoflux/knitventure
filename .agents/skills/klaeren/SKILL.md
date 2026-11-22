---
name: klaeren
description: Klärt eine neue fachliche Anforderung per Interview, bevor Code entsteht – eine Frage nach der anderen, bis nichts mehr angenommen werden muss. Erhebt den Ist-Prozess aus Code und Diagrammen, vergleicht ihn mit dem Soll und schneidet priorisierte vertikale Slices. Ziehen, wenn eine Anforderung neu oder unscharf ist („Wir wollen, dass …“, Feature-Idee, Ticket ohne Akzeptanzkriterien) oder wenn jemand „klär das erst mal“ sagt.
---

# Anforderung klären

Ziel ist ein Klärungsdokument, aus dem sich danach eine Spezifikation schreiben lässt. Du
entscheidest dabei nichts Fachliches selbst: Du deckst auf, was du sonst annehmen müsstest.

## Regeln

- **Schreibe noch keinen Code** und ändere keine Datei außer dem Klärungsdokument.
- **Eine Frage pro Nachricht.** Stell sie, dann warte auf die Antwort. Keine Fragenkataloge.
- Frag nur, was der Code, die Doku oder eine frühere Antwort nicht schon beantwortet. Was du
  nachgelesen hast, nenne kurz als Beleg („laut `<Datei>` passiert heute X – soll das so bleiben?“).
- Formuliere jede Interviewfrage mit zwei bis drei kurzen, klar unterscheidbaren Antwortoptionen, die aus dem Ist-Stand oder aus bisherigen Antworten folgen. Kennzeichne eine begründete Empfehlung ausdrücklich als solche.
- Zeige die Auswahl als anklickbare Optionen. Nutze im Standardmodus `request_user_input_async` und im Planmodus `request_user_input`, sofern das jeweilige Werkzeug verfügbar ist. Sende genau eine Frage und warte auf die ausdrücklich abgeschickte Antwort. Eine Vorauswahl oder ausbleibende Antwort zählt nicht als Entscheidung.
- Steht kein Auswahlwerkzeug zur Verfügung, nummeriere die Optionen im Chat, sodass eine Ziffer als Antwort genügt. Freitext bleibt in beiden Fällen möglich. Wenn sich keine sinnvollen Optionen aus dem bisherigen Stand ableiten lassen, stelle eine einzelne offene Frage.
- **„Wissen wir (noch) nicht“ ist eine gültige Antwort.** Dann entscheidest du NICHT selbst und
  setzt auch keinen „sinnvollen Standard“ ein. Notiere es als offene Frage, mit dem, was davon
  abhängt, und geh zur nächsten Frage.
- Wenn eine Antwort einer früheren oder dem Code widerspricht, sprich den Widerspruch an.
- Nach etwa 15 Fragen biete einen Zwischenstand an, statt endlos weiterzufragen.

## Ablauf

### 1. Ist erheben (vor der ersten Frage, ohne den Menschen zu fragen)

- Suche den betroffenen Ablauf im Code: Einstieg in der Oberfläche, Schritte in ihrer
  Reihenfolge, aufgerufene Endpunkte, beteiligte Domänenobjekte, wo Preise/Regeln berechnet werden.
- Lies vorhandene Prozessdiagramme, Glossar und Architekturdoku zu diesem Ablauf.
- Halte das Ist in wenigen Zeilen fest – mit Dateipfaden als Beleg. Es ist die Grundlage für
  Frage und Vergleich.
- Ordner, die gesperrt sind oder die der Mensch ausgeschlossen hat, liest du nicht – auch nicht
  über Umwege.

### 2. Interview

Geh die Kategorien durch. Reihenfolge nach Bedarf, aber keine überspringen:

| Kategorie | Typische Frage |
|---|---|
| Begriff | Was genau ist mit `<Wort>` gemeint? Gibt es den Begriff schon im Glossar/Code? |
| Nutzer | Wer benutzt das – welche Rolle, über welchen Kanal? Wer ist ausdrücklich nicht gemeint? |
| Verhalten | Was passiert im Normalfall Schritt für Schritt? Was bleibt unverändert? |
| Ort im Ablauf / Code | An welcher Stelle des bestehenden Ablaufs setzt es an? |
| Randfall | Null, eins, viele – gibt es Ober- oder Untergrenzen? Was bei Wiederholung oder Abbruch? |
| Fehlerverhalten | Was sieht der Nutzer, wenn etwas schiefgeht? Was wird zurückgerollt? |
| Fehlende Daten | Woher kommen Werte (Preise, Stammdaten, Konfiguration)? Wer pflegt sie? |
| Vertrauen | Welche Werte darf der Client liefern, welche muss der Server selbst bestimmen? |
| Zeit | Gibt es Fristen, Zeitfenster, Stichtage? |
| Rückabwicklung | Ändern, stornieren, erstatten – was gilt, und für welchen Teil? |
| Test | Woran erkennen wir, dass es fertig ist? Welches Beispiel muss funktionieren? |

Hör auf, wenn jede Kategorie entweder beantwortet oder als offene Frage notiert ist – oder
wenn der Mensch das Interview beendet.

### 3. Ist und Soll vergleichen

- Beschreibe den Soll-Ablauf in denselben Schritten wie das Ist und markiere, was neu ist.
- **Lücken:** Was fehlt im heutigen Code/Modell, damit das Soll möglich wird?
- **Chancen:** Was wird durch die Änderung nebenbei besser oder einfacher möglich?

### 4. In vertikale Slices schneiden und priorisieren

- Ein Slice geht durch alle nötigen Schichten (Oberfläche, Schnittstelle, Domäne, Persistenz),
  ist einzeln testbar und auslieferbar und passt in einen Commit.
- Slices heißen SL1, SL2 … (nicht S1 – das kollidiert mit nummerierten Szenarien einer späteren
  Spezifikation). SL1 ist der kleinste durchgehende Durchstich, der das größte technische Risiko
  zuerst sichtbar macht.
- Bewerte jeden Slice mit hoch / mittel / niedrig nach **Business Value**, **technischem Risiko**
  und **Impact** (wie viel Bestehendes er berührt). Hoher Wert und hohes Risiko zuerst.
- Slices, die an einer offenen Frage hängen, bekommen den Verweis darauf und kommen nach hinten.
  Für sie wird nichts erfunden.

### 5. Ergebnis schreiben

Schreibe nach `docs/anforderungen/<thema>-klaerung.md` (`<thema>` in Kleinbuchstaben mit
Bindestrichen). Halte die Gliederung aus
[references/klaerung-vorlage.md](references/klaerung-vorlage.md) genau ein:

1. Entschieden
2. Offene Fragen an den Fachbereich
3. Ist / Soll mit Lücken und Chancen
4. Vertikale Slices, priorisiert (Tabelle)

Zum Schluss: Fasse in drei Sätzen zusammen, was entschieden ist, was offen ist und welcher Slice
als Erstes kommt. Weise darauf hin, dass offene Fragen vor dem betroffenen Slice beantwortet
werden müssen.
