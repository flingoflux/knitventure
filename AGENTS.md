# Deployment und Techstack

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
