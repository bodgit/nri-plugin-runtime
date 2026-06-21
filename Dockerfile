FROM --platform=${BUILDPLATFORM} golang:1.26-alpine@sha256:3ad57304ad93bbec8548a0437ad9e06a455660655d9af011d58b993f6f615648 AS builder

ADD . /app
WORKDIR /app

ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-s -w" -o runtime ./cmd/runtime

FROM scratch

LABEL org.opencontainers.image.source="https://github.com/bodgit/nri-plugin-runtime"

COPY --from=builder /app/runtime /

ENTRYPOINT ["/runtime"]
