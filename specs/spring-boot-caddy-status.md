# Meilenstein 1 – Backend-Status über Caddy bereitstellen

> Quellen [Klärungsdokument](../docs/anforderungen/spring-boot-caddy-klaerung.md) und [Klärung der Review-Befunde](../docs/anforderungen/backend-status-review-klaerung.md) und [Klärung der verbleibenden Kriterien](../docs/anforderungen/meilenstein-1-rest-klaerung.md) · Stand 2026-11-22 · Status Entwurf
>
> Grundlage [ADR 0001](../docs/adr/0001-techstack-und-betriebsmodell.md) · [Slice-Plan](../docs/anforderungen/spring-boot-caddy-klaerung.md#4-vertikale-slices-priorisiert)

## Wozu

Wer Knitventure lokal öffnet, erkennt, ob das Backend erreichbar ist und ob dort ein lokaler Build läuft. Die Entwicklung kann den ersten durchgehenden Aufruf prüfen und Verstöße gegen den API-Vertrag oder die Backend-Architektur erkennen. Der Betrieb kann geprüfte Versionen gemeinsam ausliefern und bei einem fehlerhaften Wechsel den zuletzt erfolgreichen Stand wiederherstellen.

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
- **R15** Ein dokumentierter lokaler Compose-Aufruf baut und startet Caddy mit Angular und Spring Boot aus dem lokalen Quellstand. (Restklärung E1)
- **R16** Die PR-CI baut die beiden Images für `linux/amd64` und prüft den Compose-Stack einschließlich Caddy-Konfiguration, Startseite, Assets und SPA-Fallback. (Restklärung E2)
- **R17** Die PR-CI führt die Maven-Tests einschließlich ArchUnit aus, validiert die versionierte OpenAPI-Datei und prüft die Antwort von `GET /api/status` über Caddy gegen den Vertrag. Jeder Fehler in diesen Prüfungen lässt den Workflow fehlschlagen. (Restklärung E2)
- **R18** Frontend und Backend werden in öffentlichen GHCR-Paketen bereitgestellt. Die VM kann beide Images und den bisherigen Caddy-Tag ohne Registry-Anmeldung abrufen. (Restklärung E3)
- **R19** Ein erfolgreicher Push-Build auf `main` veröffentlicht die beiden geprüften Images unter derselben vollständigen Commit-ID als Tag. Das Deployment startet beide Images dieser Version gemeinsam auf der VM. (Restklärung E4)
- **R20** Das Deploy-Skript übernimmt den neuen Tag erst nach erfolgreichen HTTP-Checks für Startseite und API über Caddy. (Restklärung E4)
- **R21** Scheitert das erste Backend-Deployment, stellt das Skript den bisherigen Caddy-Stand wieder her und stoppt den Backend-Dienst. Bei späteren Fehlern stellt es das zuletzt erfolgreiche Image-Paar wieder her. Der Deploy-Job endet in beiden Fällen mit Fehler. (Restklärung E5)
- **R22** Die absichtlich fehlschlagenden HTTP-Checks laufen mit demselben Deploy-Skript in einem isolierten Compose-Test. Auf der Hetzner-VM wird der erfolgreiche Wechsel geprüft. (Restklärung E6)

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

### A19 – Lokalen Stack aus dem Quellstand starten · R15 · SL1

- **Given** Ein ausgecheckter Quellstand ohne vorab gebaute Projektimages.
- **When** Die Entwicklung führt den dokumentierten lokalen Compose-Aufruf aus.
- **Then** Compose baut und startet beide Dienste, und `GET /api/status` über Caddy liefert HTTP 200 mit `{"commitId":"local"}`.

### A20 – Stack im Pull Request prüfen · R16, R17 · SL2

- **Given** Ein Pull Request mit gültigem Vertrag und bestandenen Maven-Tests.
- **When** Der Workflow baut und prüft den Stack.
- **Then** Beide Images sind für `linux/amd64` gebaut. Caddy-Konfiguration, Startseite, Assets, SPA-Fallback und die API-Antwort über Caddy bestehen die Prüfungen. Der Workflow endet erfolgreich.

### A21 – Architekturverletzung im Pull Request erkennen · R17 · SL2

- **Given** Der Anwendungskern referenziert testweise direkt einen Adapter.
- **When** Die PR-CI führt die Maven-Tests aus.
- **Then** ArchUnit meldet diese Abhängigkeit, und der Workflow endet mit Fehler.

### A22 – Ungültigen OpenAPI-Vertrag erkennen · R17 · SL2

- **Given** Die OpenAPI-Datei ist lesbares YAML, aber ihr Pflichtfeld `info` fehlt.
- **When** Die PR-CI validiert den Vertrag.
- **Then** Die OpenAPI-Validierung meldet einen Fehler, und der Workflow endet mit Fehler.

### A23 – Vertragswidrige Antwort über Caddy erkennen · R17 · SL2

- **Given** Die Maven-Tests sind grün und die OpenAPI-Datei ist gültig. Beim gemeinsamen HTTP-Test antwortet der Endpunkt über Caddy mit HTTP 200, `application/json` und `{}`.
- **When** Die PR-CI prüft die Antwort gegen den Vertrag.
- **Then** Die Vertragsprüfung meldet das fehlende Feld `commitId`, und der Workflow endet mit Fehler.

### A24 – Öffentliche Images und Rückfallversion abrufen · R18 · SL3

- **Given** Beide GHCR-Pakete sind öffentlich, und der bisherige Caddy-Tag ist gespeichert.
- **When** Die VM prüft vor dem ersten Backend-Deployment den Zugriff aus dem Deployment-Kontext.
- **Then** Sie lädt beide Images und den bisherigen Caddy-Tag ohne Registry-Anmeldung.

### A25 – Geprüfte Images gemeinsam veröffentlichen · R19 · SL3

- **Given** Ein erfolgreicher Push-Build auf `main` mit der Commit-ID `0123456789abcdef0123456789abcdef01234567`.
- **When** Der Workflow veröffentlicht die geprüften Images.
- **Then** Beide getesteten Images sind in ihren öffentlichen GHCR-Paketen unter dem Tag `0123456789abcdef0123456789abcdef01234567` abrufbar.

### A26 – Gemeinsames Deployment auf der VM übernehmen · R19, R20, R22 · SL3

- **Given** Beide öffentlichen Images derselben Commit-ID sind von der VM abrufbar.
- **When** GitHub Actions deployt den Tag auf der Hetzner-VM.
- **Then** Beide Dienste laufen mit dem neuen Tag. Startseite und `GET /api/status` liefern über Caddy HTTP 200. Der neue Tag ist erst nach den erfolgreichen HTTP-Checks als aktiver Stand gespeichert, und der Job endet erfolgreich.

### A27 – Beim ersten Deployment zu Caddy zurückwechseln · R20, R21, R22 · SL3

- **Given** Ein isolierter Compose-Test mit demselben Deploy-Skript und einem gespeicherten Caddy-Stand ohne Backend.
- **When** Beim ersten gemeinsamen Deployment schlägt der HTTP-Check der API absichtlich fehl.
- **Then** Caddy läuft wieder mit dem bisherigen Tag und liefert die Startseite mit HTTP 200. Der Backend-Dienst ist gestoppt, der gespeicherte Tag bleibt auf dem Caddy-Stand, und der Deploy-Lauf endet mit Fehler.

### A28 – Zum vorherigen Image-Paar zurückwechseln · R20, R21, R22 · SL3

- **Given** Ein isolierter Compose-Test mit demselben Deploy-Skript und einem zuletzt erfolgreich bereitgestellten Image-Paar.
- **When** Beim nächsten Deployment schlägt der HTTP-Check der API absichtlich fehl.
- **Then** Beide Dienste laufen wieder mit dem vorherigen gemeinsamen Tag. Startseite und API liefern HTTP 200 über Caddy, der gespeicherte Tag zeigt auf das vorherige Paar, und der Deploy-Lauf endet mit Fehler.

## Fertig, wenn

- [ ] `npm run build` im Verzeichnis `frontend/` endet mit Exitcode 0.
- [ ] A1 bis A6 sind am lokalen Compose-Stack, am API-Vertrag und am Backend-Quellstand nachvollziehbar.
- [ ] Der Maven-Testlauf führt den Architekturtest aus. A7 und A8 sind mit demselben Testlauf reproduzierbar, und die temporäre Verletzung ist aus dem Arbeitsstand entfernt.
- [ ] Bestehendes Verhalten unverändert gemäß A9 bis A11.
- [ ] A12 bis A16 sind am gepackten JAR beziehungsweise beim Start aus kompilierten Klassen anhand von Manifest, HTTP-Antwort und Startprotokoll überprüft.
- [ ] `mvn -f backend/pom.xml verify` im Repository-Stamm endet mit Exitcode 0 und führt die Schema- und HTTP-Prüfungen aus A17 und A18 aus.
- [ ] Der dokumentierte lokale Compose-Aufruf erfüllt A19.
- [ ] Die PR-Workflow-Läufe erfüllen A20 bis A23.
- [ ] GHCR-Zugriff und Veröffentlichung erfüllen A24 und A25. Der erfolgreiche Lauf auf der VM erfüllt A26, und der isolierte Compose-Test erfüllt A27 und A28.

## Offen (nicht Teil dieser Spezifikation)

Keine fachlichen Fragen. Der lokale Start ist in der [Frontend-README](../frontend/README.md#frontend-und-backend-gemeinsam-starten) dokumentiert. Die [CI](../.github/workflows/ci.yml) enthält die Prüfaufrufe.

Für die produktive Abnahme müssen die aktualisierte Compose-Datei und das Deploy-Skript auf der VM installiert sein.

## Slices

Zuordnung zum [Slice-Plan für die verbleibenden Kriterien](../docs/anforderungen/meilenstein-1-rest-klaerung.md#4-vertikale-slices-priorisiert).

| Slice im Klärungsdokument | Szenarien |
|---|---|
| SL1 · Status vom Backend bis zur Angular-Seite | A1–A19, davon A12–A18 für die [Absicherung aus dem Review](../docs/anforderungen/backend-status-review-klaerung.md#4-vertikale-slices-priorisiert) |
| SL2 · Beide Images und den API-Vertrag in der PR-CI prüfen | A20–A23 |
| SL3 · Öffentliche Images veröffentlichen und gemeinsam deployen | A24–A28 |
