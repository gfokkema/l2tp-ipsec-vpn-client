ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION}

ENV LANG C.UTF-8

RUN set -x && \
    apk add --no-cache \
              openrc \
              libreswan \
    && mkdir -p /var/run/pluto

COPY startup.sh /

CMD ["/startup.sh"]
