# Tor Proxy

[![workutils](https://img.shields.io/docker/pulls/workutils/tor-proxy.svg)](https://hub.docker.com/r/workutils/tor-proxy)
[![docker-image](https://github.com/avalak-work/tor-proxy/actions/workflows/build-image.yml/badge.svg)](https://github.com/avalak-work/tor-proxy/actions/workflows/build-image.yml)
[![shellcheck](https://github.com/avalak-work/tor-proxy/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/avalak-work/tor-proxy/actions/workflows/shellcheck.yml)

---

Docker based tor image

## Configuration

```
## Defaults
TOR_MAX_CIRCUIT_DIRTNESS: 300
TOR_PORT_BASE: 9060
TOR_PORT_AMOUNT: 20
TOR_EXPOSE_PORT: 0
TOR_HOSTNAME: $(hostname)
```

## Usage

## Ports

* `socks5://container:1080` - (`tcp`) used for SOCKS5 proxy
* `http://container:8404` - (`http`) used for stats and metrics (`/stats`, `/metrics`)

## Metrics

Prometheus ready

```yaml
## prometheus.yml
- job_name: 'haproxy'
  static_configs:
    - targets: [ 'container:8404' ]
```

## Links

* [RFC 1928](https://tools.ietf.org/html/rfc1928#section-3 "SOCKS Protocol Version 5 - Procedure for TCP-based clients")
