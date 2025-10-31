# Build stage
FROM --platform=linux/arm64 golang:alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a -installsuffix cgo -o main .

# Final stage
FROM --platform=linux/arm64 gcr.io/distroless/static-debian11

WORKDIR /

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Expose port
EXPOSE 8080

# Run the application
CMD ["./main"]
