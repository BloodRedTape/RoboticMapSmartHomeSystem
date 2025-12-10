FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o homekit-service .

FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/homekit-service .

ENV LISTEN_HOST=0.0.0.0
ENV LISTEN_PORT=5583
ENV BACKEND_URL=http://backend:8080
ENV STORAGE_PATH=/data

EXPOSE 5583

CMD ["./homekit-service"]
