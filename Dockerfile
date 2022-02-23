####################################################################################################
## Builder
####################################################################################################
FROM nimlang/nim:1.6.2-alpine-regular AS builder

RUN apk add --no-cache \
    ca-certificates \
    libsass-dev \
    pcre \
    git

WORKDIR /nitter

ADD https://api.github.com/repos/zedeus/nitter/git/refs/head /cachebreak
RUN git clone https://github.com/zedeus/nitter.git /nitter

RUN nimble install -y --depsOnly

RUN nimble build -d:danger -d:lto -d:strip \
    && nimble scss \
    && nimble md

####################################################################################################
## Final image
####################################################################################################
FROM alpine:3.15

RUN apk add --no-cache \
    ca-certificates \
    pcre \
    tini

WORKDIR /nitter

COPY --from=builder /nitter/nitter ./
COPY --from=builder /nitter/public ./public
COPY ./nitter.conf /nitter/nitter.conf

# Copy start script
COPY ./start.sh /nitter/start.sh
RUN chmod +x /nitter/start.sh

# Add an unprivileged user and set directory permissions
RUN adduser --disabled-password --gecos "" --no-create-home nitter \
    && chown -R nitter:nitter /nitter

ENTRYPOINT ["/sbin/tini", "--"]

USER nitter

CMD ["/nitter/start.sh"]

EXPOSE 8080

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=15s \
    --interval=1m \
    --timeout=3s \
    CMD wget --spider --q http://localhost:8080/settings || exit 1

# Image metadata
LABEL org.opencontainers.image.title=Nitter
LABEL org.opencontainers.image.description="Nitter is a alternative Twitter front-end focused on privacy."
LABEL org.opencontainers.image.url=https://nitter.silkky.cloud
LABEL org.opencontainers.image.vendor="Silkky.Cloud"
LABEL org.opencontainers.image.licenses=Unlicense
LABEL org.opencontainers.image.source="https://github.com/silkkycloud/docker-nitter"