#!/usr/bin/env sh
set -eu
#set -x
# man:tor

TOR_CONFIG=${TOR_CONFIG:-/etc/tor/torrc}

populate_torrc_config () {
  local buff=$(mktemp)
  local result=${1:?Config file location REQUIRED}
  :>${buff}
  cat << EOF > ${buff}
# /etc/tor/torrc
# man:torrc

EOF
  echo "MaxCircuitDirtiness ${TOR_MAX_CIRCUIT_DIRTNESS:-300}" >> ${buff}
  local min_port=${TOR_PORT_BASE:-9060}
  local amount=${TOR_PORT_AMOUNT:-20}
  for port in $(seq ${min_port} $(( ${min_port} + ${amount} -1 ))); do
    echo "SOCKSPort 0.0.0.0:${port}" >> ${buff}
  done
  mv -f ${buff} ${result}
}

populate_torrc_config "${TOR_CONFIG}"

/usr/bin/tor --verify-config -f "${TOR_CONFIG}"
exec /usr/bin/tor "$@"
