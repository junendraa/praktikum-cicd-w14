# Pengganti VM Ubuntu (bagian 6) + self-hosted runner (bagian 10).
FROM ubuntu:24.04

ARG RUNNER_VERSION=2.335.1
ENV DEBIAN_FRONTEND=noninteractive

# Paket dasar target (setara apt install di bagian 6)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git tar gzip python3 python3-venv \
 && rm -rf /var/lib/apt/lists/*

# User khusus runner (bukan root) + direktori deployment (least privilege)
RUN useradd --create-home --shell /bin/bash ghrunner \
 && mkdir -p /opt/data-cluster/releases \
 && chown -R ghrunner:ghrunner /opt/data-cluster \
 && chmod 750 /opt/data-cluster

# GitHub Actions runner
WORKDIR /home/ghrunner/actions-runner
RUN curl -fsSL -o runner.tar.gz \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
 && tar xzf runner.tar.gz \
 && rm runner.tar.gz \
 && apt-get update \
 && ./bin/installdependencies.sh \
 && rm -rf /var/lib/apt/lists/* \
 && chown -R ghrunner:ghrunner /home/ghrunner

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

USER ghrunner
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
