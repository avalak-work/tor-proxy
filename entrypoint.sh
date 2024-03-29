#!/usr/bin/env sh
# shellcheck disable=SC2039,SC3043
# Docs: https://github.com/koalaman/shellcheck/wiki/SC${CODE}
# SC2039 - In POSIX sh, something is undefined. (Deprecated; => SC3043)
# SC3043 - In POSIX sh, local is undefined.

set -eu
#set -x

TOR_CONFIG="${TOR_CONFIG:-/etc/tor/torrc}"
_TOR_HOST="$([ "${TOR_EXPOSE_PORT:-0}" = "1" ] && echo "0.0.0.0" || echo "127.0.0.1")"
_TOR_HOSTNAME="${TOR_HOSTNAME:-$(hostname)}"
HAPROXY_CONFIG="${HAPROXY_CONFIG:-/etc/haproxy/haproxy.cfg}"


show_usage () {
  cat << EOF
Usage: ${0##*/}

Description:

This is docker container entry point.
EOF
}


populate_torrc () {
  local max_circuit_dirtness="${TOR_MAX_CIRCUIT_DIRTNESS:-300}"
  local min_port="${TOR_PORT_BASE:-9060}"
  local amount="${TOR_PORT_AMOUNT:-20}"
  local bridge="${TOR_BRIDGE:-}"

  cat << EOF
# /etc/tor/torrc
# man:torrc
# Generated at $(date --utc -Iseconds)

EOF

  if [ -n "${bridge}" ]; then
    echo "UseBridges 1"
    echo "ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy managed"
    echo "Bridge ${bridge}"
  fi

  echo "MaxCircuitDirtiness ${max_circuit_dirtness}"
  for port in $(seq "${min_port}" "$(( min_port + amount - 1 ))"); do
    echo "SOCKSPort ${_TOR_HOST}:${port}"
  done
}


populate_haproxy_cfg () {
  local min_port="${TOR_PORT_BASE:-9060}"
  local amount="${TOR_PORT_AMOUNT:-20}"

  cat << EOF
# /etc/haproxy/haproxy.cfg
# man:haproxy
# Generated at $(date --utc -Iseconds)

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
    echo "  server $([ "${TOR_EXPOSE_PORT:-0}" = "1" ] || echo "_")tor_${_TOR_HOSTNAME}_${port} ${_TOR_HOST}:${port} check"
  done


## Add stats with native Prometheus support (HAProxy 2.0.0+)
cat << EOF
frontend stats
  bind *:8404
  http-request use-service prometheus-exporter if { path /metrics }
  stats enable
  stats uri /stats
  stats refresh 10s
  stats uri /
EOF
}


populate_supervisord_config () {
  local program_name="${1:?Program name REQUIRED}"
  local command_exec="${2:?Command REQUIRED}"
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

if [ ! -f "/etc/supervisord.conf" ]; then
  cat << EOF > /etc/supervisord.conf
# /etc/supervisord
# man:supervisord
# Generated at $(date --utc -Iseconds)

[unix_http_server]
file=/run/supervisord.sock

[supervisord]
logfile=/var/log/supervisord.log

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///run/supervisord.sock

[include]
files = /etc/supervisor.d/*.ini
EOF
fi

## Populate Supervisor services
mkdir -p /etc/supervisor.d/
populate_supervisord_config "haproxy" "/usr/sbin/haproxy -W -f \"${HAPROXY_CONFIG}\"" > /etc/supervisor.d/haproxy.ini
populate_supervisord_config "tor" "/usr/bin/tor" > /etc/supervisor.d/tor.ini

## Populate & validate HAProxy config
populate_haproxy_cfg > "${HAPROXY_CONFIG}"
haproxy -f "${HAPROXY_CONFIG}" -c && {
  echo "[OK] HAProxy config file valid"
}

## Populate & validate TOR config
populate_torrc > "${TOR_CONFIG}"
/usr/bin/tor -f "${TOR_CONFIG}" --verify-config --hush && {
  echo "[OK] TOR config file valid"
}

#cat /etc/supervisord.conf

#exec gosu tor /usr/bin/tor -f "${TOR_CONFIG}" "${@}" &
#exec /usr/sbin/haproxy -W -f "${HAPROXY_CONFIG}"

PYTHONUNBUFFERED=1 exec /usr/bin/supervisord --nodaemon --configuration /etc/supervisord.conf "${@}"
