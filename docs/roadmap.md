# Deployment-Roadmap

Der technologische Durchstich ist erreicht, wenn sich eine Person auf der bereitgestellten Angular-App über Auth0 anmelden, ein eigenes Avatarbild hochladen und es nach einer erneuten Anmeldung wieder sehen kann. Angular spricht dafür über Caddy mit Spring Boot, das die Sitzung verwaltet und das Nutzerkonto in PostgreSQL speichert. Das Bild liegt in einem persistenten Volume und wird über die API ausgeliefert.

> Nach Abschluss jedes Meilensteins die Abnahmekriterien abhaken, das Prüfergebnis kurz festhalten, den Meilenstein unter „Erledigt“ zusammenfassen und die [Architekturbeschreibung](arc42.md) auf den neuen Ist-Stand bringen. Neue oder geänderte Fachbegriffe im [Glossar](glossar.md) nachführen.

## Nächste Meilensteine

### 1. Domain, HTTPS und Auth0-Login einrichten

- [ ] Die Domain zeigt auf die VM. Ein HTTP-Aufruf leitet auf HTTPS weiter und der Browser akzeptiert das von Caddy bereitgestellte Zertifikat.
- [ ] Aus Angular führt die Anmeldung über Auth0 zurück zur App. Login und OIDC-Callback laufen über Caddy, Spring Security verwaltet die Sitzung. Die App zeigt den angemeldeten Zustand auch nach dem Neuladen an.
- [ ] Der geschützte Endpunkt `/api/me` liefert mit gültiger Sitzung HTTP 200 und die eigene Identität. In einem frischen Browserfenster ohne Sitzung und nach der Abmeldung liefert derselbe Endpunkt HTTP 401.
- [ ] OpenAPI beschreibt `GET /api/me` mit Sitzungs-Cookie und den Antworten für HTTP 200 und 401. Die API-Tests prüfen beide Fälle gegen den Vertrag.

### 2. Nutzerkonten in PostgreSQL speichern

- [ ] PostgreSQL läuft als Compose-Dienst mit persistentem Volume. Die Migration erstellt auf einer leeren Datenbank genau eine Anwendungstabelle für Nutzerkonten. Ein erneuter Start mit derselben Datenbank gelingt.
- [ ] Die erste Anmeldung legt genau eine Zeile mit der eindeutigen OIDC-Identität aus Issuer und Subject an. Die erneute Anmeldung verwendet dieselbe Zeile. Ein zweites Auth0-Konto erhält eine eigene Zeile.
- [ ] Die CI prüft Migration und Kontoanlage gegen PostgreSQL. Auf der VM bleiben beide Konten nach dem Stoppen und erneuten Starten des Compose-Stacks erhalten.

### 3. Eigenes Avatarbild hochladen und anzeigen

- [ ] OpenAPI beschreibt Upload und Abruf des Avatars einschließlich Medientypen und Fehlerantworten. Die API-Tests prüfen erfolgreiche und abgewiesene Anfragen gegen den Vertrag.
- [ ] Angular lädt für das angemeldete Konto ein gültiges PNG- oder JPEG-Bild hoch und zeigt es anschließend an. Die API speichert das Bild im persistenten Volume und die Zuordnung in der Nutzerzeile.
- [ ] Die API weist ungültige oder zu große Uploads zurück. Ein zuvor gespeicherter Avatar bleibt dabei abrufbar. Ohne Sitzung liefert die API beim Hochladen und Abrufen HTTP 401. Ein zweites Konto kann den Avatar des ersten Kontos weder abrufen noch ändern.
- [ ] Auf der Hetzner-VM zeigt Angular nach Abmeldung, Neustart des Compose-Stacks und erneuter Anmeldung dasselbe Bild an.

### 4. Technisches GitHub-Konto für private Container-Images einrichten

- [ ] Ein separates technisches GitHub-Konto hat Lesezugriff auf die privaten GHCR-Pakete für Frontend und Backend. GitHub Actions kann beide Images veröffentlichen.
- [ ] Beide Images werden in privaten Paketen veröffentlicht. Für bereits öffentliche Pakete werden neue private Pakete angelegt.
- [ ] Die Hetzner-VM kann im Deployment-Kontext beide privaten Images und die vorgesehene Rückfallversion abrufen. Gemeinsames Deployment und Rückwechsel sind nach dem Paketwechsel geprüft.

## Erledigt

- [x] **Frontend containerisiert.** Caddy liefert die Angular-Willkommensseite aus. Lokaler Start und SPA-Fallback sind geprüft.
- [x] **Build und Veröffentlichung automatisiert.** GitHub Actions prüft das Frontend-Image und veröffentlicht auf `main` ein öffentliches, per Commit-ID versioniertes Image.
- [x] **Erstes Deployment auf Hetzner abgeschlossen.** Docker Compose betreibt Caddy auf der VM. Die Willkommensseite ist über die Server-IP erreichbar und wurde nach einem VM-Neustart geprüft.
- [x] **Updates automatisiert und Rückwechsel geprüft.** GitHub Actions deployt per SSH über Tailscale. Der manuelle Rückwechsel ist in der [Frontend-README](../frontend/README.md#auf-hetzner-deployen-und-zurückwechseln) dokumentiert.
- [x] <a name="1-spring-boot-über-caddy-bereitstellen-und-cicd-erweitern"></a> **Spring Boot bereitgestellt und CI/CD erweitert.** Caddy und Spring Boot laufen gemeinsam auf Hetzner. Die Angular-Statusanzeige, der gemeinsame CI-Build und der Rückwechsel sind geprüft. [GitHub-Actions-Lauf](https://github.com/flingoflux/knitventure/actions/runs/45072308454/attempts/2)
