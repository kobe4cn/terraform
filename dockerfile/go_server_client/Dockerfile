FROM golang:1.21 as builder
WORKDIR /src
COPY ./src .
RUN CGO_ENABLED=0 go build -o /bin/server ./server/tcp_server.go && \
    CGO_ENABLED=0 go build -o /bin/client ./client/tcp_client.go


# FROM ubuntu:jammy
FROM alpine:3.20.2 as server
COPY --from=builder /bin/server /bin/server
CMD ["/bin/server"]

FROM alpine:3.20.2 as client
COPY --from=builder /bin/client /bin/client
CMD ["/bin/client"]