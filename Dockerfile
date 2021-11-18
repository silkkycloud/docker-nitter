ARG UID=991
ARG GID=991

####################################################################################################
## Builder
####################################################################################################
FROM nimlang/nim:alpine as builder

RUN apk add --no-cache \
    libsass-dev \
    libffi-dev \
    openssl-dev \
    redis \
    openssh-client \
    git

WORKDIR /nitter

RUN git clone https://github.com/zedeus/nitter.git /nitter

RUN nimble build -y -d:release --passC:"-flto" --passL:"-flto" \
    && strip -s nitter \
    && nimble scss

####################################################################################################
## Final image
####################################################################################################
FROM alpine:edge

ARG UID
ARG GID

RUN apk add --no-cache \
    pcre-dev \
    sqlite-dev \
    tini \
    curl \
    openssl \
    bash \
    sed

WORKDIR /nitter

COPY --from=builder /nitter/nitter .
COPY ./nitter.conf /nitter/nitter.conf

# Copy start script
COPY ./start.sh /nitter/start.sh
RUN chmod 777 /plerma/start.sh

# Add non-root user
RUN adduser -g $GID -u $UID --disabled-password --gecos "" nitter
RUN chown -R nitter:nitter /nitter

USER nitter

ENTRYPOINT ["/sbin/tini", "--", "/nitter/start.sh"]

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=15s \
    --interval=1m \
    CMD curl --fail http://localhost:8080/ || exit 1
