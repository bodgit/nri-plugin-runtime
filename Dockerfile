FROM --platform=${BUILDPLATFORM} golang:1.26-alpine@sha256:27f2d3b83cfc5803c8078f8e730af0f7c431bf067afaec8f60a36fb763187cba AS builder

ADD . /app
WORKDIR /app

ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-s -w" -o runtime ./cmd/runtime

FROM scratch

LABEL org.opencontainers.image.source="https://github.com/bodgit/nri-plugin-runtime"

COPY --from=builder /app/runtime /

ENTRYPOINT ["/runtime"]
