FROM eclipse-temurin:21-jre-jammy
WORKDIR /work/
COPY target/quarkus-app/lib/ ./lib/
COPY target/quarkus-app/app/ ./app/
COPY target/quarkus-app/quarkus/ ./quarkus/
COPY target/quarkus-app/quarkus-run.jar ./quarkus-run.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "quarkus-run.jar", "-Dquarkus.http.host=0.0.0.0"]
