# Klärung: Spring Boot über Caddy bereitstellen und CI/CD erweitern

- **Stand:** 2026-11-22
- **Beteiligt:** Auftraggeberin und Entwicklung
- **Ausgangsanforderung:** „Spring Boot über Caddy bereitstellen und CI/CD erweitern“ ([Roadmap, Meilenstein 1](../roadmap.md#1-spring-boot-über-caddy-bereitstellen-und-cicd-erweitern))

## 1 Entschieden

| # | Entscheidung | Quelle (wer, wann) |
|---|---|---|
| E1 | Beim Laden der Seite ruft Angular einmal `GET /api/status` über Caddy auf. Der Aufruf ist bereits vor Einführung der Anmeldung verfügbar. | Interview und Roadmap |
| E2 | HTTP 200 signalisiert, dass das Backend über Caddy erreichbar ist. Die Antwort mit Medientyp `application/json` enthält als einziges Feld `commitId` mit der vollständigen Commit-ID des Backend-Builds. Bei lokalen Builds lautet der Wert `local`. | Interview, Roadmap und anschließende Präzisierung |
| E3 | Angular zeigt bei Erfolg die Erreichbarkeit und den Wert aus `commitId` an. Bei fehlgeschlagenem Abruf erscheint „Backend nicht erreichbar“. | Interview |
| E4 | HTTP ist ein eingehender Adapter. jMolecules kennzeichnet Anwendung, Ports und Adapter. ArchUnit prüft die Abhängigkeiten im Maven-Testlauf. Eine testweise direkte Abhängigkeit vom Anwendungskern zu einem Adapter lässt den Test fehlschlagen. PostgreSQL und Avatar-Dateiablage folgen in späteren Meilensteinen. | Roadmap und AGENTS.md |
| E5 | Die PR-CI baut beide Images für `linux/amd64`, führt die Maven-Tests aus, validiert die versionierte OpenAPI-Datei und prüft die API-Antwort sowie Startseite, Assets und SPA-Fallback über Caddy. Fehler lassen die CI fehlschlagen. | Roadmap |
| E6 | Ein erfolgreicher Push auf `main` veröffentlicht beide geprüften Images mit derselben vollständigen Commit-ID und deployt sie gemeinsam. Das Deploy-Skript übernimmt den Tag nach erfolgreichen HTTP-Checks von Startseite und API. Bei fehlgeschlagenem Check stellt es das vorherige Image-Paar wieder her und meldet den Job als fehlgeschlagen. Die Commit-ID dient der Anzeige und ist kein Kriterium für die Übernahme des Tags. | Interview und Roadmap |

## 2 Offene Fragen an den Fachbereich

Für diesen Meilenstein sind keine fachlichen Fragen offen. Die technische Spezifikation konkretisiert, wie die Commit-ID in den Build gelangt und wie CI bzw. Deployment den HTTP-Check ausführen.

Die [ergänzende Klärung für Meilenstein 1](meilenstein-1-rest-klaerung.md) hält fest, wie die öffentlichen GHCR-Images bereitgestellt werden und welcher Stand beim ersten Backend-Deployment als Rückfallversion dient.

## 3 Ist / Soll

### Ist (aus Code und Diagrammen erhoben)

| Schritt | Oberfläche | Schnittstelle | Domäne / Beleg |
|---|---|---|---|
| 1. Seite laden | Angular zeigt die Willkommensseite. | Caddy liefert statische Dateien aus und leitet SPA-Pfade an die Startdatei weiter. | [Angular-Komponente](../../frontend/src/app/app.ts), [Caddyfile](../../frontend/Caddyfile) |
| 2. Backend-Status abrufen | Die Seite hat keinen Statusabruf. | Compose betreibt Caddy. | [Compose](../../deploy/compose.yaml), [Architekturbeschreibung](../arc42.md) |
| 3. Prüfen und deployen | Die CI prüft die statisch ausgelieferte Anwendung. | Auf `main` wird ein Frontend-Image per Commit-ID über Tailscale deployt. Das Skript prüft Caddy per HTTP und versucht bei einem Fehler, die vorherige Version wiederherzustellen. | [CI](../../.github/workflows/ci.yml), [Deploy-Skript](../../deploy/deploy.sh) |

### Soll

| Schritt | Oberfläche | Schnittstelle | Domäne / Betrieb |
|---|---|---|---|
| 1. Seite laden | Angular lädt die Seite wie bisher. | Caddy liefert Startseite, Assets und SPA-Fallback aus. | Compose betreibt zusätzlich Spring Boot. |
| 2. Backend-Status abrufen (**neu**) | Angular ruft beim Laden einmal den Status ab und zeigt die Erreichbarkeit mit dem Wert aus `commitId` oder den vereinbarten Fehlerhinweis. | Caddy leitet `GET /api/status` an Spring Boot weiter. Bei Erfolg liefert Spring Boot HTTP 200 und JSON mit `commitId`. | Das Backend liefert bei lokalen Builds `local` und bei veröffentlichten Builds die vollständige Commit-ID. Der HTTP-Adapter bindet den Anwendungskern an. |
| 3. Prüfen und deployen (**erweitert**) | Startseite, Assets und SPA-Fallback werden weiterhin geprüft. | Die PR-CI prüft zusätzlich die Architektur und den OpenAPI-Vertrag einschließlich der Antwort über Caddy. | Auf `main` veröffentlicht und deployt die CI das geprüfte Image-Paar. Der bestehende Rückwechsel wird auf beide Images erweitert. |

### Lücken

- Spring Boot, der Maven-Testlauf mit Architekturregeln und der versionierte API-Vertrag fehlen.
- Angular-Statusanzeige, Caddy-Proxy und Compose-Dienst für das Backend fehlen.
- CI und Deployment behandeln bisher ein Image. Vertragsprüfung, gemeinsame Versionierung sowie HTTP-Prüfung und Rückwechsel des Image-Paars fehlen.

### Chancen

- Der durchgehende Statusabruf prüft den Pfad vom Browser über Caddy bis zum Backend.
- Die sichtbare Commit-ID ordnet ein veröffentlichtes Backend einem Build zu. `local` kennzeichnet einen lokalen Build.
- Architektur- und Vertragsprüfungen greifen bereits beim ersten Endpunkt.

## 4 Vertikale Slices, priorisiert

| Prio | Slice | Fertig, wenn (grob) | Business Value | Techn. Risiko | Impact | Hängt an |
|---|---|---|---|---|---|---|
| 1 | SL1 Status vom Backend bis zur Angular-Seite | Der lokale Compose-Stack zeigt Erreichbarkeit und den Wert `local` an. Ein fehlgeschlagener Abruf zeigt den Fehlerhinweis. OpenAPI beschreibt die Antwort. Der Maven-Architekturtest erkennt eine testweise direkte Abhängigkeit des Kerns von einem Adapter. | hoch | hoch | mittel | – |
| 2 | SL2 Beide Images und den API-Vertrag in der PR-CI prüfen | Die PR-CI baut beide Images für `linux/amd64`, führt Maven-Tests aus und prüft Assets, SPA-Fallback und Vertrag über Caddy. Eine ungültige Spezifikation oder vertragswidrige Antwort macht den Workflow rot. | hoch | mittel | mittel | SL1 |
| 3 | SL3 Image-Paar auf der VM deployen und zurückwechseln | Ein Push auf `main` veröffentlicht und deployt beide geprüften Images mit derselben Commit-ID. Ein absichtlich fehlgeschlagener HTTP-Check führt zum Rückwechsel beider Images und einem fehlgeschlagenen Job. | hoch | hoch | hoch | SL2 |
