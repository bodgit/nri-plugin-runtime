FROM --platform=${BUILDPLATFORM} golang:1.27-alpine@sha256:eb61c3873c97416fff0116553fff65d67a3549f72e11d9758849a689cdd8b523 AS builder

ADD . /app
WORKDIR /app

ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-s -w" -o runtime ./cmd/runtime

FROM scratch

LABEL org.opencontainers.image.source="https://github.com/bodgit/nri-plugin-runtime"

COPY --from=builder /app/runtime /

ENTRYPOINT ["/runtime"]
