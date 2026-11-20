#!/bin/bash
# Password diambil dari env ROOT_PASSWORD (di-set bot lewat Railway variables)
ROOT_PASSWORD="${ROOT_PASSWORD:-linn1502}"
echo "root:${ROOT_PASSWORD}" | chpasswd

mkdir -p /run/sshd
ssh-keygen -A >/dev/null 2>&1
/usr/sbin/sshd -e || { echo "sshd GAGAL start"; }
echo "sshd started"

# IP publik (outbound) container, dibaca bot dari log deployment
CIP="$(curl -s4 --max-time 8 https://ifconfig.me 2>/dev/null || curl -s4 --max-time 8 https://api.ipify.org 2>/dev/null)"
echo "CONTAINER_IP=${CIP}"

# freeroot (opsional) jalan di background, tidak boleh mengganggu sshd
if [ -d /opt/freeroot ]; then
  (cd /opt/freeroot && bash noninteractive.sh </dev/null >/dev/null 2>&1 &)
fi

# ttyd = web terminal. JANGAN pakai $PORT: Railway meng-set PORT=22 (port TCP proxy) -> bentrok dengan sshd
# proses utama yang menjaga container tetap hidup
exec /usr/local/bin/ttyd --writable -i 0.0.0.0 -p "${TTYD_PORT:-7681}" \
  -c "root:${ROOT_PASSWORD}" tmux new-session -A -s main /bin/bash
