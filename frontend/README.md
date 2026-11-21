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

## Auf Hetzner deployen und zurückwechseln

Nach einem erfolgreichen Push-Build auf `main` startet der Workflow den Job `deploy`. Er übergibt die veröffentlichte Commit-ID per SSH an das Deployment-Skript auf der VM. Die VM zieht das Image und startet den Caddy-Container neu. Nach erfolgreichem HTTP-Test speichert das Skript die Commit-ID in `/opt/knitventure/.env`.

Für ein manuelles Update per SSH auf der VM ausführen und `<commit-id>` durch die vollständige ID eines veröffentlichten Images ersetzen.

```sh
/opt/knitventure/deploy.sh <commit-id>
```

Für einen Rückwechsel denselben Befehl mit der vorherigen Commit-ID ausführen. Bei einem fehlgeschlagenen Start oder HTTP-Test versucht das Skript, die in `.env` gespeicherte Version wiederherzustellen. Mit `docker compose ps` unter `/opt/knitventure` lässt sich das laufende Image prüfen. Die Seite ist unter http://138.201.187.224/ erreichbar.

Die Automatisierung verwendet das Repository-Secret `KNITVENTURE_DEPLOY_SSH_KEY`. Auf der VM ist dieser Schlüssel auf `/opt/knitventure/deploy.sh` beschränkt. Der SSH-Hostschlüssel liegt in [`deploy/known_hosts`](../deploy/known_hosts). Wenn sich das Deployment-Skript ändert, muss die aktualisierte Datei auf der VM unter `/opt/knitventure/deploy.sh` installiert werden.
