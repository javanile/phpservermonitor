#!/usr/bin/env bash
set -e

source .env

cat <<EOF
_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    if [ -z "$SUDO_PASSWORD" ]; then
      echo "❌ Errore: variabile SUDO_PASSWORD non definita" >&2
      return 1
    fi
    echo "\$@"
    echo "$SUDO_PASSWORD" | sudo -S "\$@"
  fi
}

[ ! -d "/opt/phpservermonitor" ] && _sudo git clone --branch main --single-branch https://github.com/javanile/phpservermonitor /opt/phpservermonitor
cd /opt/phpservermonitor
_sudo git pull --no-rebase
_sudo docker compose up -d --build --force-recreate --remove-orphans
EOF
