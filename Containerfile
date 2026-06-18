FROM docker.io/debian:13 AS build

ARG TARGETARCH
ARG NODE_VERSION=24.17.0

RUN apt-get update && apt-get install -y curl ca-certificates tar gzip

RUN mkdir -p /dist/usr/local

RUN case "${TARGETARCH}" in \
    "amd64")  ARCH="x64" ;; \
    "arm64")  ARCH="arm64" ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    curl --retry 5 --retry-all-errors -fSsL \
    "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.gz" | \
    tar -xz -C /dist/usr/local --strip-components=1 --no-same-owner --wildcards "*/bin" "*/include" "*/lib" "*/share"

ENV PATH="/dist/usr/local/bin:$PATH"

RUN npm config set fetch-retries 10 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    for i in 1 2 3 4 5; do \
    npm i -g pnpm yarn snyk && break || \
    if [ "$i" -eq 5 ]; then echo "npm install failed after $i attempts"; exit 1; fi; \
    echo "npm install failed, retrying in 10s... ($i/5)"; sleep 10; \
    done

FROM scratch
COPY --from=build /dist /
