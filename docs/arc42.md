# Knitventure – Architekturbeschreibung nach arc42

## 1. Einführung und Ziele

Knitventure stellt derzeit eine Angular-Willkommensseite bereit. Der aktuelle Stand dient dazu, die Auslieferung auf der Hetzner-VM, automatisierte Updates und den Rückwechsel auf eine frühere Version zu erproben. Die [Deployment-Roadmap](roadmap.md) beschreibt den geplanten Durchstich.

## 2. Randbedingungen

Angular und TypeScript werden zu statischen Dateien gebaut. Das Produktionsimage wird für Linux/AMD64 erstellt und mit Docker Compose auf einer Hetzner-VM mit Ubuntu 24.04 LTS betrieben.

## 3. Kontextabgrenzung

Besucherinnen und Besucher rufen die Willkommensseite im Browser über HTTP auf. GitHub Actions, GitHub Container Registry (GHCR) und Tailscale sind externe Systeme für Build, Veröffentlichung und Deployment.

## 4. Lösungsstrategie

Caddy liefert die gebaute SPA aus. Ein mehrstufiger Docker-Build bündelt die statischen Dateien mit Caddy. Die CI prüft das Image vor der Veröffentlichung und versioniert es mit der vollständigen Commit-ID.

## 5. Bausteinsicht

| Baustein | Verantwortung |
| --- | --- |
| [Angular-Anwendung](../frontend/src/app/) | Willkommensseite und Backend-Status im Browser anzeigen |
| [Caddy](../frontend/Caddyfile) | Statische Dateien ausliefern, direkte SPA-Aufrufe bedienen und API-Anfragen an Spring Boot weiterleiten |
| [Spring Boot](../backend/) | Bekannte Build-Version über den [OpenAPI-Vertrag](../api/openapi.yaml) bereitstellen |
| [GitHub-Actions-Workflow](../.github/workflows/ci.yml) | Image-Paar bauen, prüfen, veröffentlichen und das Deployment anstoßen |
| [Deploy-Skript](../deploy/deploy.sh) | Image-Version auf der VM wechseln, per HTTP prüfen und bei einem Fehler die vorherige Version wieder starten |

## 6. Laufzeitsicht

- **Seitenaufruf.** Der Browser lädt die Startdatei sowie JavaScript und CSS von Caddy. Bei einem Pfad ohne zugehörige Datei liefert Caddy die Startdatei der SPA.
- **Update.** Nach einem erfolgreichen Push-Build auf `main` übergibt GitHub Actions die Commit-ID per SSH über Tailscale. Das Deploy-Skript lädt beide Images, startet Caddy und Spring Boot und übernimmt den Tag nach erfolgreichen HTTP-Checks von Startseite und API. Schlägt der Wechsel fehl, stellt es den in `.env` gespeicherten Stand wieder her.

## 7. Verteilungssicht

Die VM kann beide Images öffentlich aus GHCR abrufen. Die [Compose-Konfiguration](../deploy/compose.yaml) betreibt Caddy und Spring Boot. Caddy veröffentlicht Port 80 und bindet persistente Volumes für Daten und Konfiguration ein. Spring Boot ist über Caddy erreichbar. Der Browser führt die Angular-Anwendung aus.

Der [lokale Compose-Stack](../compose.yaml) baut beide Images aus dem Quellstand. Der erste gemeinsame Rollout auf Hetzner ist in der Roadmap dokumentiert.

## 8. Querschnittliche Konzepte

Die Commit-ID verbindet Quellstand, geprüftes Image und Deployment. Das Deploy-Skript serialisiert Updates per Dateisperre. Die [Frontend-README](../frontend/README.md#auf-hetzner-deployen-und-zurückwechseln) beschreibt den manuellen Rückwechsel.

## 9. Architekturentscheidungen

Die Abwägung zum Techstack und Betriebsmodell steht in [ADR-0001](adr/0001-techstack-und-betriebsmodell.md).

**Umgesetzt.** Statische Angular-Auslieferung über Caddy, ein Compose-Stack auf der VM und commitbasierte Releases.

**Für den Durchstich beschlossen.** Java, Spring Boot und Maven für das Backend, Auth0 per OpenID Connect für die Anmeldung und PostgreSQL für Nutzerkonten. Das Backend folgt einer hexagonalen Architektur mit jMolecules und ArchUnit. OpenAPI beschreibt den HTTP-Vertrag. Für die Modellierung verwenden wir Domain-Driven Design (DDD).

**Vorläufige Context-Grenze.** Der Bounded Context **Nutzerprofil** verantwortet die Profildaten in Knitventure. „Eigenes Profil bearbeiten“ ist ein Anwendungsfall in diesem Context. Für den Durchstich umfasst er das Anzeigen und Ändern des eigenen Avatars. Auth0 liefert die Identität für die Zuordnung zum lokalen Nutzerkonto. Bingo und Challenge werden später fachlich untersucht. Ihre Context-Grenzen bleiben offen.

## 10. Qualitätsanforderungen

Die CI prüft Caddy-Konfiguration, Startseite, JavaScript, CSS und SPA-Fallback. Beim ersten Deployment wurde geprüft, dass die Seite nach einem VM-Neustart wieder erreichbar ist. Update und Rückwechsel wurden im Betrieb erprobt.

## 11. Risiken und technische Schulden

Die Bereitstellung erfolgt über die Server-IP per HTTP. Domain und HTTPS sind offene Punkte der Roadmap und gehen dem produktiven Auth0-Login voraus.

## 12. Glossar

Die gemeinsame Fachsprache wird im [Glossar](glossar.md) gepflegt.
