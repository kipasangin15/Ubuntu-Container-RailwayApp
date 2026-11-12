FROM ubuntu:latest

ENV PORT=7681
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     ca-certificates wget curl git sudo unminimize python3 python3-pip tini fastfetch tmux \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/bin

RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64|amd64) ttyd_asset="ttyd.x86_64" ;; \
      aarch64|arm64) ttyd_asset="ttyd.aarch64" ;; \
      *) echo "Unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    wget -qO /usr/local/bin/ttyd "https://github.com/tsl0922/ttyd/releases/latest/download/${ttyd_asset}" \
    && chmod +x /usr/local/bin/ttyd

RUN git clone https://github.com/Mytai20100/freeroot.git /opt/freeroot

ENV USERNAME=root
ENV PASSWORD=linn1502

RUN echo "fastfetch || true" >> /root/.bashrc

EXPOSE 7681

ENTRYPOINT ["/usr/bin/tini","--"]

CMD ["/bin/bash", "-lc", "cd /opt/freeroot && bash noninteractive.sh & sleep 2 && /usr/local/bin/ttyd --writable -i 0.0.0.0 -p ${PORT} -c ${USERNAME}:${PASSWORD} tmux new-session -A -s main /bin/bash"]
