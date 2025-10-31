# Build stage
FROM golang:alpine AS builder

WORKDIR /app

# Copy go mod and source code
COPY ./ .

# Download dependencies and build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a -installsuffix cgo -o main .

# Final stage
FROM gcr.io/distroless/static-debian11

WORKDIR /

# Copy binary from builder stage
COPY --from=builder /app/main .

# Expose port
EXPOSE 8080

# Run application
CMD ["./main"]
