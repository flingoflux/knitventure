# Klärung: Meilenstein 1 abschließen

- **Stand:** 2026-11-22
- **Beteiligt:** Auftraggeberin und Entwicklung
- **Ausgangsanforderung:** Die verbleibenden Kriterien aus [Meilenstein 1 der Deployment-Roadmap](../roadmap.md#1-spring-boot-über-caddy-bereitstellen-und-cicd-erweitern) klären.

## 1 Entschieden

| # | Entscheidung | Quelle |
|---|---|---|
| E1 | Ein Compose-Befehl baut Caddy mit Angular und Spring Boot aus dem lokalen Quellstand und startet beide Dienste. Angular ruft beim Laden einmal `GET /api/status` über Caddy auf und zeigt bei Erfolg die Erreichbarkeit und `local` an. Bei einem fehlgeschlagenen Abruf erscheint „Backend nicht erreichbar“. Startseite, Assets und SPA-Fallback werden über Caddy ausgeliefert. | Interview und [SL1-Spezifikation](../../specs/spring-boot-caddy-status.md) |
| E2 | Die PR-CI baut beide Images für `linux/amd64`, führt die Maven-Tests einschließlich ArchUnit aus, validiert die OpenAPI-Datei und prüft die API-Antwort über Caddy gegen den Vertrag. Die bestehenden Prüfungen für Caddy, Startseite, Assets und SPA-Fallback laufen mit. Fehler lassen den Workflow fehlschlagen. | Roadmap und [ursprüngliche Klärung](spring-boot-caddy-klaerung.md) |
| E3 | Frontend und Backend werden in öffentlichen GHCR-Paketen bereitgestellt. Vor dem ersten Backend-Deployment wird geprüft, dass die VM beide Images und den bisherigen Caddy-Tag ohne Registry-Anmeldung abrufen kann. | Aktualisierte Entscheidung der Auftraggeberin |
| E4 | Ein erfolgreicher Push auf `main` veröffentlicht die beiden geprüften Images mit derselben vollständigen Commit-ID und deployt sie gemeinsam. Das Skript übernimmt den neuen Tag nach erfolgreichen HTTP-Checks von Startseite und API über Caddy. | Roadmap und ursprüngliche Klärung |
| E5 | Beim ersten Backend-Deployment ist die Rückfallversion der bisherige Caddy-Stand. Schlägt dieses Deployment fehl, stellt das Skript diesen Stand wieder her und stoppt den Backend-Dienst. Ab dem ersten erfolgreichen gemeinsamen Deployment stellt es bei einem späteren Fehler das vorherige Image-Paar wieder her. Der fehlgeschlagene Lauf meldet in beiden Fällen einen Fehler. | Interview und Roadmap |
| E6 | Der absichtlich fehlschlagende HTTP-Check läuft in einem isolierten Compose-Test mit demselben Deploy-Skript. Auf der Hetzner-VM wird der erfolgreiche Wechsel geprüft. | Interview |

## 2 Offene Fragen an den Fachbereich

Keine. Die konkreten Compose- und CI-Befehle gehören in die Umsetzung. Für die produktive Abnahme müssen die aktualisierte Compose-Datei und das Deploy-Skript auf der VM installiert sein. Die vorhandene SSH-Einbindung führt das bereits auf der VM installierte Skript aus.

Das technische GitHub-Konto und der Wechsel auf private GHCR-Pakete sind in [Meilenstein 5 der Roadmap](../roadmap.md#5-technisches-github-konto-für-private-container-images-einrichten) geplant.

## 3 Ist / Soll

### Ist (aus Code und Diagrammen erhoben)

| Schritt | Oberfläche | Schnittstelle | Domäne / Beleg |
|---|---|---|---|
| 1. Lokal starten und Status abrufen | Angular zeigt die Willkommensseite. | Caddy liefert die SPA aus. Spring Boot beantwortet den Statusabruf direkt. | [Caddyfile](../../frontend/Caddyfile), [Backend-README](../../backend/README.md), [Architekturbeschreibung](../arc42.md) |
| 2. Pull Request prüfen | Die CI prüft Startseite, JavaScript, CSS und SPA-Fallback. | Die CI baut das Frontend-Image für `linux/amd64`. | [Workflow](../../.github/workflows/ci.yml) |
| 3. Veröffentlichen, deployen und zurückwechseln | Caddy liefert die bereitgestellte Seite. | Das öffentliche Frontend-Image wird per Commit-ID veröffentlicht. Das Deployment startet Caddy und prüft die Startseite. | [Compose-Datei](../../deploy/compose.yaml), [Deploy-Skript](../../deploy/deploy.sh), [Betriebsanleitung](../../frontend/README.md#auf-hetzner-deployen-und-zurückwechseln) |

### Soll

| Schritt | Oberfläche | Schnittstelle | Betrieb |
|---|---|---|---|
| 1. Lokal starten und Status abrufen (**erweitert**) | Angular zeigt die Erreichbarkeit und `local` oder den vereinbarten Fehlerhinweis. | Caddy leitet den Statusabruf an Spring Boot weiter und liefert die SPA aus. | Ein Compose-Befehl baut und startet beide Dienste aus dem Quellstand. |
| 2. Pull Request prüfen (**erweitert**) | Die Prüfung der SPA bleibt Teil der CI. | Maven-Tests, OpenAPI-Validierung und Vertragsprüfung über Caddy laufen im Workflow. | Beide `linux/amd64`-Images werden gemeinsam geprüft. |
| 3. Veröffentlichen, deployen und zurückwechseln (**erweitert**) | Startseite und API werden nach dem Start über Caddy geprüft. | GHCR stellt beide geprüften Images öffentlich bereit. Die VM lädt sie ohne Registry-Anmeldung unter demselben Tag. | Beim ersten fehlgeschlagenen Wechsel gilt der Caddy-Stand als Rückfallversion. Bei späteren Fehlern gilt das zuletzt erfolgreiche Image-Paar. |

### Lücken

- Das Backend-Containerimage, der gemeinsame lokale Start, Caddys API-Weiterleitung und die Angular-Statusanzeige fehlen.
- Die CI muss Backend-Build, Maven- und Vertragsprüfungen in den Workflow aufnehmen.
- Das öffentliche Backend-Paket, das gemeinsame Deployment und beide Rückfallpfade müssen eingerichtet und geprüft werden.

### Chancen

- Die Entwicklung prüft den vollständigen HTTP-Pfad lokal mit einem Compose-Befehl.
- Der isolierte Rückwechseltest deckt die Migration und spätere Updates ohne absichtlichen Fehler auf der VM ab.

## 4 Vertikale Slices, priorisiert

| Prio | Slice | Fertig, wenn (grob) | Business Value | Techn. Risiko | Impact | Hängt an |
|---|---|---|---|---|---|---|
| 1 | SL1 abschließen · Lokaler Statusabruf über Caddy | Ein Compose-Befehl baut und startet beide Dienste. Angular zeigt den Status nach der bestehenden Spezifikation. Die SPA-Prüfungen sind grün. | hoch | mittel | mittel | – |
| 2 | SL2 · Beide Images und den API-Vertrag in der PR-CI prüfen | Der Workflow baut und prüft beide Images. Maven-Testfehler, eine ungültige OpenAPI-Datei und eine vertragswidrige Antwort führen jeweils zum Fehlschlag. | hoch | mittel | mittel | SL1 |
| 3 | SL3 · Öffentliche Images veröffentlichen und gemeinsam deployen | Die VM kann beide Images und die Caddy-Rückfallversion ohne Registry-Anmeldung laden. Der produktive Wechsel auf das geprüfte Image-Paar gelingt. Der isolierte Test bestätigt den Rückwechsel sowohl beim ersten als auch bei einem späteren fehlgeschlagenen HTTP-Check. | hoch | hoch | hoch | SL2 |
