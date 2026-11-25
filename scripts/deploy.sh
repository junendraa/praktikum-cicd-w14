#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="${DEPLOY_BASE_DIR:-/opt/data-cluster}"
COMMIT="${GITHUB_SHA:-$(git rev-parse HEAD)}"
RUN_ID="${GITHUB_RUN_ID:-local-$(date +%Y%m%d%H%M%S)}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_ID="${COMMIT:0:12}-${RUN_ID}"
RELEASE_DIR="$BASE_DIR/releases/$RELEASE_ID"

if [[ ! -d "$PROJECT_DIR/dags" || ! -d "$PROJECT_DIR/src" ]]; then
  echo "Direktori dags/ atau src/ tidak ditemukan." >&2
  exit 1
fi

mkdir -p "$BASE_DIR/releases"
mkdir -p "$RELEASE_DIR"
cp -a "$PROJECT_DIR/dags" "$RELEASE_DIR/"
cp -a "$PROJECT_DIR/src" "$RELEASE_DIR/"
if [[ -d "$PROJECT_DIR/data" ]]; then
  cp -a "$PROJECT_DIR/data" "$RELEASE_DIR/"
fi

test -s "$RELEASE_DIR/dags/sales_daily_dag.py"
test -s "$RELEASE_DIR/src/sales_transform.py"

if [[ -L "$BASE_DIR/current" ]]; then
  OLD_RELEASE="$(readlink -f "$BASE_DIR/current")"
  ln -sfn "$OLD_RELEASE" "$BASE_DIR/.previous-$RUN_ID"
  mv -Tf "$BASE_DIR/.previous-$RUN_ID" "$BASE_DIR/previous"
fi

ln -sfn "$RELEASE_DIR" "$BASE_DIR/.current-$RUN_ID"
mv -Tf "$BASE_DIR/.current-$RUN_ID" "$BASE_DIR/current"

echo "Deployment berhasil."
echo "Commit: $COMMIT"
echo "Release: $RELEASE_DIR"
echo "Current: $(readlink -f "$BASE_DIR/current")"
