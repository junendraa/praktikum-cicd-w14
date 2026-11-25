#!/usr/bin/env bash
# Daftarkan runner sekali (token hanya dipakai saat pertama), lalu jalankan.
set -euo pipefail
cd /home/ghrunner/actions-runner

if [[ ! -f .runner ]]; then
  : "${REPO_URL:?REPO_URL belum diisi di file .env}"
  : "${RUNNER_TOKEN:?RUNNER_TOKEN belum diisi di file .env}"
  ./config.sh --unattended \
    --url "$REPO_URL" \
    --token "$RUNNER_TOKEN" \
    --name "${RUNNER_NAME:-docker-cicd-target}" \
    --labels cicd-target \
    --work _work \
    --replace
fi

exec ./run.sh
