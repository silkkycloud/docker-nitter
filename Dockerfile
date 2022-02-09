####################################################################################################
## Builder
####################################################################################################
FROM nimlang/nim:1.6.2-alpine AS builder

RUN apk add --no-cache \
    ca-certificates \
    libsass-dev \
    pcre

WORKDIR /nitter

# TODO: Fix Nitter version detection by using Git here.
ADD https://github.com/zedeus/nitter/archive/master.tar.gz /tmp/nitter-master.tar.gz
RUN tar xvfz /tmp/nitter-master.tar.gz -C /tmp \
    && cp -r /tmp/nitter-master/nitter.nimble /nitter

RUN nimble install -y --depsOnly

RUN cp -r /tmp/nitter-master/. /nitter

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
    tini \
    bash

WORKDIR /nitter

COPY --from=builder /nitter/nitter ./
COPY --from=builder /nitter/public ./public
COPY ./nitter.conf /nitter/nitter.conf

# Copy start script
COPY ./start.sh /nitter/start.sh
RUN chmod 777 /nitter/start.sh

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