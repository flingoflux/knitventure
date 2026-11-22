# Deployment-Roadmap

Der technologische Durchstich ist erreicht, wenn sich eine Person auf der bereitgestellten Angular-App über Auth0 anmelden, ein eigenes Avatarbild hochladen und es nach einer erneuten Anmeldung wieder sehen kann. Angular spricht dafür über Caddy mit Spring Boot, das die Sitzung verwaltet und das Nutzerkonto in PostgreSQL speichert. Das Bild liegt in einem persistenten Volume und wird über die API ausgeliefert.

> Nach Abschluss jedes Meilensteins die Abnahmekriterien abhaken, das Prüfergebnis kurz festhalten und die [Architekturbeschreibung](arc42.md) auf den neuen Ist-Stand bringen. Neue oder geänderte Fachbegriffe im [Glossar](glossar.md) nachführen.

## Erledigt

- [x] **Frontend containerisiert.** Caddy liefert die Angular-Willkommensseite aus. Lokaler Start und SPA-Fallback sind geprüft.
- [x] **Build und Veröffentlichung automatisiert.** GitHub Actions prüft das Frontend-Image und veröffentlicht auf `main` ein öffentliches, per Commit-ID versioniertes Image.
- [x] **Erstes Deployment auf Hetzner abgeschlossen.** Docker Compose betreibt Caddy auf der VM. Die Willkommensseite ist über die Server-IP erreichbar und wurde nach einem VM-Neustart geprüft.
- [x] **Updates automatisiert und Rückwechsel geprüft.** GitHub Actions deployt per SSH über Tailscale. Der manuelle Rückwechsel ist in der [Frontend-README](../frontend/README.md#auf-hetzner-deployen-und-zurückwechseln) dokumentiert.

## Nächste Meilensteine

### 1. Spring Boot über Caddy bereitstellen und CI/CD erweitern

- [x] Das Backend hexagonal strukturieren. HTTP ist ein eingehender Adapter. PostgreSQL und die Avatar-Dateiablage werden später als ausgehende Adapter angebunden. Der Anwendungskern greift über Ports auf sie zu. Der HTTP-Adapter greift über den eingehenden Status-Port auf die Anwendung zu. Der lokale Maven-Testlauf war erfolgreich (Commit `d68f6a7`).
- [ ] Anwendung, Ports und Adapter mit jMolecules kennzeichnen und ihre Abhängigkeiten mit ArchUnit prüfen. Die Tests laufen mit Maven in der PR-CI. Eine testweise direkte Abhängigkeit des Anwendungskerns von einem Adapter lässt den Architekturtest fehlschlagen.
  - Lokal geprüft: Der Maven-Testlauf prüft die jMolecules-Kennzeichnung und die Abhängigkeitsregel. Eine testweise direkte Abhängigkeit ließ den ArchUnit-Test fehlschlagen. Der Workflow führt den Maven-Testlauf aus. Die Abnahme durch einen gehosteten PR-Lauf steht aus.
- [ ] Eine versionierte OpenAPI-Datei als API-Vertrag im Repository ablegen und zunächst `GET /api/status` mit Statuscode, Medientyp und Antwortschema beschreiben. Die PR-CI validiert die Datei und prüft die Antwort über Caddy gegen den Vertrag. Eine ungültige Spezifikation oder eine vertragswidrige Antwort lässt den Workflow fehlschlagen.
  - Lokal geprüft: Der [OpenAPI-Vertrag](../api/openapi.yaml) beschreibt den Endpunkt. Der Maven-Test prüft beide zulässigen `commitId`-Varianten gegen das Schema und gleicht die direkte Backend-Antwort mit dem Vertrag ab. OpenAPI-Validierung und Vertragsprüfung gegen den lokalen Compose-Stack über Caddy waren erfolgreich. Die Abnahme im gehosteten PR-Lauf steht aus.
- [ ] Spring Boot mit Maven als Compose-Dienst ergänzen. Der Abruf von `/api/status` über Caddy liefert HTTP 200 mit der erwarteten JSON-Antwort. Angular zeigt den erfolgreich abgerufenen Status an. Startseite, Assets und SPA-Fallback bleiben über Caddy abrufbar.
  - Lokal geprüft: `docker compose up --build -d` startet beide Dienste. Caddy liefert Startseite, Assets, SPA-Fallback und `GET /api/status` mit `local` aus. Der Angular-Produktionsbuild war erfolgreich. Die Darstellung im Browser wurde nicht separat geprüft.
- [ ] Bei einem Pull Request baut die CI beide Images für `linux/amd64`, führt die Maven-Tests aus und prüft Caddy und API gemeinsam. Ein fehlgeschlagener Test macht den Workflow rot.
  - Beide `linux/amd64`-Images wurden lokal gebaut. Maven und der lokale HTTP-Vertragstest waren erfolgreich. Der gehostete PR-Lauf steht aus.
- [ ] Ein erfolgreicher Push auf `main` veröffentlicht beide geprüften Images öffentlich in GHCR mit derselben Commit-ID. GitHub Actions startet beide auf der VM. Das Deploy-Skript prüft Startseite und API über Caddy, bevor es den neuen Tag übernimmt. Bei einem absichtlich fehlschlagenden HTTP-Check stellt es das vorherige Image-Paar wieder her und meldet den Job als fehlgeschlagen.
  - Der isolierte Compose-Test hat den Rückfall auf Caddy beim ersten Fehler und auf das vorherige Image-Paar bei einem späteren Fehler bestätigt. Die erste gemeinsame Veröffentlichung in GHCR und der erfolgreiche Wechsel auf der VM stehen aus.

### 2. Domain, HTTPS und Auth0-Login einrichten

- [ ] Die Domain zeigt auf die VM. Ein HTTP-Aufruf leitet auf HTTPS weiter und der Browser akzeptiert das von Caddy bereitgestellte Zertifikat.
- [ ] Aus Angular führt die Anmeldung über Auth0 zurück zur App. Login und OIDC-Callback laufen über Caddy, Spring Security verwaltet die Sitzung. Die App zeigt den angemeldeten Zustand auch nach dem Neuladen an.
- [ ] Der geschützte Endpunkt `/api/me` liefert mit gültiger Sitzung HTTP 200 und die eigene Identität. In einem frischen Browserfenster ohne Sitzung und nach der Abmeldung liefert derselbe Endpunkt HTTP 401.
- [ ] OpenAPI beschreibt `GET /api/me` mit Sitzungs-Cookie und den Antworten für HTTP 200 und 401. Die API-Tests prüfen beide Fälle gegen den Vertrag.

### 3. Nutzerkonten in PostgreSQL speichern

- [ ] PostgreSQL läuft als Compose-Dienst mit persistentem Volume. Die Migration erstellt auf einer leeren Datenbank genau eine Anwendungstabelle für Nutzerkonten. Ein erneuter Start mit derselben Datenbank gelingt.
- [ ] Die erste Anmeldung legt genau eine Zeile mit der eindeutigen OIDC-Identität aus Issuer und Subject an. Die erneute Anmeldung verwendet dieselbe Zeile. Ein zweites Auth0-Konto erhält eine eigene Zeile.
- [ ] Die CI prüft Migration und Kontoanlage gegen PostgreSQL. Auf der VM bleiben beide Konten nach dem Stoppen und erneuten Starten des Compose-Stacks erhalten.

### 4. Eigenes Avatarbild hochladen und anzeigen

- [ ] OpenAPI beschreibt Upload und Abruf des Avatars einschließlich Medientypen und Fehlerantworten. Die API-Tests prüfen erfolgreiche und abgewiesene Anfragen gegen den Vertrag.
- [ ] Angular lädt für das angemeldete Konto ein gültiges PNG- oder JPEG-Bild hoch und zeigt es anschließend an. Die API speichert das Bild im persistenten Volume und die Zuordnung in der Nutzerzeile.
- [ ] Die API weist ungültige oder zu große Uploads zurück. Ein zuvor gespeicherter Avatar bleibt dabei abrufbar. Ohne Sitzung liefert die API beim Hochladen und Abrufen HTTP 401. Ein zweites Konto kann den Avatar des ersten Kontos weder abrufen noch ändern.
- [ ] Auf der Hetzner-VM zeigt Angular nach Abmeldung, Neustart des Compose-Stacks und erneuter Anmeldung dasselbe Bild an.

### 5. Technisches GitHub-Konto für private Container-Images einrichten

- [ ] Ein separates technisches GitHub-Konto hat Lesezugriff auf die privaten GHCR-Pakete für Frontend und Backend. GitHub Actions kann beide Images veröffentlichen.
- [ ] Beide Images werden in privaten Paketen veröffentlicht. Für bereits öffentliche Pakete werden neue private Pakete angelegt.
- [ ] Die Hetzner-VM kann im Deployment-Kontext beide privaten Images und die vorgesehene Rückfallversion abrufen. Gemeinsames Deployment und Rückwechsel sind nach dem Paketwechsel geprüft.
