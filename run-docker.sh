#!/usr/bin/env bash
# Wrapper: build image on first use, then run dojo-pull-tool inside a container.
# Usage: ./run-docker.sh [pull.sh args...]   (same flags as pull.sh)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="dojo-pull:latest"
KEY="${KEY_PATH:-$HOME/.ssh/id_ed25519}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[!] docker CLI not found. Install it first:" >&2
  echo "    sudo apt update && sudo apt install -y docker.io && sudo usermod -aG docker \$USER" >&2
  exit 2
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[*] Building image $IMAGE..."
  docker build -t "$IMAGE" "$DIR"
fi

exec docker run --rm -it \
  -e OUT_DIR=/outputs \
  -e KEY_PATH=/run/ssh-key \
  -v "$KEY":/run/ssh-key:ro \
  -v "$DIR/pull.conf":/app/pull.conf:ro \
  -v "$DIR/outputs":/outputs \
  "$IMAGE" "$@"
