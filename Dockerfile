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
FROM alpine:3.14

RUN apk add --no-cache \
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

# Add non-root user
RUN adduser --disabled-password --gecos "" --no-create-home nitter
RUN chown -R nitter:nitter /nitter

USER nitter

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--", "/nitter/start.sh"]

STOPSIGNAL SIGTERM

HEALTHCHECK \
    --start-period=15s \
    --interval=1m \
    --timeout=3s \
    CMD wget --spider --q http://localhost:8080/settings || exit 1
