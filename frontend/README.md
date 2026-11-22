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

## Frontend und Backend gemeinsam starten

Im Repository-Stamm ausführen.

```sh
docker compose up --build
```

Unter http://localhost:8080 zeigt Angular den Status über Caddy an. Ein lokaler Build meldet
`local`. Mit `Ctrl+C` stoppen, mit `docker compose down` aufräumen.

## CI/CD

Der [Workflow](../.github/workflows/ci.yml) baut beide Images für `linux/amd64` und führt Maven-
und ArchUnit-Tests aus. Er validiert OpenAPI und prüft die SPA sowie die API über Caddy.
Bei einem erfolgreichen Push auf `main` veröffentlicht er die geprüften Images unter derselben
vollständigen Commit-ID in GHCR. Er verwendet dafür `GITHUB_TOKEN` mit `packages: write`.

```sh
docker pull ghcr.io/flingoflux/knitventure:<commit-id>
docker pull ghcr.io/flingoflux/knitventure-backend:<commit-id>
```

GHCR legt ein neues Paket zunächst privat an. Nach der ersten Veröffentlichung muss ein
Paketadministrator das Backend-Paket auf **Public** setzen und den fehlgeschlagenen Workflow-Lauf
erneut starten. Der Workflow prüft den anonymen Zugriff auf beide Images vor dem Deployment.

## Auf Hetzner deployen und zurückwechseln

Nach einem erfolgreichen Push-Build auf `main` startet der Workflow den Job `deploy`. Er übergibt die veröffentlichte Commit-ID per SSH über Tailscale an das Deployment-Skript auf der VM. Die VM lädt die Images und startet Caddy und Spring Boot. Erst nach erfolgreichen HTTP-Checks für Startseite und API speichert das Skript Commit-ID und Backend-Status in `/opt/knitventure/.env`.

Für ein manuelles Update per SSH auf der VM ausführen und `<commit-id>` durch die vollständige ID eines veröffentlichten Image-Paars ersetzen.

```sh
/opt/knitventure/deploy.sh <commit-id>
```

Für einen manuellen Rückwechsel auf ein vorheriges Image-Paar denselben Befehl mit dessen Commit-ID ausführen. Bei einem fehlgeschlagenen ersten Backend-Deployment stellt das Skript Caddy wieder her und stoppt das Backend. Bei späteren Fehlern stellt es das zuletzt erfolgreiche Image-Paar wieder her. Mit `docker compose ps` unter `/opt/knitventure` lassen sich die laufenden Images prüfen. Die Seite ist unter http://138.201.187.224/ erreichbar.

Der Deployment-Job verbindet sich mit einer kurzlebigen OIDC-Identität und dem Tag `tag:knitventure-ci` mit dem Tailnet. Der Grant erlaubt TCP 22 zur VM mit `tag:knitventure-vm`. Das Repository-Secret `KNITVENTURE_TAILSCALE_DEPLOY_KEY` enthält den SSH-Schlüssel für `knitventure-deploy`. Der Schlüssel gilt für Tailscale-Quelladressen und führt ausschließlich `/opt/knitventure/deploy.sh` aus. Der SSH-Hostschlüssel liegt in [`deploy/known_hosts`](../deploy/known_hosts). Vor dem ersten gemeinsamen Deployment müssen die aktualisierten Dateien `deploy/compose.yaml` und `deploy/deploy.sh` auf der VM unter `/opt/knitventure/` installiert sein. Das Skript muss dort ausführbar sein. Die vorhandene `.env` mit dem bisherigen Caddy-Tag wird übernommen. Vor dem ersten Wechsel den bisherigen Caddy-Tag von der VM abrufen und nach dem erfolgreichen Deploy Startseite und API über Caddy prüfen.
