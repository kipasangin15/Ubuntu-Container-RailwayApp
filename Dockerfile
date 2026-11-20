FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    PORT=7681 \
    ROOT_PASSWORD=linn1502

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     ca-certificates wget curl git sudo nano htop procps iputils-ping net-tools \
     python3 python3-pip tini tmux openssh-server locales \
  && rm -rf /var/lib/apt/lists/*

# fastfetch tidak selalu ada di repo 24.04, jadi opsional
RUN (apt-get update && apt-get install -y --no-install-recommends fastfetch && rm -rf /var/lib/apt/lists/*) || true

# Konfigurasi SSH: drop-in "00-" dibaca paling awal sehingga menang atas config lain
RUN mkdir -p /run/sshd /etc/ssh/sshd_config.d \
  && chmod 755 /run/sshd \
  && ssh-keygen -A \
  && printf '%s\n' \
       'PermitRootLogin yes' \
       'PasswordAuthentication yes' \
       'KbdInteractiveAuthentication no' \
       'UsePAM yes' \
       'ListenAddress 0.0.0.0' \
       'ListenAddress ::' \
       'ClientAliveInterval 30' \
       'ClientAliveCountMax 4' \
     > /etc/ssh/sshd_config.d/00-railway.conf

RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64|amd64) a="ttyd.x86_64" ;; \
      aarch64|arm64) a="ttyd.aarch64" ;; \
      *) echo "Unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    wget -qO /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/latest/download/${a}"; \
    chmod +x /usr/local/bin/ttyd

RUN git clone --depth 1 https://github.com/Mytai20100/freeroot.git /opt/freeroot || true

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh \
  && echo 'command -v fastfetch >/dev/null && fastfetch || true' >> /root/.bashrc

EXPOSE 22 7681
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/usr/local/bin/start.sh"]
