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

- [x] Bestehende VM und Installation von Docker CE und Docker Compose prüfen oder einrichten.
- [x] SSH-Zugang und Firewall mit den benötigten Ports für SSH, HTTP und HTTPS einrichten.
- [x] Deployment-Verzeichnis mit `compose.yaml` und persistenten Caddy-Volumes anlegen.

Auf der VM `knitventure` (Ubuntu 24.04 LTS, AMD64) sind Docker CE 27.5.1 und Docker Compose 2.32.4 installiert. Docker läuft und startet beim Booten. UFW erlaubt TCP 22, 80 und 443 für IPv4 und IPv6. Der SSH-Zugang per Schlüssel wurde nach Aktivierung der Firewall erneut geprüft.

Die Datei [`deploy/compose.yaml`](../deploy/compose.yaml) liegt auf der VM unter `/opt/knitventure/compose.yaml`. Die Konfiguration wurde dort mit `docker compose config` und dem veröffentlichten Image-Tag aus Schritt 2 geprüft. Compose legt die persistenten Volumes für `/data` und `/config` beim ersten Start in Schritt 4 an. Die aktuelle Compose-Datei veröffentlicht Port 80. Die Container-Freigabe für Port 443 folgt mit der HTTPS-Konfiguration.

## 4. Erstes Deployment durchführen

- [x] Konkrete Image-Version per Docker Compose starten.
- [x] Willkommensseite über die Server-IP prüfen.
- [ ] Domain auf die VM zeigen lassen und Caddy für automatisches HTTPS konfigurieren.
- [x] Erreichbarkeit nach einem Neustart prüfen.

Als Erstes wurde das Image aus Schritt 2 auf der VM gestartet. Der laufende Tag steht in `/opt/knitventure/.env`. Die [Willkommensseite](http://138.201.187.224/) sowie JavaScript, CSS und der SPA-Fallback wurden über HTTP geprüft. Beide Caddy-Volumes wurden beim Start angelegt.

Nach einem Neustart der VM lief der Caddy-Container automatisch wieder und die Willkommensseite war über die Server-IP erreichbar. Domain und automatisches HTTPS sind vorerst zurückgestellt.

## 5. Updates und Rückwechsel festhalten

- [x] Eine neue Image-Version manuell per SSH deployen.
- [x] Rückwechsel auf eine vorherige Commit-Version prüfen.
- [x] Deployment-Befehle und Rückwechsel in der README dokumentieren.
- [ ] Deployment anschließend über GitHub Actions automatisieren.

Der [Workflow-Lauf 44948730197](https://github.com/flingoflux/knitventure/actions/runs/44948730197) veröffentlichte das Image mit Tag `197ab4c7598f9bf69ac96496d4a60fb826514731`. Geprüft wurden das Update auf diesen Tag, der Rückwechsel auf `5047fb6483f69d927c05a0491018724f230dee21` und das erneute Update. Bei jedem Wechsel wurden das laufende Image und die öffentliche Willkommensseite kontrolliert.

Die [Frontend-README](../frontend/README.md#auf-hetzner-deployen-und-zurückwechseln) beschreibt die Befehle und den SSH-Zugang für den Deployment-Job.
