#!/usr/bin/env bash
set -e

env_file="${1:-.env.example}"

if [ ! -f "$env_file" ]; then
  echo "File $env_file not found!" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$env_file"

cat <<EOF
_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    if [ -z "$SUDO_PASSWORD" ]; then
      echo "❌ Errore: variabile SUDO_PASSWORD non definita" >&2
      return 1
    fi
    echo "RUN: \$@"
    echo "$SUDO_PASSWORD" | sudo -S "\$@"
  fi
}

_update() {
  [ ! -d "/opt/phpservermonitor" ] && _sudo git clone --branch main --single-branch https://github.com/javanile/phpservermonitor /opt/phpservermonitor
  cd /opt/phpservermonitor
  _sudo git pull --no-rebase
  _sudo docker compose up -d --build --force-recreate --remove-orphans
}

_reset() {
  if [ -d "/opt/phpservermonitor" ]; then
    cd /opt/phpservermonitor
    _sudo docker compose down --remove-orphans -v
    cd /opt
    _sudo rm -rf /opt/phpservermonitor
  fi
}

_reset
_update
EOF
