# Deployment und Techstack

Die geplanten Schritte und ihr Fortschritt stehen in der [Deployment-Roadmap](docs/roadmap.md).

- Deployment auf einer Hetzner-Cloud-VM (CX23, Ubuntu 24.04 LTS mit Docker CE).
- Docker Compose betreibt Caddy, Spring Boot und PostgreSQL auf derselben VM.
- Angular (TypeScript) wird statisch von Caddy ausgeliefert. Caddy leitet API- und Login-Anfragen an Spring Boot weiter und übernimmt HTTPS, sobald eine Domain eingerichtet ist.
- Das Backend verwendet Java, Spring Boot und Maven. Spring Security bindet Auth0 per OpenID Connect an und verwaltet die Sitzung serverseitig.
- PostgreSQL speichert Challenge-Daten. Private Fotos liegen in persistentem Speicher auf der VM und werden über die API ausgeliefert.

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

# CI/CD

- `.github/workflows/ci.yml` baut bei Pull Requests, Pushes auf `main` und manuellen Starts das Frontend-Image für `linux/amd64`.
- Vor der Veröffentlichung werden Caddy-Konfiguration, Startseite, JavaScript, CSS und SPA-Fallback geprüft.
- Auf `main` wird das geprüfte Image als `ghcr.io/flingoflux/knitventure:<vollständige-commit-id>` veröffentlicht. Die Anmeldung erfolgt mit `GITHUB_TOKEN` und `packages: write`.
- Das Image ist öffentlich abrufbar. Nach einem erfolgreichen Push-Build auf `main` deployt GitHub Actions das geprüfte Image per SSH über Tailscale auf die Hetzner-VM.
