#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="${DEPLOY_BASE_DIR:-/opt/data-cluster}"
CURRENT="$BASE_DIR/current"
PREVIOUS="$BASE_DIR/previous"

if [[ ! -L "$PREVIOUS" ]]; then
  echo "Release sebelumnya tidak ditemukan: $PREVIOUS" >&2
  exit 1
fi

PREVIOUS_RELEASE="$(readlink -f "$PREVIOUS")"
if [[ ! -d "$PREVIOUS_RELEASE" ]]; then
  echo "Direktori release sebelumnya tidak valid." >&2
  exit 1
fi

if [[ -L "$CURRENT" ]]; then
  CURRENT_RELEASE="$(readlink -f "$CURRENT")"
  ln -sfn "$CURRENT_RELEASE" "$BASE_DIR/.previous-rollback"
  mv -Tf "$BASE_DIR/.previous-rollback" "$PREVIOUS"
fi

ln -sfn "$PREVIOUS_RELEASE" "$BASE_DIR/.current-rollback"
mv -Tf "$BASE_DIR/.current-rollback" "$CURRENT"

echo "Rollback selesai."
echo "Current: $(readlink -f "$CURRENT")"
