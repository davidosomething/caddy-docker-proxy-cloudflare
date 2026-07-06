# ============================================================================
# Builder
# ============================================================================

# Pinned to an exact Caddy version for reproducible builds.
# Update the builder, runner, and ARG CADDY_VERSION together.
# caddy-docker issue history: https://github.com/caddyserver/caddy-docker/issues/307
FROM docker.io/library/caddy:2.11.4-builder-alpine AS builder

# read by `xcaddy build` command
ARG CADDY_VERSION=v2.11.4
# https://github.com/lucaslorentz/caddy-docker-proxy
# https://github.com/caddy-dns/cloudflare
RUN xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2@v2.13.1 \
    --with github.com/caddy-dns/cloudflare@v0.2.4

# ============================================================================
# Runner
# ============================================================================

FROM docker.io/library/caddy:2.11.4-alpine

# Create a non-root user to run Caddy (OWASP Docker Security Rule #7)
# Pin the caddy user to UID 1000 so bind-mounted host directories
# can be chown'd once predictably. GID 1000 for the group as well.
RUN addgroup -S -g 1000 caddy && adduser -S -D -u 1000 -h /data/caddy -s /sbin/nologin -G caddy -g caddy caddy

# Copy the built binary from the builder stage
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Ensure the binary is executable and owned by root (runs as non-root caddy user)
# Container-level CAP_NET_BIND_SERVICE is added in docker-compose instead of
# setcap file capabilities, which can cause "operation not permitted" on SELinux
# hosts when a non-root user executes a binary with security.capability xattrs.
RUN chmod 755 /usr/bin/caddy

# Ensure the caddy user owns its data and config directories
RUN chown -R caddy:caddy /data/caddy /config/caddy /etc/caddy

# OCI image labels for provenance
LABEL org.opencontainers.image.title="caddy-docker-proxy-cloudflare"
LABEL org.opencontainers.image.description="Caddy with docker-proxy and Cloudflare DNS modules"
LABEL org.opencontainers.image.source="https://github.com/caddy-dns/cloudflare"
LABEL org.opencontainers.image.vendor="davidosomething"

# Drop privileges — all subsequent instructions run as the caddy user
USER caddy

# Health check via Caddy's admin API
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["wget", "-O", "/dev/null", "http://localhost:2019/"]

CMD ["caddy", "docker-proxy"]
