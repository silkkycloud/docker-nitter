####################################################################################################
## Builder
####################################################################################################
FROM nimlang/nim:alpine as builder

RUN apk add --no-cache \
    ca-certificates \
    libsass-dev \
    libffi-dev \
    openssl-dev \
    redis \
    openssh-client \
    git

WORKDIR /nitter

RUN --mount=type=cache,target=/tmp/git_cache \
    git clone https://github.com/zedeus/nitter.git /tmp/git_cache/nitter; \
    cd /tmp/git_cache/nitter \ 
    && git pull \
    && cp -r ./ /nitter

RUN nimble build -y -d:release --passC:"-flto" --passL:"-flto" \
    && strip -s nitter \
    && nimble scss

####################################################################################################
## Final image
####################################################################################################
FROM alpine:3.14

RUN apk add --no-cache \
    ca-certificates \
    pcre-dev \
    sqlite-dev \
    tini \
    openssl \
    bash \
    sed

WORKDIR /nitter

COPY --from=builder /nitter/nitter /nitter/start.sh /nitter/nitter.conf ./
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
