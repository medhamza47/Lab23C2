FROM maven:3.9.11-eclipse-temurin-17 AS build
ARG MODULE
WORKDIR /app
COPY ${MODULE}/pom.xml .
RUN mvn -B dependency:go-offline
COPY ${MODULE}/src src
RUN mvn -B -DskipTests package && cp target/*.jar /service.jar

FROM eclipse-temurin:17-jre
COPY --from=build /service.jar /service.jar
ENTRYPOINT ["java", "-jar", "/service.jar"]
