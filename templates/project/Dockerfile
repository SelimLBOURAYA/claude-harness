# Backend image. Delete this file on a frontend repository.
#
# P5-#18 — the image ships the artefact the tests actually ran on.
#
# There is no build stage here, on purpose. A `RUN ./mvnw package -DskipTests`
# stage produces a DIFFERENT jar from the one `./mvnw verify` validated: a
# different Maven version, a different local repository, a different resolution
# of every version range, and no tests. The image would then ship bytes nobody
# tested, while CI reported green on bytes nobody ships.
#
# So the jar is built once, by the validation job, and copied in:
#
#   ci.yml: validate  -> ./mvnw verify -> upload target/*.jar as "tested-artifact"
#           image-*   -> download it into the build context -> COPY below
#
# Building locally? Run the gate first, the COPY needs its output:
#   ./mvnw verify && docker build -t {{IMAGE_NAME}}:local .

FROM eclipse-temurin:21-jre-alpine

# Never root: a container that is compromised should not also be privileged.
RUN addgroup -S app && adduser -S -G app app

WORKDIR /app

# Exactly one jar is expected. A wildcard that silently matches two would make
# the last one win, which is not a decision anyone made.
COPY --chown=app:app target/*.jar /app/app.jar

USER app

EXPOSE 8080

# start_period covers JVM warm-up: without it the first probes fail and the
# orchestrator restarts a container that was merely starting.
HEALTHCHECK --interval=10s --timeout=3s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080{{HEALTH_PATH}} > /dev/null || exit 1

# No secret and no default for one: every value comes from the environment at
# run time (section 5).
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
