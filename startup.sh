#!/bin/sh

set -eu

_should_tls() {
	[ -n "${DOCKER_TLS_CERTDIR:-}" ] \
	&& [ -s "$DOCKER_TLS_CERTDIR/client/ca.pem" ] \
	&& [ -s "$DOCKER_TLS_CERTDIR/client/cert.pem" ] \
	&& [ -s "$DOCKER_TLS_CERTDIR/client/key.pem" ]
}

# if we have no DOCKER_HOST but we do have the default Unix socket (standard or rootless), use it explicitly
if [ -z "${DOCKER_HOST:-}" ] && [ -S /var/run/docker.sock ]; then
	export DOCKER_HOST=unix:///var/run/docker.sock
elif [ -z "${DOCKER_HOST:-}" ] && XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" && [ -S "$XDG_RUNTIME_DIR/docker.sock" ]; then
	export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"
fi

# if DOCKER_HOST isn't set (no custom setting, no default socket), let's set it to a sane remote value
if [ -z "${DOCKER_HOST:-}" ]; then
	if _should_tls || [ -n "${DOCKER_TLS_VERIFY:-}" ]; then
		export DOCKER_HOST='tcp://docker:2376'
	else
		export DOCKER_HOST='tcp://docker:2375'
	fi
fi
if [ "${DOCKER_HOST#tcp:}" != "$DOCKER_HOST" ] \
	&& [ -z "${DOCKER_TLS_VERIFY:-}" ] \
	&& [ -z "${DOCKER_CERT_PATH:-}" ] \
	&& _should_tls \
; then
	export DOCKER_TLS_VERIFY=1
	export DOCKER_CERT_PATH="$DOCKER_TLS_CERTDIR/client"
fi

cd /opt/mailcow

if [ ! "$(ls -A .)" ]; then
  if [ ! -f "/src/mailcow.conf" ]; then
    echo "No mailcow.conf supplied, exiting! Please mount your mailcow.conf to /src/mailcow.conf."
    exit
  fi
  echo "First start, copying mailcow files..."
  cp -R /src/. .
elif [ -f "/src/mailcow.conf" ]; then
  cp -rf /src/mailcow.conf /opt/mailcow
fi

if [ ! -f "mailcow.conf" ]; then
  echo "Generating mailcow config..."
  ./generate_config.sh
fi

docker-compose up
