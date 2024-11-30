FROM golang:1.21 as builder
WORKDIR /src
COPY ./examples .
RUN go mod tidy
RUN CGO_ENABLED=0 go build -o /bin/example ./main.go

# FROM ubuntu:jammy
FROM alpine:3.20.2
COPY --from=builder /bin/example /bin/example
CMD ["/bin/example"]