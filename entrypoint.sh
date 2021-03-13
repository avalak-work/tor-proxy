#!/usr/bin/env sh
set -eu
#set -x
## man:tor

TOR_CONFIG=${TOR_CONFIG:-/etc/tor/torrc}

populate_torrc () {
  local max_circuit_dirtness=${TOR_MAX_CIRCUIT_DIRTNESS:-300}
  local min_port=${TOR_PORT_BASE:-9060}
  local amount=${TOR_PORT_AMOUNT:-20}

  cat << EOF
## /etc/tor/torrc
## man:torrc
## Generated at $(date --utc +%Y-%m-%dT%H:%M:%SZ)

EOF

  echo "MaxCircuitDirtiness ${max_circuit_dirtness}"
  for port in $(seq ${min_port} $(( ${min_port} + ${amount} -1 ))); do
    echo "SOCKSPort 0.0.0.0:${port}"
  done
}

## Validate and run
populate_torrc > "${TOR_CONFIG}"
gosu tor /usr/bin/tor -f "${TOR_CONFIG}" --verify-config --hush && {
  echo "[OK] Config file valid"
  cat "${TOR_CONFIG}"
}
exec gosu tor /usr/bin/tor -f "${TOR_CONFIG}" "${@}"
