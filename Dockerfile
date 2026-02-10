FROM debian:bookworm-slim

ARG HAPI_VERSION=0.15.1
ARG TARGETARCH

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Download and install HAPI binary
RUN ARCH=$(case "${TARGETARCH}" in \
        "amd64") echo "x64" ;; \
        "arm64") echo "arm64" ;; \
        *) echo "x64" ;; \
    esac) && \
    curl -fsSL "https://github.com/tiann/hapi/releases/download/v${HAPI_VERSION}/hapi-linux-${ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/hapi

# Create non-root user 'claude' with fixed uid/gid for volume permission consistency
RUN groupadd -g 1000 claude && \
    useradd -m -s /bin/bash -u 1000 -g 1000 claude

# Create working directories
RUN mkdir -p /home/claude/.hapi /home/claude/data && \
    chown -R claude:claude /home/claude

USER claude
WORKDIR /home/claude

# HAPI configuration via environment variables
ENV HAPI_HOME=/home/claude/.hapi

ENTRYPOINT ["hapi"]
CMD ["runner", "start-sync"]
