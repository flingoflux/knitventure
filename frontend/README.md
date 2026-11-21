# Knitventure Frontend

Die Willkommensseite verwendet Angular und TypeScript.

## Lokal starten

Voraussetzung ist Node.js 24.15 oder neuer innerhalb der Version 24 sowie npm.

```sh
cd frontend
npm ci
npm start
```

Die Seite ist unter http://localhost:4200 erreichbar.

## Produktionsbuild

```sh
npm run build
```

Die statischen Dateien liegen anschließend unter `dist/knitventure/browser/` und können von Caddy ausgeliefert werden.

## Container lokal starten

Mit Docker im Repository-Stamm ausführen

```sh
docker build -t knitventure-frontend:local ./frontend
docker run --rm -p 127.0.0.1:8080:80 knitventure-frontend:local
```

Die Willkommensseite ist unter http://localhost:8080 erreichbar. `Ctrl+C` beendet den Container und entfernt ihn. Das Image enthält Caddy und die gebauten statischen Dateien. Caddy liefert bei direkten Aufrufen von Angular-Routen die `index.html` aus.

Die weiteren Schritte stehen in der [Deployment-Roadmap](../docs/roadmap.md).

## GitHub Actions und Container Registry

Der Workflow `.github/workflows/ci.yml` baut bei Pull Requests und Pushes auf `main` ein Linux/AMD64-Image für die vorgesehene CX23-VM. Vor der Veröffentlichung prüft er die Caddy-Konfiguration, Startseite, statische Dateien und den SPA-Fallback. Auf `main` veröffentlicht er das geprüfte Image unter `ghcr.io/flingoflux/knitventure:<vollständige-commit-id>`. Er lässt sich auch manuell auf `main` starten.

Die Anmeldung verwendet den automatisch bereitgestellten `GITHUB_TOKEN` mit `packages: write`. Das Container-Paket ist öffentlich und kann von der VM anonym abgerufen werden. Die Sichtbarkeit lässt sich in den GitHub-Paketeinstellungen kontrollieren.

Ein öffentliches Image kann mit `docker pull ghcr.io/flingoflux/knitventure:<vollständige-commit-id>` heruntergeladen werden.
