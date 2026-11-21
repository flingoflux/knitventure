# Deployment-Roadmap

Ziel ist die Auslieferung der Angular-Willkommensseite auf der Hetzner-VM mit Docker Compose und Caddy. GitHub Actions baut und veröffentlicht versionierte Container-Images.

## 1. Frontend als Container vorbereiten

- [x] Mehrstufiges `frontend/Dockerfile` für Angular-Build und Caddy-Auslieferung anlegen.
- [x] Build-Kontext über `frontend/.dockerignore` begrenzen.
- [x] `frontend/Caddyfile` für statische Dateien und den SPA-Fallback auf `index.html` anlegen.
- [x] Image lokal bauen und Caddy-Konfiguration validieren.
- [x] Startseite, JavaScript, CSS und den Fallback per HTTP prüfen.
- [x] Lokale Build- und Startbefehle dokumentieren.

Lokal auf Docker Desktop (Linux/ARM64) geprüft. Die Container-Konfiguration verwendet für diesen Schritt HTTP auf Port 80. Domain und HTTPS folgen in Schritt 4.

## 2. Build über GitHub automatisieren

- [x] GitHub-Actions-Workflow für den Image-Build bei Pull Requests einrichten.
- [x] Bei Pushes auf `main` das Image nach `ghcr.io/flingoflux/knitventure` veröffentlichen.
- [x] Images mit der Commit-ID versionieren und für die Architektur der Hetzner-VM bauen.
- [x] Container-Paket öffentlich zugänglich machen und Abruf ohne Anmeldung prüfen.

Geprüft mit [Workflow-Lauf 44947214203](https://github.com/flingoflux/knitventure/actions/runs/44947214203). Das Image `ghcr.io/flingoflux/knitventure:5047fb6483f69d927c05a0491018724f230dee21` wurde erfolgreich für Linux/AMD64 gebaut, per HTTP geprüft, veröffentlicht und mit leerer Docker-Konfiguration anonym heruntergeladen. Die öffentliche Paketsichtbarkeit wurde kontrolliert.

## 3. Hetzner-VM vorbereiten

- [ ] Bestehende VM und Installation von Docker CE und Docker Compose prüfen oder einrichten.
- [ ] SSH-Zugang und Firewall mit den benötigten Ports für SSH, HTTP und HTTPS einrichten.
- [ ] Deployment-Verzeichnis mit `compose.yaml` und persistenten Caddy-Volumes anlegen.

## 4. Erstes Deployment durchführen

- [ ] Konkrete Image-Version per Docker Compose starten.
- [ ] Willkommensseite über die Server-IP prüfen.
- [ ] Domain auf die VM zeigen lassen und Caddy für automatisches HTTPS konfigurieren.
- [ ] Erreichbarkeit nach einem Neustart prüfen.

## 5. Updates und Rückwechsel festhalten

- [ ] Eine neue Image-Version manuell per SSH deployen.
- [ ] Rückwechsel auf eine vorherige Commit-Version prüfen.
- [ ] Deployment-Befehle und Rückwechsel in der README dokumentieren.
- [ ] Deployment anschließend über GitHub Actions automatisieren.
