# ADR-0001 – Techstack und Betriebsmodell für Knitventure

- **Datum** 2026-11-22
- **Status** Proposed
- **Entscheidung von** Projektverantwortliche
- **Bezug** [arc42](../arc42.md)

## Kontext

Knitventure unterstützt eine jährliche Strickchallenge mit Projektplanung, Bingo und Foto-Uploads für eine kleine Gruppe. Angular und Auth0 sind Vorgaben für den Technologiestack. Die VM ist eingerichtet und der [Compose-Stack](../../deploy/compose.yaml) liefert bereits die Angular-Willkommensseite über Caddy aus. Der nächste Durchstich umfasst Login, persistentes Nutzerkonto und privaten Avatar.

**Frage** Mit welchem Anwendungsstack und Betriebsmodell setzen wir den Durchstich um?

## Entscheidungstreiber

1. Geringer Entwicklungs- und Integrationsaufwand.
2. Geschützter Zugriff auf Konten und Bilder mit Auth0 und serverseitiger Berechtigungsprüfung.
3. Erreichbarkeit nach längerer Nutzungspause ohne tarifbedingtes Aufwecken der App.
4. Überschaubare laufende Kosten und ein für eine kleine Gruppe tragbarer Betriebsaufwand.

## Optionen

### A – Spring Boot und PostgreSQL auf einer Hetzner-VM

Caddy liefert Angular aus und leitet API- und Login-Anfragen unter derselben Domain an Spring Boot weiter. PostgreSQL und die private Avatarablage laufen auf derselben VM. Auth0 bleibt extern.

- **Gewinn.** Etablierter Java- und Maven-Workflow, integrierte Login- und Sitzungsverwaltung mit Spring Security und eine dauerhaft laufende Anwendung.
- **Aufwand und Risiko.** Fixkosten für die VM und Verantwortung für Updates, Backups und Wiederherstellung. Ein VM-Ausfall betrifft die gesamte App.

### B – Angular und TypeScript-API auf Vercel mit Neon

Eine Hono-API hätte Neon und private Fotos angebunden. Für Auth0 wurden das Angular-SDK mit Access-Token im Arbeitsspeicher und eine Backend-Sitzung betrachtet. Für die Backend-Sitzung standen Neon als Sitzungsspeicher oder ein verschlüsseltes `HttpOnly`-Cookie zur Wahl. Express kam wegen der Auth0-Middleware für Login und Cookies infrage. NestJS war eine TypeScript-Alternative mit einer Spring und Angular ähnlichen Modulstruktur.

- **Gewinn.** Vercel übernimmt die Laufzeit. Ein verschlüsseltes Cookie spart eine Sitzungstabelle und deren Bereinigung.
- **Aufwand und Risiko.** Die Dienste und ihre Berechtigungen müssen zusammenspielen. Functions und Neon Free können nach Leerlauf zusätzliche Latenz verursachen. Eine kopierte Cookie-Sitzung bleibt bei rein clientseitiger Speicherung bis zum Ablauf nutzbar.

### C – Klassische Rust-API auf einer VM oder einem Webservice

Axum war die bevorzugte Rust-Option, Actix Web eine Alternative. Für eine klassische API kamen Hetzner und verwaltete Webservices infrage. Railway im Always-on-Tarif und Cloud Run mit Mindestinstanz hätten den VM-Betrieb abgenommen. Der Leerlauf von Render Free hätte auch eine Rust-API betroffen.

- **Gewinn.** Native Binärdatei und potenziell geringerer Ressourcenbedarf.
- **Aufwand und Risiko.** Einarbeitung in Cargo, Ownership und asynchronen Rust-Code sowie Integration von Datenbank und Authentifizierung. Always-on bei einem verwalteten Dienst hätte laufende Kosten verursacht.

### D – Kostenarmer Einstieg mit Cloudflare Workers

Für einen Start ohne Fixkosten waren Hono mit D1 sowie Rust mit `workers-rs` im Gespräch. Angular hätte auf Vercel bleiben können. Oracle Always Free wurde als VM-Alternative betrachtet, kann aber inaktive Gratis-Instanzen zurückfordern.

- **Gewinn.** Wenig Serverbetrieb bei Workers, schnelle Initialisierung und ein Einstieg innerhalb der Gratislimits.
- **Aufwand und Risiko.** D1 basiert auf SQLite und hat eigene Gratislimits. `workers-rs` setzt WebAssembly und kompatible Bibliotheken voraus.

### E – Minimalvariante mit dem bestehenden Frontend

Die Angular-Seite bleibt als statischer Prototyp auf der VM.

- **Gewinn.** Der vorhandene Deploy reicht für UI-Experimente.
- **Aufwand und Risiko.** Login, zentrale Konten und private Uploads bleiben offen. Damit scheitert die Variante an den Kriterien für den Durchstich.

### Vergleich

| Treiber | A · Spring/VM | B · Vercel/Neon | C · Rust | D · Workers | E · Prototyp |
| --- | --- | --- | --- | --- | --- |
| Entwicklungsaufwand | Gering durch integrierte Spring-Bausteine | Mittel durch Integration | Hoch durch Einarbeitung | Gering mit Hono, höher mit Rust | Gering für UI |
| Login und private Daten | Spring Security und API | SDK und API | Zusätzliche Integration | Zusätzliche Integration | Offen |
| Zugriff nach Leerlauf | App und DB laufen weiter | Kaltstart möglich | Tarifabhängig | Schnelle Initialisierung | Statische Seite |
| Kosten und Betrieb | VM-Fixkosten, Eigenbetrieb | Wenig Serverpflege, mehrere Dienste | Tarif- und Hosting-abhängig | Gratislimits, wenig Serverpflege | Bestehende VM |

## Entscheidung

Für den Durchstich kommt **Option A** zum Einsatz. Caddy liefert das Angular-Frontend aus. Caddy, das mit Maven gebaute Java-Backend auf Basis von Spring Boot und PostgreSQL laufen per Docker Compose auf dem gewählten Hetzner CX23 mit Ubuntu 24.04 LTS und Docker CE. Spring Security bindet Auth0 per OpenID Connect an und verwaltet die Sitzung serverseitig. Der Avatar liegt in einem persistenten Volume und wird über die geschützte API ausgeliefert.

### Begründung

Spring Security reduziert den Integrationsaufwand für Login und Sitzungsverwaltung. Ein Hostname für Frontend und API vereinfacht die Cookie-Sitzung. Die VM bietet zu einem festen Preis einen dauerhaft laufenden Backend-Prozess und lokalen Datenbankzugriff. Die zusätzliche Infrastrukturpflege ist für eine VM überschaubar. Vercel mit Neon würde diese Pflege reduzieren, hätte aber mehr Dienstgrenzen und mögliche Kaltstarts. Rust erhöht den Einarbeitungs- und Integrationsaufwand. Ein geringerer Ressourcenbedarf ist für den Durchstich kein entscheidender Treiber.

## Konsequenzen

- Angular und API können unter derselben öffentlichen Adresse deployt und geprüft werden. Eine Sitzung im Arbeitsspeicher reicht zunächst aus. Nach einem Backend-Neustart kann ein neuer Login nötig sein.
- Updates, Firewall, persistente Daten und externe Backups liegen in eigener Verantwortung. Datenbank und Fotos müssen gemeinsam wiederherstellbar sein.
- Domain und HTTPS gehen dem produktiven Auth0-Login voraus.

## Überprüfung

- `docker compose -f deploy/compose.yaml config` mit gesetztem Image-Tag prüft die Compose-Konfiguration. Die geplante CI prüft beide Images und `/api/status` über Caddy.
- Der Durchstich ist überprüfbar, wenn `/api/me` ohne Sitzung `401` liefert, Login und Avatar-Upload funktionieren und Nutzerkonto und Avatar nach einem Stack-Neustart erhalten bleiben.
- **Wiedervorlage, wenn** der VM-Betrieb dauerhaft zu viel Pflege erfordert, Neustarts die Nutzung stören oder mehrere Backend-Instanzen nötig werden.

## Verweise

- [arc42](../arc42.md)
- [Aktueller Compose-Stack](../../deploy/compose.yaml)
