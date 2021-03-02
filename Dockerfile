## Dockerfile
## https://docker.github.io/engine/reference/builder/

FROM alpine:3
RUN set -eux; \
  apk --no-cache add tor

ENV TOR_CONFIG=/etc/tor/torrc

ADD entrypoint.sh /src/entrypoint.sh
#ADD torrc ${TOR_CONFIG}

ENTRYPOINT ["/bin/sh", "-c", "/src/entrypoint.sh"]
CMD ["-f", "${TOR_CONFIG}"]
