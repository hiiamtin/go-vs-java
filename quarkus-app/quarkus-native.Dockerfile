## Stage 1: provide the native runner produced outside of this build.
FROM scratch AS runner
COPY target/*-runner /application

## Stage 2: Minimal runtime image containing only the native binary.
FROM quay.io/quarkus/ubi9-quarkus-micro-image:2.0
WORKDIR /work/

# Ensure writable directory for the non-root user provided by the base image.
RUN chown 1001 /work \
    && chmod "g+rwX" /work \
    && chown 1001:root /work

COPY --from=runner --chown=1001:root --chmod=0755 /application /work/application

EXPOSE 8080
USER 1001

ENTRYPOINT ["./application", "-Dquarkus.http.host=0.0.0.0"]
