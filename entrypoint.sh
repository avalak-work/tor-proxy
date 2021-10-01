#!/usr/bin/env sh
set -eu
#set -x

TOR_CONFIG=${TOR_CONFIG:-/etc/tor/torrc}
_TOR_HOST=$([ "${TOR_EXPOSE_PORT:-0}" = "1" ] && echo "0.0.0.0" || echo "127.0.0.1")
HAPROXY_CONFIG=${HAPROXY_CONFIG:-/etc/haproxy/haproxy.cfg}


populate_torrc () {
  max_circuit_dirtness=${TOR_MAX_CIRCUIT_DIRTNESS:-300}
  min_port=${TOR_PORT_BASE:-9060}
  amount=${TOR_PORT_AMOUNT:-20}

  cat << EOF
## /etc/tor/torrc
## man:torrc
## Generated at $(date --utc -Iseconds)

EOF

  echo "MaxCircuitDirtiness ${max_circuit_dirtness}"
  for port in $(seq "${min_port}" "$(( min_port + amount - 1 ))"); do
    echo "SOCKSPort ${_TOR_HOST}:${port}"
  done
}


populate_haproxy_cfg () {
  min_port=${TOR_PORT_BASE:-9060}
  amount=${TOR_PORT_AMOUNT:-20}

  cat << EOF
## /etc/haproxy/haproxy.cfg
## man:haproxy
## Generated at $(date --utc -Iseconds)

global
  user haproxy
  group haproxy

defaults
  mode http
  maxconn 500
  timeout client 3600s
  timeout connect 1s
  timeout queue 5s
  timeout server 3600s

frontend front_proxy
  bind *:1080
  mode tcp
  use_backend backend_proxy_pool

backend backend_proxy_pool
  mode tcp
  balance roundrobin
EOF

  for port in $(seq "${min_port}" "$(( min_port + amount - 1 ))"); do
    echo "  server $([ "${TOR_EXPOSE_PORT:-0}" = "1" ] || echo "_")tor_instance_${port} ${_TOR_HOST}:${port} check"
  done


## Add stats with native Prometheus support (HAProxy 2.0.0+)
cat << EOF
frontend stats
  bind *:8404
  option http-use-htx
  http-request use-service prometheus-exporter if { path /metrics }
  stats enable
  stats uri /stats
  stats refresh 10s
  stats uri /
EOF
}


populate_supervisord_config () {
  program_name=${1:?Program name REQUIRED}
  command_exec=${2:?Command REQUIRED}
  cat << EOF
[program:${program_name}]
command=${command_exec}
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
EOF
}


## Populate Supervisor services
mkdir /etc/supervisor.d/
populate_supervisord_config "haproxy" "/usr/sbin/haproxy -W -f \"${HAPROXY_CONFIG}\"" > /etc/supervisor.d/haproxy.ini
populate_supervisord_config "tor" "/usr/bin/tor" > /etc/supervisor.d/tor.ini

## Populate & validate HAProxy config
populate_haproxy_cfg > "${HAPROXY_CONFIG}"
haproxy -f "${HAPROXY_CONFIG}" -c && {
  echo "[OK] HAProxy config file valid"
}

## Populate & validate TOR config
populate_torrc > "${TOR_CONFIG}"
gosu tor /usr/bin/tor -f "${TOR_CONFIG}" --verify-config --hush && {
  echo "[OK] TOR config file valid"
}

#cat /etc/supervisord.conf

#exec gosu tor /usr/bin/tor -f "${TOR_CONFIG}" "${@}" &
#exec /usr/sbin/haproxy -W -f "${HAPROXY_CONFIG}"

PYTHONUNBUFFERED=1 exec /usr/bin/supervisord --nodaemon --configuration /etc/supervisord.conf "${@}"
