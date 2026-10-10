FROM --platform=${BUILDPLATFORM} golang:1.27-alpine@sha256:f92b6ef800e499660581efdabdf25d9d817a9d124eaf900924f0504e7e27e12d AS builder

ADD . /app
WORKDIR /app

ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags="-s -w" -o runtime ./cmd/runtime

FROM scratch

LABEL org.opencontainers.image.source="https://github.com/bodgit/nri-plugin-runtime"

COPY --from=builder /app/runtime /

ENTRYPOINT ["/runtime"]
