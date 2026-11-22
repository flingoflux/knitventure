# Deployment und Techstack

Die geplanten Schritte und ihr Fortschritt stehen in der [Deployment-Roadmap](docs/roadmap.md). Der aktuelle Compose-Stack betreibt Caddy mit der Angular-Willkommensseite.

Nach jeder Umsetzung zu einem Roadmap-Meilenstein und vor dem Abschlussbericht oder Commit die Roadmap prüfen. Ein Kriterium abhaken, sobald es vollständig umgesetzt und geprüft ist. Bei teilweise erfüllten Kriterien den erreichten Stand, den Prüfnachweis und den offenen Teil direkt am Kriterium festhalten.

- Deployment auf einer Hetzner-Cloud-VM (CX23, Ubuntu 24.04 LTS mit Docker CE).
- Im Zielbild betreibt Docker Compose Caddy, Spring Boot und PostgreSQL auf derselben VM.
- Angular (TypeScript) wird statisch von Caddy ausgeliefert. Caddy leitet API- und Login-Anfragen an Spring Boot weiter und übernimmt HTTPS, sobald eine Domain eingerichtet ist.
- Das Backend verwendet Java, Spring Boot und Maven. Spring Security bindet Auth0 per OpenID Connect an und verwaltet die Sitzung serverseitig.
- Für den Durchstich speichert PostgreSQL Nutzerkonten. Avatarbilder liegen in einem persistenten Volume und werden über die geschützte API ausgeliefert.

# Backend-Architektur und API-Vertrag

- Das Spring-Boot-Backend ist hexagonal aufgebaut. HTTP ist ein eingehender Adapter. Der Anwendungskern bindet PostgreSQL und die Avatar-Dateiablage über ausgehende Ports an.
- Anwendung, Ports und Adapter mit jMolecules kennzeichnen und ihre Abhängigkeiten mit ArchUnit im Maven-Testlauf prüfen. Der Anwendungskern darf keine direkte Abhängigkeit von einem Adapter haben.
- Den HTTP-API-Vertrag als versionierte OpenAPI-Datei im Repository pflegen. Änderungen an HTTP-Endpunkten und ihren Antworten gemeinsam mit der Spezifikation und den Vertragstests aktualisieren.

# Frontend bauen und starten

Die Befehle werden im Verzeichnis `frontend/` ausgeführt. Voraussetzung ist Node.js 24.15 oder neuer innerhalb der Version 24 sowie npm.

Abhängigkeiten aus der Lockdatei installieren

```sh
cd frontend
npm ci
```

Lokalen Entwicklungsserver starten

```sh
npm start
```

Die Seite ist unter http://localhost:4200 erreichbar. Der Server wird mit `Ctrl+C` beendet.

Produktionsbuild erstellen

```sh
npm run build
```

Die statischen Dateien liegen danach unter `frontend/dist/knitventure/browser/`, relativ zum Repository-Stamm, und können von Caddy ausgeliefert werden.

# Frontend als Container

Die folgenden Befehle werden im Repository-Stamm ausgeführt und benötigen Docker.

```sh
docker build -t knitventure-frontend:local ./frontend
docker run --rm -p 127.0.0.1:8080:80 knitventure-frontend:local
```

Die Seite ist unter http://localhost:8080 erreichbar. Der Container wird mit `Ctrl+C` beendet.

# Gemeinsamer lokaler Stack und CI/CD

- `docker compose up --build` im Repository-Stamm baut und startet Caddy mit Angular und Spring Boot. Die Seite ist unter http://localhost:8080 erreichbar.
- `.github/workflows/ci.yml` baut beide Images für `linux/amd64` und prüft Maven, ArchUnit, OpenAPI, die SPA und die API über Caddy.
- Bei einem erfolgreichen Push auf `main` veröffentlicht GitHub Actions die geprüften Images in den öffentlichen GHCR-Paketen `ghcr.io/flingoflux/knitventure` und `ghcr.io/flingoflux/knitventure-backend` unter derselben vollständigen Commit-ID. Die Veröffentlichung verwendet `GITHUB_TOKEN` mit `packages: write`.
- GitHub Actions deployt das Image-Paar per SSH über Tailscale. Der [Rollout](frontend/README.md#auf-hetzner-deployen-und-zurückwechseln) beschreibt die Vorbereitung auf der VM.
