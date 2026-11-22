FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml ./
COPY src ./src
ARG KNITVENTURE_COMMIT_ID=local
RUN mvn -B -ntp -Dmaven.test.skip=true -Dknitventure.commit-id="$KNITVENTURE_COMMIT_ID" package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/knitventure-backend-*.jar app.jar
USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
