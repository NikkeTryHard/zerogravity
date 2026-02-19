# ── Stage 1: Extract LS binary from Antigravity .deb (amd64 only) ──
FROM debian:bookworm-slim AS ls-extractor

ARG TARGETARCH

# Add Google's Antigravity apt repo (only needed for amd64)
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o /etc/apt/keyrings/antigravity-repo-key.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
    > /etc/apt/sources.list.d/antigravity.list \
    && apt-get update \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Download .deb and extract only the LS binary (no full install)
# Pin to known-good version to prevent breakage from Google updates
WORKDIR /extract
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    apt-get update \
    && apt-get download antigravity=1.16.5-1770081357 \
    && dpkg-deb -x antigravity_*.deb extracted/ \
    && cp extracted/usr/share/antigravity/resources/app/extensions/antigravity/bin/language_server_linux_x64 /ls_binary \
    && chmod +x /ls_binary \
    && rm -rf /extract; \
    else \
    touch /ls_binary; \
    fi

# ── Stage 2: Download prebuilt proxy binary (arch-aware) ──
FROM debian:bookworm-slim AS downloader

ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

ARG GH_RELEASE_URL=https://github.com/NikkeTryHard/zerogravity/releases/latest/download

# Map Docker TARGETARCH to our release naming convention
RUN ARCH_SUFFIX=$(case "$TARGETARCH" in \
    amd64) echo "x86_64" ;; \
    arm64) echo "arm64" ;; \
    *) echo "x86_64" ;; \
    esac) \
    && curl -fsSL "$GH_RELEASE_URL/zerogravity-linux-${ARCH_SUFFIX}" -o /zerogravity \
    && curl -fsSL "$GH_RELEASE_URL/zg-linux-${ARCH_SUFFIX}" -o /zg \
    && chmod +x /zerogravity /zg

# ── Stage 3: Runtime ──
FROM debian:bookworm-slim

ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gcc \
    libc6-dev \
    sudo \
    procps \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Create system user for UID isolation
RUN useradd --system --no-create-home --shell /usr/sbin/nologin zerogravity-ls \
    && echo "root ALL=(zerogravity-ls) NOPASSWD: ALL" > /etc/sudoers.d/zerogravity \
    && chmod 0440 /etc/sudoers.d/zerogravity

# Copy binaries
COPY --from=downloader /zerogravity /usr/local/bin/zerogravity
COPY --from=downloader /zg /usr/local/bin/zg

# Copy LS binary — on amd64 this is the real binary from Google's .deb,
# on arm64 this is a placeholder (Google doesn't publish ARM LS binaries).
# ARM users must mount their own LS binary and set ZEROGRAVITY_LS_PATH.
COPY --from=ls-extractor /ls_binary /usr/local/bin/language_server_linux_x64

# Setup directories
RUN mkdir -p /root/.config/zerogravity \
    && mkdir -p /tmp/zerogravity-standalone \
    && chmod 1777 /tmp/zerogravity-standalone

EXPOSE 8741 8742

ENV RUST_LOG=info
ENV ZEROGRAVITY_TOKEN=""
ENV ZEROGRAVITY_UPSTREAM_PROXY=""
ENV ZEROGRAVITY_LS_PATH="/usr/local/bin/language_server_linux_x64"

ENTRYPOINT ["zerogravity"]
CMD ["--headless", "--host", "0.0.0.0"]
