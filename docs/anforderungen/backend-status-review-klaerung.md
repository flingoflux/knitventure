# Klärung: Commit-ID und Vertragstest für den Backend-Status

- **Stand:** 2026-11-22
- **Beteiligt:** Auftraggeberin und Entwicklung
- **Ausgangsanforderung:** Die beiden Review-Befunde zum Backend-Status klären. Grundlage ist die [SL1-Spezifikation](../../specs/spring-boot-caddy-status.md).

## 1 Entschieden

| # | Entscheidung | Quelle |
|---|---|---|
| E1 | Maven schreibt den Build-Wert in das Manifest des Backend-JARs. Das gepackte Backend liest den Wert aus seinem eigenen Manifest. Die Spring-Laufzeitkonfiguration kann ihn nicht überschreiben. | Interview und Review |
| E2 | Beim direkten Start aus kompilierten Klassen, etwa über `spring-boot:run`, meldet der Endpunkt immer `local`. | Interview |
| E3 | Fehlt der Wert im Manifest eines gepackten JARs oder entspricht er nicht dem API-Vertrag, meldet das Backend `local` und protokolliert beim Start eine Warnung. Ein gültiger Manifestwert ist `local` oder eine vollständige Commit-ID gemäß OpenAPI. | Interview und OpenAPI-Vertrag |
| E4 | Jeder Maven-Testlauf prüft das OpenAPI-Schema mit `local` und einer vollständigen Commit-ID. Der HTTP-Test prüft weiterhin den Wert des laufenden Backends. | Interview |

## 2 Offene Fragen an den Fachbereich

Keine.

## 3 Ist / Soll

### Ist (aus Code und Diagrammen erhoben)

| Schritt | Verhalten | Beleg |
|---|---|---|
| Build | Maven setzt standardmäßig `local` und übernimmt den Build-Wert in die Spring-Konfiguration. | [Maven-Projekt](../../backend/pom.xml), [Anwendungskonfiguration](../../backend/src/main/resources/application.properties) |
| Start und HTTP-Abruf | Das Backend liest eine überschreibbare Spring-Property. Der Endpunkt gibt den gelesenen Wert als `commitId` aus. | [Spring-Boot-Einstieg](../../backend/src/main/java/de/knitventure/backend/KnitventureBackend.java#L18), [HTTP-Adapter](../../backend/src/main/java/de/knitventure/backend/adapter/http/StatusController.java#L19) |
| Test | Der HTTP-Test prüft den aktuellen Wert gegen das Schema. Ein lokaler Lauf prüft damit nur `local`. | [HTTP-Test](../../backend/src/test/java/de/knitventure/backend/StatusHttpTest.java#L57), [OpenAPI-Vertrag](../../api/openapi.yaml) |

### Soll

| Schritt | Verhalten |
|---|---|
| Build (**geändert**) | Maven hinterlegt `local` für den lokalen Build beziehungsweise die übergebene vollständige Commit-ID im Manifest des gepackten JARs. |
| Start und HTTP-Abruf (**geändert**) | Das gepackte Backend liest den Wert aus seinem eigenen Manifest. Fehlt er dort oder ist er ungültig, meldet es `local` und protokolliert eine Warnung. Beim Start aus kompilierten Klassen meldet es `local`. |
| Test (**erweitert**) | Jeder Maven-Testlauf prüft beide Beispielwerte gegen das Schema. Die HTTP-Prüfung deckt weiterhin den tatsächlich ausgegebenen Wert ab. |

### Lücken

- Die Build-Metadaten sind derzeit Teil einer überschreibbaren Laufzeitkonfiguration.
- Der Schematest kann ein versehentliches Verbot des jeweils anderen gültigen Werts übersehen.

### Chancen

- Ein veröffentlichtes Backend bleibt seiner Build-Version zuordenbar.
- Ein einzelner Maven-Testlauf erkennt, wenn das Schema einen der beiden zulässigen Werte ausschließt.

## 4 Vertikale Slices, priorisiert

| Prio | Slice | Fertig, wenn (grob) | Business Value | Techn. Risiko | Impact | Hängt an |
|---|---|---|---|---|---|---|
| 1 | SL1 Backend-Status aus Build-Metadaten absichern | Ein gepacktes JAR meldet bei einem Laufzeit-Override weiterhin seine Manifest-ID. Ein gepacktes JAR mit fehlendem oder ungültigem Wert meldet `local` und warnt beim Start. Der Start aus kompilierten Klassen meldet `local`. Ein Maven-Testlauf prüft beide gültigen Schema-Beispiele und enthält weiterhin den HTTP-Test. | mittel | mittel | niedrig | – |
