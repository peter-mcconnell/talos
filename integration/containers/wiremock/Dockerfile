FROM java:openjdk-8-jdk-alpine

ENV WIREMOCK_PORT=80

# Get wiremock jar file
RUN apk add --update --no-cache curl && \
    curl --insecure -sSL https://repo1.maven.org/maven2/com/github/tomakehurst/wiremock-standalone/2.2.2/wiremock-standalone-2.2.2.jar -o /wiremock.jar

# Set wiremock as the entry point of the container
ENTRYPOINT java -Xms128m -Xmx128m -jar "/wiremock.jar" --port $WIREMOCK_PORT --verbose --container-threads 20 --jetty-acceptor-threads 4

# Expose port 80 from the container
EXPOSE $WIREMOCK_PORT
