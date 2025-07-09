FROM --platform=${BUILDPLATFORM} golang:1.24-alpine@sha256:ddf52008bce1be455fe2b22d780b6693259aaf97b16383b6372f4b22dd33ad66 AS builder

ADD . /app
WORKDIR /app

ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-s -w" -o runtime ./cmd/runtime

FROM scratch

LABEL org.opencontainers.image.source="https://github.com/bodgit/nri-plugin-runtime"

COPY --from=builder /app/runtime /

ENTRYPOINT ["/runtime"]
