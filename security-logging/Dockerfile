FROM golang:1.11-stretch AS builder

# Copy sources
WORKDIR $GOPATH/src/github.com/18F/gcp-appengine-template/security-logging
COPY . .

# install Cloud SDK
RUN curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-236.0.0-linux-x86_64.tar.gz | tar zxpf -

# Build binary
RUN CGO_ENABLED=0 go build

# Copy binary to alpine
FROM alpine:3.9
COPY --from=builder /go/src/github.com/18F/gcp-appengine-template/security-logging/security-logging /bin/security-logging
COPY --from=builder /go/src/github.com/18F/gcp-appengine-template/security-logging/google-cloud-sdk /google-cloud-sdk
RUN apk update && apk add python2

RUN addgroup -S -g 2000 securitylogging && adduser -S -u 2000 securitylogging -G securitylogging
USER securitylogging

ENV PATH="/google-cloud-sdk/bin:/usr/bin"
ENTRYPOINT ["/bin/security-logging"]
