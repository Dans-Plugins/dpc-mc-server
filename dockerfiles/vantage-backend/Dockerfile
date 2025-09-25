FROM openjdk:17-jdk-alpine

WORKDIR /app

# Copy gradle files
COPY vantage/backend/gradle ./gradle
COPY vantage/backend/gradlew vantage/backend/build.gradle vantage/backend/settings.gradle vantage/backend/gradle.properties ./

# Download dependencies
RUN ./gradlew dependencies --no-daemon

# Copy source code
COPY vantage/backend/src ./src

# Build the application
RUN ./gradlew shadowJar --no-daemon

# Expose port
EXPOSE 9000

# Run the application
CMD ["java", "-jar", "build/libs/backend-2.0.1-all.jar"]