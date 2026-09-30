FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /build
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY --from=build /build/target/sample-app-1.0.0.jar app.jar

ENV PORT=8080
EXPOSE 8080

USER 10001
ENTRYPOINT ["java", "-jar", "/app/app.jar"]




