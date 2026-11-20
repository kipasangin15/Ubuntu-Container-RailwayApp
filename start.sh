#!/bin/bash
ROOT_PASSWORD="${ROOT_PASSWORD:-linn1502}"
echo "root:${ROOT_PASSWORD}" | chpasswd

mkdir -p /run/sshd
ssh-keygen -A >/dev/null 2>&1

# IP publik (outbound) container, dibaca bot dari log
CIP="$(curl -s4 --max-time 8 https://ifconfig.me 2>/dev/null || true)"
echo "CONTAINER_IP=${CIP}"

# Opsional, jalan di background dan tidak boleh mematikan container
if [ -d /opt/freeroot ]; then
  (cd /opt/freeroot && bash noninteractive.sh </dev/null >/tmp/freeroot.log 2>&1 &) || true
fi
if [ -x /usr/local/bin/ttyd ]; then
  ( while true; do
      /usr/local/bin/ttyd --writable -i 0.0.0.0 -p "${TTYD_PORT:-7681}" -c "root:${ROOT_PASSWORD}" \
        tmux new-session -A -s main /bin/bash >/tmp/ttyd.log 2>&1
      sleep 5
    done ) &
fi

# sshd sebagai proses utama (foreground)
exec /usr/sbin/sshd -D -e
