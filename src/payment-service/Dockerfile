FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY main.go go.mod ./
RUN go build -o /app/payment-service .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/payment-service .
EXPOSE 8080
CMD ["./payment-service"]