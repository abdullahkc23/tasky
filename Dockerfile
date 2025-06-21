# --- Build Stage ---
FROM golang:1.19 AS build

WORKDIR /go/src/tasky
COPY . .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /go/src/tasky/tasky

# --- Release Stage ---
FROM alpine:3.17.0 as release

WORKDIR /app

# Copy app binary and assets
COPY --from=build /go/src/tasky/tasky .
COPY --from=build /go/src/tasky/assets ./assets

# Explicitly copy wizexercise.txt
COPY wizexercise.txt /app/

# Add debug wrapper script
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'echo 🔍 MONGODB_URI: $MONGODB_URI' >> /app/start.sh && \
    echo 'echo "--- Environment ---"' >> /app/start.sh && \
    echo 'env' >> /app/start.sh && \
    echo 'echo "--- Listing /app directory ---"' >> /app/start.sh && \
    echo 'ls -l /app' >> /app/start.sh && \
    echo 'echo "📄 wizexercise.txt contents:"' >> /app/start.sh && \
    echo 'cat /app/wizexercise.txt || echo "❌ wizexercise.txt not found"' >> /app/start.sh && \
    echo 'echo "🕐 Sleeping for debug..."' >> /app/start.sh && \
    echo 'sleep 20' >> /app/start.sh && \
    echo 'echo "🚀 Launching Tasky..."' >> /app/start.sh && \
    echo './tasky' >> /app/start.sh && \
    chmod +x /app/start.sh


EXPOSE 8080
CMD ["/app/start.sh"]
