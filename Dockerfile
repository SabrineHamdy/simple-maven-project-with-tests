########Maven build stage########
FROM maven:3.6-jdk-11 as maven_build
WORKDIR /app

#copy pom
COPY pom.xml .

#resolve maven dependencies
RUN mvn clean package -Dmaven.test.skip -Dmaven.main.skip -Dspring-boot.repackage.skip && rm -r target/

#copy source
COPY src ./src

# build the app (no dependency download here)
RUN mvn clean package  -Dmaven.test.skip

# split the built app into multiple layers to improve layer rebuild
RUN mkdir -p target/docker-packaging && cd target/docker-packaging && jar -xf ../my-app*.jar

########JRE run stage########
FROM openjdk:11.0-jre
WORKDIR /app

#copy built app layer by layer
ARG DOCKER_PACKAGING_DIR=/app/target/docker-packaging
COPY --from=maven_build ${DOCKER_PACKAGING_DIR}/BOOT-INF/lib /app/lib
COPY --from=maven_build ${DOCKER_PACKAGING_DIR}/BOOT-INF/classes /app/classes
COPY --from=maven_build ${DOCKER_PACKAGING_DIR}/META-INF /app/META-INF

#run the app
CMD java -cp .:classes:lib/* \
         -Djava.security.egd=file:/dev/./urandom \
         foo.bar.MySpringBootApplication
