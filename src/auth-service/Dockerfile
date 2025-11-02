FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY main.go go.mod ./
RUN go build -o /app/auth-service .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/auth-service .
EXPOSE 8080
CMD ["./auth-service"]