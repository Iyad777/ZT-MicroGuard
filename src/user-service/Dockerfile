# Use the official Go image to build the application
FROM golang:1.25-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy the source code
COPY main.go go.mod ./

# Build the application
RUN go build -o /app/user-service .

# Use a smaller base image for the final runtime
FROM alpine:latest

# Install necessary tools for debugging (optional, but useful)
RUN apk --no-cache add ca-certificates

# Set the working directory
WORKDIR /root/

# Copy the compiled application from the builder stage
COPY --from=builder /app/user-service .

# Expose the port the application runs on
EXPOSE 8080

# Run the executable
CMD ["./user-service"]