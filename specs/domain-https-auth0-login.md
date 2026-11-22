# Meilenstein 1 – Domain, HTTPS und Auth0-Login

> Quellen [Klärung](../docs/anforderungen/domain-https-auth0-login-klaerung.md) und [Deployment-Roadmap](../docs/roadmap.md#1-domain-https-und-auth0-login-einrichten) · Stand 2026-11-22 · Status Entwurf
>
> Grundlage [ADR 0001](../docs/adr/0001-techstack-und-betriebsmodell.md) · [Slice-Plan](../docs/anforderungen/domain-https-auth0-login-klaerung.md#4-vertikale-slices-priorisiert)

## Wozu

Freigeschaltete Testpersonen können sich bei Knitventure anmelden und erkennen ihren Anmeldestatus auch nach dem Neuladen. Die Entwicklung kann prüfen, dass Knitventure die bestätigte Anmeldeidentität einer gültigen Sitzung zuordnet. Der Betrieb kann den vollständigen Anmeldeablauf auf der öffentlich bereitgestellten App abnehmen.

## Regeln

- **R1** Zugang erhalten ausschließlich Testpersonen, deren Testkonten die Auftraggeberin in Auth0 angelegt und freigeschaltet hat. (E1)
- **R2** Die Anmeldung startet auf der Angular-Startseite und führt nach Erfolg dorthin zurück. Login und OIDC-Callback laufen über Caddy zu Spring Boot. Spring Security verwaltet die Sitzung serverseitig. (E2)
- **R3** Angular zeigt bei gültiger Sitzung „Angemeldet“ und „Abmelden“, auch nach dem Neuladen. (E2)
- **R4** `GET /api/me` liefert bei gültiger Sitzung HTTP 200 mit ausschließlich Issuer und Subject. Beide Werte stammen aus der serverseitigen Sitzung. (E3)
- **R5** `GET /api/me` liefert ohne gültige Sitzung HTTP 401. (E3)
- **R6** Die versionierte OpenAPI-Datei beschreibt für `GET /api/me` das Sitzungscookie und die Antworten HTTP 200 und 401. Vertragstests prüfen beide Antworten. (E3)
- **R7** Bei Abbruch oder Fehlschlag der Anmeldung führt der Ablauf zur Startseite zurück. Angular zeigt einen kurzen Hinweis und ermöglicht einen erneuten Anmeldeversuch. (E4)
- **R8** Bei Inaktivität gilt die Standard-Sitzungsdauer der eingesetzten Spring-Boot-Version. (E5)
- **R9** „Abmelden“ beendet die Sitzungen bei Knitventure und Auth0. (E6)
- **R10** Die öffentliche Adresse verweist auf die Hetzner-VM. Caddy leitet HTTP auf HTTPS um und liefert ein vom Browser akzeptiertes Zertifikat. (Roadmap)
- **R11** Die Browser-Abnahme mit echtem Auth0 läuft zuerst im lokalen Compose-Stack und anschließend auf der bereitgestellten HTTPS-App. (E7)
- **R12** Die Startseite und der Build-Status bleiben öffentlich erreichbar. Die Startseite zeigt weiterhin den Backend-Status. *(Abgeleitet aus der bestehenden öffentlichen Startseite mit Statusanzeige und dem dort startenden Login. [Angular](../frontend/src/app/app.html), [OpenAPI](../api/openapi.yaml), E2.)*

## Akzeptanzszenarien

### A1 – Startseite und Status ohne Sitzung abrufen · R12 · SL1

- **Given** Der lokal gebaute Compose-Stack läuft und der Browser hat keine Sitzung.
- **When** Die Person öffnet die Startseite.
- **Then** Die Startseite lädt mit HTTP 200. `GET /api/status` liefert HTTP 200 mit `{"commitId":"local"}`. Angular zeigt „Backend erreichbar“ und `local`.

### A2 – Mit freigeschaltetem Testkonto anmelden · R1, R2, R3 · SL1

- **Given** Der lokale Compose-Stack läuft mit Auth0-Konfiguration. Die Auftraggeberin hat ein Testkonto freigeschaltet.
- **When** Die Testperson startet die Anmeldung auf der Angular-Startseite und meldet sich bei Auth0 an.
- **Then** Der Browser kehrt über den von Caddy an Spring Boot weitergeleiteten OIDC-Callback zur Startseite zurück. Der Login-Aufruf und Callback sind im HTTP-Ablauf unter derselben App-Adresse nachvollziehbar. Spring Security führt eine serverseitige Sitzung. Angular zeigt „Angemeldet“ und „Abmelden“.

### A3 – Ohne freigeschaltetes Testkonto zugreifen · R1, R5 · SL1

- **Given** Ein Browser ohne Knitventure-Sitzung und eine Person ohne freigeschaltetes Testkonto.
- **When** Die Person versucht, sich über die App Zugang zu verschaffen.
- **Then** Der Versuch erzeugt keine gültige Knitventure-Sitzung. `GET /api/me` liefert HTTP 401.

### A4 – Startseite nach Anmeldung neu laden · R3 · SL1

- **Given** Eine Testperson hat eine gültige Knitventure-Sitzung.
- **When** Sie lädt die Startseite neu.
- **Then** Angular zeigt erneut „Angemeldet“ und „Abmelden“, ohne dass die Person erneut Anmeldedaten eingeben muss.

### A5 – Eigene Anmeldeidentität gegen OpenAPI prüfen · R4, R6 · SL1

- **Given** Eine gültige Sitzung für ein Testkonto mit bekanntem OIDC-Issuer und bekanntem Subject. Der OpenAPI-Eintrag für `GET /api/me` beschreibt das Sitzungscookie sowie HTTP 200 und 401.
- **When** Der Vertragstest ruft den Endpunkt mit dem Sitzungscookie auf.
- **Then** HTTP 200 und der Antwortinhalt entsprechen OpenAPI. Die Antwort enthält genau den Issuer und das Subject dieses Testkontos.

### A6 – Antwort ohne Sitzung gegen OpenAPI prüfen · R5, R6 · SL1

- **Given** Der Vertragstest hat kein Sitzungscookie und der Endpunkt dokumentiert HTTP 401.
- **When** Der Test ruft `GET /api/me` auf.
- **Then** Die Antwort ist HTTP 401 und entspricht dem OpenAPI-Eintrag für diesen Fall.

### A7 – Anmeldung abbrechen · R7 · SL1

- **Given** Eine Person hat die Anmeldung von der Startseite aus begonnen.
- **When** Sie bricht die Anmeldung ab und der Anmeldedienst meldet den Abbruch an die App zurück.
- **Then** Die Startseite erscheint mit einem kurzen Hinweis und der Möglichkeit, eine neue Anmeldung zu starten.

### A8 – Fehlgeschlagene Anmeldung erneut versuchen · R7 · SL1

- **Given** Die Anmeldung wurde von der Startseite aus begonnen.
- **When** Auth0 meldet einen Anmeldefehler an die App zurück.
- **Then** Die Startseite erscheint mit einem kurzen Hinweis. Die Person kann dort einen neuen Anmeldeversuch starten.

### A9 – Sitzung nach Inaktivität prüfen · R5, R8 · SL1

- **Given** Eine gültige Sitzung und die für die eingesetzte Spring-Boot-Version ermittelte Standarddauer bei Inaktivität.
- **When** Nach Ablauf dieser Dauer ohne Sitzungsaktivität wird `GET /api/me` mit dem bisherigen Cookie aufgerufen.
- **Then** Die Antwort ist HTTP 401.

### A10 – Bei Knitventure und Auth0 abmelden · R5, R9 · SL2

- **Given** Eine Testperson ist über Auth0 bei Knitventure angemeldet und hat eine aktive Auth0-Sitzung.
- **When** Sie wählt in Angular „Abmelden“.
- **Then** `GET /api/me` liefert im selben Browser HTTP 401. Ein erneuter Login im selben Browser erfordert eine neue Auth0-Anmeldung, da die bisherige Auth0-Sitzung beendet ist.

### A11 – HTTP auf HTTPS umleiten · R10 · SL3

- **Given** Die öffentliche App-Adresse ist im DNS auf die Hetzner-VM eingerichtet.
- **When** Ein Browser öffnet die Adresse über HTTP.
- **Then** Der Browser folgt der von Caddy gelieferten Weiterleitung zur HTTPS-Adresse und zeigt die Startseite ohne Zertifikatswarnung.

### A12 – Anmeldeablauf lokal und auf Hetzner abnehmen · R2–R5, R9, R11 · SL3

- **Given** Für den lokalen Compose-Stack und die öffentliche HTTPS-App sind die jeweils passenden Auth0-Einstellungen vorhanden.
- **When** Eine Testperson prüft den Ablauf zuerst lokal und anschließend auf Hetzner. Sie ruft `/api/me` ohne Sitzung in einem frischen Browserprofil auf, meldet sich an, lädt die Startseite neu und meldet sich ab.
- **Then** Beide Prüfungen ergeben der Reihe nach HTTP 401 ohne Sitzung, HTTP 200 mit der Identität des Testkontos, „Angemeldet“ nach dem Neuladen und HTTP 401 nach der Abmeldung. Login und OIDC-Callback laufen in beiden Umgebungen über Caddy.

## Fertig, wenn

- [ ] `npm run build` im Verzeichnis `frontend/` endet mit Exitcode 0.
- [ ] `mvn -f backend/pom.xml verify` im Repository-Stamm endet mit Exitcode 0 und führt die Architekturprüfung und die Vertragstests für A5 und A6 aus.
- [ ] `docker compose up --build` im Repository-Stamm startet mit lokaler Auth0-Konfiguration den Stack für die Browserprüfung.
- [ ] Bestehendes Verhalten unverändert gemäß A1. Die bestehenden CI-Prüfungen für Startseite, Assets, SPA-Fallback und `/api/status` sind grün.
- [ ] Das lokale Prüfprotokoll hält die Ergebnisse zu A2–A4 und A7–A10 fest. Für A9 enthält es die verwendete Spring-Boot-Version und die zugehörige Standarddauer.
- [ ] Das Hetzner-Prüfprotokoll enthält die Ergebnisse zu A11 und A12 einschließlich der Reihenfolge der Browser-Abnahmen.

## Offen (nicht Teil dieser Spezifikation)

| # | Frage | Wer klärt | Folge bis zur Klärung |
|---|---|---|---|
| O1 (F1 der Klärung) | Welche konkrete öffentliche Domain erhält Knitventure? | Auftraggeberin | Die konkrete DNS-Konfiguration, die produktiven Callback- und Abmeldeadressen sowie die Abnahme auf Hetzner warten auf diese Entscheidung. Die lokale Abnahme kann vorher erfolgen. |

## Slices

Die Reihenfolge folgt dem [Slice-Plan der Klärung](../docs/anforderungen/domain-https-auth0-login-klaerung.md#4-vertikale-slices-priorisiert).

| Slice | Szenarien |
|---|---|
| SL1 · Lokal anmelden und Identität abrufen | A1–A9 |
| SL2 · Bei Knitventure und Auth0 abmelden | A10 |
| SL3 · Auf Hetzner über HTTPS bereitstellen und abnehmen | A11–A12 |
