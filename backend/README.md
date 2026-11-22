# Knitventure-Backend

Voraussetzungen sind Java 21 und Maven. Die Befehle werden im Repository-Stamm ausgeführt.

```sh
mvn -f backend/pom.xml verify
mvn -f backend/pom.xml spring-boot:run
```

Ein Aufruf von `http://localhost:8080/api/status` liefert HTTP 200. Beim Start aus kompilierten
Klassen mit `spring-boot:run` lautet die Antwort `{"commitId":"local"}`. Der
[OpenAPI-Vertrag](../api/openapi.yaml) beschreibt die Antwort.

Maven setzt beim Paketieren den Manifest-Eintrag `Knitventure-Commit-Id` auf `local`. Für
einen veröffentlichten Build wird beim Paketieren die vollständige Commit-ID übergeben.

```sh
mvn -f backend/pom.xml clean verify -Dknitventure.commit-id="$(git rev-parse HEAD)"
java -jar backend/target/knitventure-backend-0.1.0-SNAPSHOT.jar
```

Das gepackte Backend meldet den Wert aus seinem Manifest. Bei fehlendem oder ungültigem
Wert protokolliert es beim Start eine Warnung und meldet `local`.
