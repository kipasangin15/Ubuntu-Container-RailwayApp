FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    LANG=C.UTF-8 \
    TTYD_PORT=7681 \
    ROOT_PASSWORD=linn1502

# Update, upgrade, dan paket dasar
RUN apt-get update \
  && apt-get -y upgrade \
  && apt-get install -y --no-install-recommends \
       ca-certificates gnupg tzdata locales sudo tini \
       curl wget git unzip zip tar xz-utils jq rsync \
       openssh-server openssh-client \
       nano vim htop tmux screen procps lsof \
       iproute2 iputils-ping net-tools dnsutils \
       build-essential pkg-config \
       libssl-dev libffi-dev zlib1g-dev libsqlite3-dev \
       python3 python3-pip python3-venv python3-dev python-is-python3 \
  && rm -rf /var/lib/apt/lists/*

# Node.js LTS (NodeSource) + npm + pm2
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && npm install -g npm@latest pm2 \
  && rm -rf /var/lib/apt/lists/* /root/.npm

# fastfetch opsional (belum tentu tersedia di repo 24.04)
RUN (apt-get update && apt-get install -y --no-install-recommends fastfetch && rm -rf /var/lib/apt/lists/*) || true

# SSH: drop-in "00-" dibaca paling awal sehingga menang atas config lain
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

# Web terminal (ttyd)
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

WORKDIR /root
EXPOSE 22 7681
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/usr/local/bin/start.sh"]
