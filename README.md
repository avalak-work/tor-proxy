# Tor Proxy

[![shellcheck][workflow-image]][workflow-actions]
[![workutils](https://img.shields.io/docker/pulls/workutils/tor-proxy.svg)](https://hub.docker.com/r/workutils/tor-proxy)

---

Docker based tor image

## Configuration

```
## Defaults
TOR_MAX_CIRCUIT_DIRTNESS: 300
TOR_PORT_BASE: 9060
TOR_PORT_AMOUNT: 20
TOR_EXPOSE_PORT: 0
```

## Usage

## Ports

* `socks5://container:1080` - (`tcp`) used for SOCKS5 proxy
* `http://container:8404` - (`http`) used for stats and metrics

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

[workflow-image]: https://github.com/avalak-work/tor-proxy/workflows/shell-shellcheck/badge.svg "Shell Shellcheck"

[workflow-actions]: https://github.com/avalak-work/tor-proxy/actions?query=workflow%3Ashell-shellcheck
