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
