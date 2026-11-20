#!/bin/bash
# Password diambil dari env ROOT_PASSWORD (di-set bot lewat Railway variables)
ROOT_PASSWORD="${ROOT_PASSWORD:-linn1502}"
echo "root:${ROOT_PASSWORD}" | chpasswd

mkdir -p /run/sshd
ssh-keygen -A >/dev/null 2>&1
/usr/sbin/sshd -e || { echo "sshd GAGAL start"; }
echo "sshd started"

# freeroot (opsional) jalan di background, tidak boleh mengganggu sshd
if [ -d /opt/freeroot ]; then
  (cd /opt/freeroot && bash noninteractive.sh </dev/null >/dev/null 2>&1 &)
fi

# ttyd = web terminal (port ${PORT}); proses utama yang menjaga container tetap hidup
exec /usr/local/bin/ttyd --writable -i 0.0.0.0 -p "${PORT:-7681}" \
  -c "root:${ROOT_PASSWORD}" tmux new-session -A -s main /bin/bash
