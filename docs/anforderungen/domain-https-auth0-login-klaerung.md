# Klärung: Domain, HTTPS und Auth0-Login

- **Stand:** 2026-11-22
- **Beteiligt:** Auftraggeberin und Entwicklung
- **Ausgangsanforderung:** [Meilenstein 1 der Deployment-Roadmap](../roadmap.md#1-domain-https-und-auth0-login-einrichten)

## 1 Entschieden

| # | Entscheidung | Quelle |
|---|---|---|
| E1 | Die Auftraggeberin legt Testkonten in Auth0 an. Der Zugang steht ausschließlich ausdrücklich freigeschalteten Testpersonen offen. | Interview |
| E2 | Die Anmeldung startet auf der Angular-Startseite. Caddy leitet Login und OIDC-Callback an Spring Boot weiter. Spring Security verwaltet die Sitzung serverseitig. Nach erfolgreicher Anmeldung kehrt die Person zur App zurück und sieht „Angemeldet“ und „Abmelden“. Der Zustand ist nach dem Neuladen sichtbar, solange die Sitzung gültig ist. | Roadmap und Interview |
| E3 | `GET /api/me` liefert mit gültiger Sitzung HTTP 200 und ausschließlich Issuer und Subject. Spring Boot ermittelt beide Werte aus der serverseitigen Sitzung. Ohne gültige Sitzung antwortet der Endpunkt mit HTTP 401. OpenAPI beschreibt das Sitzungscookie und beide Antworten. Vertragstests prüfen beide Fälle. | Roadmap und Interview |
| E4 | Bei Abbruch oder Fehlschlag der Anmeldung kehrt die Person zur Startseite zurück, sieht einen kurzen Hinweis und kann die Anmeldung erneut starten. | Interview |
| E5 | Für Inaktivität gilt im Durchstich die Standarddauer von Spring Boot. | Interview |
| E6 | Die Abmeldung beendet die Sitzungen bei Knitventure und Auth0. Danach liefert `GET /api/me` im selben Browser HTTP 401. | Roadmap und Interview |
| E7 | Die erste Browserprüfung mit echtem Auth0 erfolgt über den lokalen Compose-Stack. Auf der produktiven HTTPS-Adresse folgt dieselbe Abnahme. Ein frisches Browserfenster ohne Sitzung erhält HTTP 401. | Roadmap und Interview |
| E8 | Die öffentliche Adresse von Knitventure ist `https://flingoflux.de`. | Auftraggeberin |

## 2 Offene Fragen an den Fachbereich

Keine fachlichen Fragen offen.

## 3 Ist / Soll

### Ist (aus Code und Dokumentation erhoben)

| Schritt | Oberfläche | Schnittstelle | Domäne / Beleg |
|---|---|---|---|
| 1. App öffnen | Angular zeigt die Willkommensseite und den Backend-Status. | Caddy liefert die SPA per HTTP über Port 80 aus und leitet `/api/status` an Spring Boot weiter. | [Angular](../../frontend/src/app/app.ts), [Caddyfile](../../frontend/Caddyfile), [Deployment-Compose](../../deploy/compose.yaml) |
| 2. Anmelden | Die Startseite bietet keine Anmeldung an. | Die Caddy-Weiterleitung erfasst `/api` und `/api/*`. | [Angular](../../frontend/src/app/), [Caddyfile](../../frontend/Caddyfile) |
| 3. Identität abrufen | Die Startseite zeigt den Backend-Buildstatus. | Die OpenAPI-Datei definiert `GET /api/status`. | [OpenAPI](../../api/openapi.yaml) |
| 4. Abmelden | Es gibt keine Abmeldefunktion. | Es gibt keinen Abmeldeablauf. | [Angular](../../frontend/src/app/), [Architekturbeschreibung](../arc42.md) |

### Soll

| Schritt | Oberfläche | Schnittstelle | Domäne / Betrieb |
|---|---|---|---|
| 1. App öffnen (**erweitert**) | Die Startseite ist unter `https://flingoflux.de` im Browser erreichbar. | Caddy leitet HTTP auf HTTPS um und liefert ein vom Browser akzeptiertes Zertifikat. | DNS verweist auf die Hetzner-VM. |
| 2. Anmelden (**neu**) | Die freigeschaltete Testperson startet den Login in Angular und kehrt nach der Anmeldung zurück. Bei Abbruch oder Fehler zeigt die Startseite einen kurzen Hinweis und ermöglicht einen erneuten Versuch. | Login und OIDC-Callback laufen über Caddy. | Auth0 bestätigt die Anmeldeidentität. Spring Security führt die Sitzung. |
| 3. Identität abrufen (**neu**) | Angular zeigt „Angemeldet“ und „Abmelden“ auch nach erneutem Laden mit gültiger Sitzung. | `GET /api/me` liefert HTTP 200 mit Issuer und Subject oder HTTP 401 ohne gültige Sitzung. | Die Identität stammt aus der serverseitigen Sitzung. Der OpenAPI-Vertrag und die Tests decken beide Antworten ab. |
| 4. Abmelden (**neu**) | Die Testperson meldet sich von der Startseite aus ab. | Danach antwortet `GET /api/me` mit HTTP 401. | Die Sitzungen bei Knitventure und Auth0 enden. |

### Lücken

- Produktion benötigt DNS, HTTPS und die zur Adresse passende Auth0-Konfiguration.
- Angular, Caddy und Spring Boot benötigen den gemeinsamen Login-Ablauf und die Behandlung fehlgeschlagener Anmeldungen.
- `GET /api/me`, sein OpenAPI-Vertrag und die Vertragstests fehlen.
- Die Abmeldung bei Knitventure und Auth0 muss über die Oberfläche ausgelöst und im Browser geprüft werden.

### Chancen

- Der lokale Browser-Test prüft früh, ob Caddy, OIDC und die serverseitige Sitzung zusammenspielen.
- Das bestätigte Paar aus Issuer und Subject bildet die Grundlage für die spätere Zuordnung zum Nutzerkonto.

## 4 Vertikale Slices, priorisiert

| Prio | Slice | Fertig, wenn (grob) | Business Value | Techn. Risiko | Impact | Hängt an |
|---|---|---|---|---|---|---|
| 1 | SL1 · Lokal anmelden und Identität abrufen | Ein freigeschaltetes Testkonto meldet sich im lokalen Compose-Stack aus Angular über Caddy und Auth0 an. Angular zeigt den Zustand auch nach dem Neuladen. Abbruch und Fehler erlauben einen erneuten Versuch. OpenAPI und Vertragstests decken HTTP 200 mit der Sitzungsidentität und HTTP 401 ohne Sitzung ab. | hoch | hoch | hoch | Testkonto und lokale Auth0-Konfiguration |
| 2 | SL2 · Bei Knitventure und Auth0 abmelden | Die Abmeldung über Angular beendet beide Sitzungen. Im selben Browser liefert `GET /api/me` danach HTTP 401. | hoch | mittel | mittel | SL1 |
| 3 | SL3 · Auf Hetzner über HTTPS bereitstellen und abnehmen | `flingoflux.de` zeigt auf die VM. HTTP leitet auf HTTPS um und das Zertifikat wird akzeptiert. Login, Neuladen und Abmeldung funktionieren in der bereitgestellten App. `GET /api/me` liefert die eigene Identität mit gültiger Sitzung und HTTP 401 in einem frischen Browserfenster sowie nach der Abmeldung. | hoch | hoch | hoch | SL2 |
