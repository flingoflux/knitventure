# Backend-Status über Caddy anzeigen

> Quellen [Klärungsdokument](../docs/anforderungen/spring-boot-caddy-klaerung.md) und [Klärung der Review-Befunde](../docs/anforderungen/backend-status-review-klaerung.md) · Stand 2026-11-22 · Status Entwurf
>
> Grundlage [ADR 0001](../docs/adr/0001-techstack-und-betriebsmodell.md) · [Slice-Plan](../docs/anforderungen/spring-boot-caddy-klaerung.md#4-vertikale-slices-priorisiert)

## Wozu

Wer Knitventure lokal öffnet, erkennt, ob das Backend erreichbar ist und ob dort ein lokaler Build läuft. Die Entwicklung kann den ersten durchgehenden Aufruf prüfen und Verstöße gegen den API-Vertrag oder die Backend-Architektur erkennen.

## Regeln

- **R1** Der lokale Compose-Stack stellt Spring Boot über Caddy unter `GET /api/status` ohne Anmeldung bereit. (E1)
- **R2** Bei Erfolg liefert der Endpunkt HTTP 200 mit Medientyp `application/json`. Das JSON-Objekt enthält ausschließlich `commitId` als Zeichenkette. Zulässige Werte sind `local` und eine vollständige Commit-ID mit 40 kleingeschriebenen Hexadezimalzeichen. (E2 der ursprünglichen Klärung, Review E3 und bestehender OpenAPI-Vertrag)
- **R3** Angular sendet beim Laden der Seite genau einen Statusabruf. (E1)
- **R4** Nach einem erfolgreichen Abruf zeigt Angular die Erreichbarkeit und den Wert aus `commitId` an. (E3)
- **R5** Bei fehlgeschlagenem Abruf zeigt Angular „Backend nicht erreichbar“ an. (E3)
- **R6** Eine versionierte OpenAPI-Datei im Repository beschreibt Methode, Pfad, HTTP 200, Medientyp und Antwortschema. (E2 und SL1)
- **R7** HTTP ist ein eingehender Adapter. Vorhandene Anwendung, Ports und Adapter sind mit jMolecules gekennzeichnet. (E4)
- **R8** ArchUnit prüft die Architektur im Maven-Testlauf und weist eine direkte Abhängigkeit des Anwendungskerns von einem Adapter zurück. (E4)
- **R9** Caddy liefert die Startseite, die referenzierten JavaScript- und CSS-Dateien sowie die Startdatei für direkte SPA-Aufrufe aus. *(Abgeleitet aus dem Soll für das Laden der Seite und den bestehenden HTTP-Prüfungen in der [CI](../.github/workflows/ci.yml).)*
- **R10** Maven hinterlegt den Build-Wert im Manifest des gepackten Backend-JARs. Ohne übergebene Commit-ID lautet der Build-Wert `local`. (Review E1)
- **R11** Das gepackte Backend meldet den gültigen Wert aus seinem eigenen Manifest. Änderungen an der Spring-Laufzeitkonfiguration lassen diesen Wert unverändert. (Review E1)
- **R12** Beim Start aus kompilierten Klassen meldet das Backend immer `local`. (Review E2)
- **R13** Fehlt der Wert im Manifest des gepackten Backend-JARs oder verletzt er den API-Vertrag, meldet das Backend `local` und protokolliert beim Start eine Warnung über das fehlende oder ungültige Build-Metadatum. (Review E3)
- **R14** Jeder Maven-Testlauf prüft das OpenAPI-Schema mit `local` und einer vollständigen Commit-ID unabhängig vom Build-Wert. Der HTTP-Test prüft weiterhin den Wert des laufenden Backends gegen den Vertrag. (Review E4)

## Akzeptanzszenarien

### A1 – Öffentlicher Statusabruf · R1, R2 · SL1

- **Given** Der lokale Compose-Stack läuft mit einem lokal gebauten Backend. Der Client hat keine Sitzung.
- **When** Der Client sendet `GET /api/status` an Caddy.
- **Then** Die Antwort ist HTTP 200 mit Medientyp `application/json` und dem JSON-Objekt `{"commitId":"local"}`.

### A2 – Ein Abruf pro Seitenladen · R3 · SL1

- **Given** Ein frisches Browserfenster und ein erreichbarer lokaler Compose-Stack.
- **When** Die Startseite wird geladen und bleibt nach Abschluss des Abrufs geöffnet.
- **Then** Angular sendet beim Laden genau einen `GET /api/status`. Ein erneutes Laden löst genau einen weiteren Abruf aus.

### A3 – Erreichbarkeit und Build anzeigen · R4 · SL1

- **Given** Angular erhält HTTP 200 mit `{"commitId":"local"}`.
- **When** Der Abruf ist abgeschlossen.
- **Then** Die Seite zeigt das Backend als erreichbar und den Wert `local` an.

### A4 – Backend-Ausfall anzeigen · R5 · SL1

- **Given** Caddy liefert die Startseite, und Spring Boot ist gestoppt.
- **When** Die Seite wird geladen und der Statusabruf schlägt fehl.
- **Then** Die Seite zeigt „Backend nicht erreichbar“ an.

### A5 – API-Vertrag abgleichen · R6 · SL1

- **Given** Die OpenAPI-Datei im Repository und die HTTP-Antwort aus A1.
- **When** Die Antwort wird gegen den Eintrag für `GET /api/status` geprüft.
- **Then** HTTP 200, `application/json` und das Objekt mit der erforderlichen Zeichenkette `commitId` stimmen mit dem Vertrag überein. Das Schema akzeptiert `local` und die vollständige Commit-ID eines veröffentlichten Builds, etwa `0123456789abcdef0123456789abcdef01234567`. Eine gleichartige Antwort mit leerem Objekt oder einem zusätzlichen Feld verletzt das Schema.

### A6 – Architekturkennzeichnung nachvollziehen · R7 · SL1

- **Given** Der Quellstand des laufenden Backends.
- **When** Die jMolecules-Kennzeichnung der Anwendung und der vorhandenen Ports und Adapter wird geprüft.
- **Then** Die Kennzeichnungen weisen die jeweiligen Rollen aus und ordnen den HTTP-Einstieg als eingehenden Adapter ein.

### A7 – Zulässige Architektur prüfen · R8 · SL1

- **Given** Der Stand von SL1 enthält keine direkte Abhängigkeit des Anwendungskerns von einem Adapter.
- **When** Der Maven-Testlauf wird ausgeführt.
- **Then** Der ArchUnit-Test läuft und meldet keinen Verstoß gegen diese Abhängigkeitsregel.

### A8 – Verbotene Abhängigkeit erkennen · R8 · SL1

- **Given** Eine temporäre, kompilierbare Änderung referenziert aus einer Klasse des Anwendungskerns direkt einen Adaptertyp.
- **When** Der gleiche Maven-Testlauf wie in A7 wird ausgeführt.
- **Then** Der Lauf endet mit einem Fehler des ArchUnit-Tests, der die eingefügte Abhängigkeit ausweist. Nach dem Entfernen der Änderung gilt wieder A7.

### A9 – Startseite ausliefern · R9 · SL1

- **Given** Caddy läuft im lokalen Compose-Stack.
- **When** Ein Client sendet `GET /`.
- **Then** Caddy liefert HTTP 200 mit der Startdatei, die „Willkommen bei Knitventure“ enthält.

### A10 – Assets ausliefern · R9 · SL1

- **Given** Die Startdatei referenziert mindestens eine JavaScript- und eine CSS-Datei.
- **When** Ein Client ruft die referenzierten Dateien über Caddy ab.
- **Then** Jede Anfrage liefert HTTP 200 mit einem nicht leeren Inhalt und einem Medientyp ungleich `text/html`.

### A11 – Direkten SPA-Aufruf bedienen · R9 · SL1

- **Given** Zu `/direkter-aufruf` existiert keine statische Datei.
- **When** Ein Client ruft den Pfad direkt über Caddy auf.
- **Then** Caddy liefert HTTP 200 und denselben Startdatei-Inhalt wie unter `/`.

### A12 – Lokalen Build-Wert paketieren · R10 · SL1

- **Given** Für den Maven-Build ist keine Commit-ID übergeben.
- **When** Maven paketiert das Backend-JAR.
- **Then** Das Manifest des Backend-JARs enthält `local` als Build-Wert.

### A13 – Manifest-ID bei Laufzeit-Override melden · R10, R11 · SL1

- **Given** Maven erhält beim Paketieren die Commit-ID `0123456789abcdef0123456789abcdef01234567`.
- **When** Das gepackte JAR startet mit dem Spring-Argument `--knitventure.build.commit-id=1111111111111111111111111111111111111111` und ein Client ruft `GET /api/status` ab.
- **Then** Das Manifest enthält den beim Paketieren übergebenen Wert und der Endpunkt antwortet mit HTTP 200 und `{"commitId":"0123456789abcdef0123456789abcdef01234567"}`.

### A14 – Aus kompilierten Klassen starten · R12 · SL1

- **Given** Das Backend wurde mit der Build-Commit-ID `0123456789abcdef0123456789abcdef01234567` kompiliert.
- **When** Das Backend startet direkt aus den kompilierten Klassen mit dem Spring-Argument `--knitventure.build.commit-id=1111111111111111111111111111111111111111` und ein Client ruft `GET /api/status` ab.
- **Then** Die Antwort ist HTTP 200 mit `{"commitId":"local"}`.

### A15 – Fehlenden Manifestwert behandeln · R13 · SL1

- **Given** Das Manifest des gepackten Backend-JARs enthält keinen Build-Wert.
- **When** Das JAR startet und ein Client ruft `GET /api/status` ab.
- **Then** Das Startprotokoll enthält eine Warnung zum fehlenden Build-Metadatum. Die Antwort ist HTTP 200 mit `{"commitId":"local"}`.

### A16 – Ungültigen Manifestwert behandeln · R13 · SL1

- **Given** Das Manifest des gepackten Backend-JARs enthält `bogus` als Build-Wert.
- **When** Das JAR startet und ein Client ruft `GET /api/status` ab.
- **Then** Das Startprotokoll enthält eine Warnung zum ungültigen Build-Metadatum. Die Antwort ist HTTP 200 mit `{"commitId":"local"}`.

### A17 – Beide zulässigen Werte bei jedem Testlauf prüfen · R14 · SL1

- **Given** Der OpenAPI-Vertrag und die Beispielantworten `{"commitId":"local"}` und `{"commitId":"0123456789abcdef0123456789abcdef01234567"}`.
- **When** Die Maven-Tests laufen.
- **Then** Derselbe Testlauf prüft beide Antworten gegen das Schema von `GET /api/status`. Schließt das Schema einen der beiden Werte aus, schlägt der Testlauf fehl.

### A18 – Tatsächliche HTTP-Antwort im Maven-Test prüfen · R14 · SL1

- **Given** Das Backend läuft für den HTTP-Test aus kompilierten Klassen.
- **When** Der Test ruft `GET /api/status` ab.
- **Then** Er bestätigt HTTP 200, den Medientyp `application/json` und die vertragsgemäße Antwort `{"commitId":"local"}`.

## Fertig, wenn

- [ ] `npm run build` im Verzeichnis `frontend/` endet mit Exitcode 0.
- [ ] A1 bis A6 sind am lokalen Compose-Stack, am API-Vertrag und am Backend-Quellstand nachvollziehbar.
- [ ] Der Maven-Testlauf führt den Architekturtest aus. A7 und A8 sind mit demselben Testlauf reproduzierbar, und die temporäre Verletzung ist aus dem Arbeitsstand entfernt.
- [ ] Bestehendes Verhalten unverändert gemäß A9 bis A11.
- [ ] A12 bis A16 sind am gepackten JAR beziehungsweise beim Start aus kompilierten Klassen anhand von Manifest, HTTP-Antwort und Startprotokoll überprüft.
- [ ] `mvn -f backend/pom.xml verify` im Repository-Stamm endet mit Exitcode 0 und führt die Schema- und HTTP-Prüfungen aus A17 und A18 aus.

## Offen (nicht Teil dieser Spezifikation)

| # | Frage | Wer klärt | Folge bis zur Klärung |
|---|---|---|---|
| O1 | Welcher lokale Compose-Aufruf wird nach der Einbindung des Backends dokumentiert? | Entwicklung | Die Abnahme beschreibt das beobachtbare Ergebnis am lokalen Stack. |

PR-CI und gemeinsames Deployment mit Rückwechsel sind im Slice-Plan als SL2 und SL3 vorgesehen.

## Slices

| Slice im Klärungsdokument | Szenarien |
|---|---|
| SL1 · Status vom Backend bis zur Angular-Seite | A1–A18, davon A12–A18 für die [Absicherung aus dem Review](../docs/anforderungen/backend-status-review-klaerung.md#4-vertikale-slices-priorisiert) |
