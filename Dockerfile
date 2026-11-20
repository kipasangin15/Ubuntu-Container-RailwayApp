FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    TTYD_PORT=7681 \
    ROOT_PASSWORD=linn1502

RUN apt-get update \
  && (apt-get -y upgrade || true) \
  && apt-get install -y --no-install-recommends \
       ca-certificates curl wget git sudo tini locales tzdata \
       openssh-server openssh-client \
       nano htop procps tmux jq zip unzip \
       iproute2 iputils-ping net-tools dnsutils \
       build-essential python3 python3-pip python-is-python3 \
       nodejs npm \
  && (npm install -g pm2 || true) \
  && rm -rf /var/lib/apt/lists/* /root/.npm

RUN (apt-get update && apt-get install -y --no-install-recommends fastfetch && rm -rf /var/lib/apt/lists/*) || true

RUN mkdir -p /run/sshd /etc/ssh/sshd_config.d \
  && ssh-keygen -A \
  && printf '%s\n' 'PermitRootLogin yes' 'PasswordAuthentication yes' 'ClientAliveInterval 30' 'ClientAliveCountMax 4' \
     > /etc/ssh/sshd_config.d/00-railway.conf

RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in x86_64|amd64) a="ttyd.x86_64" ;; aarch64|arm64) a="ttyd.aarch64" ;; *) a="" ;; esac; \
    if [ -n "$a" ]; then \
      (wget -qO /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/latest/download/${a}" && chmod +x /usr/local/bin/ttyd) || true; \
    fi

RUN git clone --depth 1 https://github.com/Mytai20100/freeroot.git /opt/freeroot || true

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh \
  && echo 'command -v fastfetch >/dev/null && fastfetch || true' >> /root/.bashrc

WORKDIR /root
EXPOSE 22 7681
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/usr/local/bin/start.sh"]
