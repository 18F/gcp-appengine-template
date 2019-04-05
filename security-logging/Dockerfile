FROM golang:1.11-stretch AS builder

# Copy sources
WORKDIR $GOPATH/src/github.com/18F/gcp-appengine-template/security-logging
COPY . .

# install gsutil
RUN curl https://storage.googleapis.com/pub/gsutil.tar.gz | tar zxpf -

# Build binary
RUN CGO_ENABLED=0 go build

# Copy binary to alpine
FROM alpine:3.9
COPY --from=builder /go/src/github.com/18F/gcp-appengine-template/security-logging/security-logging /bin/security-logging
COPY --from=builder /go/src/github.com/18F/gcp-appengine-template/security-logging/gsutil /gsutil
RUN apk update && apk add python2

RUN addgroup -S -g 2000 logsync && adduser -S -u 2000 logsync -G logsync
USER logsync

ENV PATH="/gsutil:/usr/bin"
ENTRYPOINT ["/bin/security-logging"]
