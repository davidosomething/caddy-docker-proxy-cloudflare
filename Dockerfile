# ============================================================================
# Builder
# ============================================================================

# Ideally you use the builder (a linux image) made for the specific caddy
# version, but it can probably build patch versions, too, if a builder version
# is missing.
# E.g. we can use 2.7.2 builder to build 2.7.3
# see https://github.com/caddyserver/caddy-docker/issues/307
ARG BUILDER_VERSION=2.7.4
ARG CADDY_VERSION=2.7.4

FROM caddy:${BUILDER_VERSION}-builder-alpine AS builder

# https://github.com/lucaslorentz/caddy-docker-proxy
# https://github.com/caddy-dns/cloudflare
RUN xcaddy build \
  --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
  --with github.com/caddy-dns/cloudflare \
  v${CADDY_VERSION}

# ============================================================================
# Runner
# ============================================================================

FROM caddy:${BUILDER_VERSION}-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
CMD ["caddy", "docker-proxy"]
