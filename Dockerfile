# Stage 1: Build

FROM maven:3.9.11-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copy Maven configuration first for better layer caching
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the Spring Boot JAR
RUN mvn clean package -DskipTests


# Stage 2: Runtime

FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Create a non-root user

RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

# Give ownership to non-root user & Copy only the generated JAR

COPY --from=builder --chown=appuser:appgroup \
    /app/target/hello-service.jar /app/hello-service.jar

USER appuser

# Application port

EXPOSE 8080

# Docker health check

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget -q -O - http://localhost:8080/health || exit 1

# Start application

ENTRYPOINT ["java", "-jar", "/app/hello-service.jar"]

