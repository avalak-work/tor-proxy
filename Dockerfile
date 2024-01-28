## Dockerfile
## https://docker.github.io/engine/reference/builder/

FROM debian:bookworm-slim

RUN set -eux; \
    apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -yq \
    supervisor tor haproxy gosu obfs4proxy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ADD entrypoint.sh /opt/entrypoint.sh
RUN set -eux; \
  chmod +x /opt/entrypoint.sh

ENTRYPOINT [ "/opt/entrypoint.sh" ]
CMD [ ]
