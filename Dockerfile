# ── Stage 1: Extract backend binary from Antigravity (arch-aware) ──
FROM debian:trixie-slim AS ls-extractor

ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Both arches use the same version from Google's direct download
WORKDIR /extract
RUN if [ "$TARGETARCH" = "amd64" ]; then \
    curl -fsSL 'https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.18.3-4739469533380608/linux-x64/Antigravity.tar.gz' \
    -o /tmp/antigravity.tar.gz \
    && tar xzf /tmp/antigravity.tar.gz \
    -C /extract \
    --strip-components=0 \
    'Antigravity/resources/app/extensions/antigravity/bin/language_server_linux_x64' \
    'Antigravity/resources/app/product.json' \
    && cp /extract/Antigravity/resources/app/extensions/antigravity/bin/language_server_linux_x64 /ls_binary \
    && chmod +x /ls_binary \
    && mkdir -p /product && cp /extract/Antigravity/resources/app/product.json /product/ \
    && rm -rf /tmp/antigravity.tar.gz /extract/Antigravity; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
    curl -fsSL 'https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.18.3-4739469533380608/linux-arm/Antigravity.tar.gz' \
    -o /tmp/antigravity.tar.gz \
    && tar xzf /tmp/antigravity.tar.gz \
    -C /extract \
    --strip-components=0 \
    'Antigravity/resources/app/extensions/antigravity/bin/language_server_linux_arm' \
    'Antigravity/resources/app/product.json' \
    && cp /extract/Antigravity/resources/app/extensions/antigravity/bin/language_server_linux_arm /ls_binary \
    && chmod +x /ls_binary \
    && mkdir -p /product && cp /extract/Antigravity/resources/app/product.json /product/ \
    && rm -rf /tmp/antigravity.tar.gz /extract/Antigravity; \
    else \
    echo "Unsupported arch: $TARGETARCH" && exit 1; \
    fi

# ── Stage 2: Download prebuilt proxy binary (arch-aware) ──
FROM debian:trixie-slim AS downloader

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
    && curl -fsSL "$GH_RELEASE_URL/dns_redirect-linux-${ARCH_SUFFIX}.so" -o /dns_redirect.so \
    && chmod +x /zerogravity /zg

# ── Stage 3: Runtime ──
FROM debian:trixie-slim

ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
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

# Copy backend binary
COPY --from=ls-extractor /ls_binary /usr/local/bin/language_server_linux_x64

# Copy product.json so version auto-detection works (find_install_dir checks this path)
COPY --from=ls-extractor /product/product.json /usr/share/antigravity/resources/app/product.json

# Pre-compiled DNS redirect library — build_dns_redirect_so() detects this and skips gcc
COPY --from=downloader /dns_redirect.so /tmp/.agcache/libgthread-2.0.so.0

# Setup directories
RUN mkdir -p /root/.config/zerogravity \
    && mkdir -p /tmp/.agcache \
    && chmod 1777 /tmp/.agcache

EXPOSE 8741 443

# Auth: mount accounts.json for multi-account rotation, or set ZEROGRAVITY_ACCOUNTS env var
VOLUME ["/root/.config/zerogravity"]

ENV RUST_LOG=info
ENV ZEROGRAVITY_TOKEN=""
ENV ZEROGRAVITY_ACCOUNTS=""
ENV ZEROGRAVITY_API_KEY=""
ENV ZEROGRAVITY_LS_PATH="/usr/local/bin/language_server_linux_x64"

ENTRYPOINT ["zerogravity"]
CMD ["--headless", "--host", "0.0.0.0", "--mitm-port", "443"]
