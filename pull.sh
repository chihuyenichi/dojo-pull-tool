#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=pull.conf
source "$SCRIPT_DIR/pull.conf"

OUT="$OUT_DIR"
MODE="all"
MODULE=""
PATTERN=""
DRY_RUN=0
VERBOSE=0
USE_RSYNC=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [pattern] [flags]

Pull challenge files from pwn.college workspace (/challenge) over SSH.

  (no args)         Pull everything under /challenge
  <regex>           Pull files whose names match ERE (e.g. 'babysuid_level1')
Flags:
  -m <module>       Pull files starting with this prefix (e.g. -m pwn.babysuid)
  -o <DIR>          Override output directory (default: $OUT_DIR)
  -n                Dry-run: list remote matches, pull nothing
  -v                Verbose
      --rsync       Use rsync instead of tar-stream
Examples:
  $(basename "$0")
  $(basename "$0") 'babysuid_level\d+'
  $(basename "$0") -m pwn.babysuid -o /tmp/respawn
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m) MODULE="${2:-}"; shift 2 ;;
    -o) OUT="${2:-}"; shift 2 ;;
    -n) DRY_RUN=1; shift ;;
    -v) VERBOSE=1; shift ;;
    --rsync) USE_RSYNC=1; shift ;;
    -h|--help) usage ;;
    -*) usage ;;
    *) PATTERN="$1"; shift ;;
  esac
done

ssh_cmd() {
  ssh -i "$KEY_PATH" -o ConnectTimeout=15 -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new "$DOJO_USER@$SSH_HOST" "$@"
}

fail_key_hint() {
  cat <<EOF >&2
[!] SSH failed (publickey).
    Register the key on pwn.college web: login -> Settings -> SSH Keys,
    then paste the contents of: $(cd "$(dirname "$KEY_PATH")" && pwd)/$(basename "$KEY_PATH").pub
EOF
  exit 2
}

# Build the remote ERE from -m MODULE or PATTERN
build_ere() {
  if [[ -n "$MODULE" ]]; then
    ERE="^${MODULE}"
  else
    ERE="${PATTERN}"
  fi
}

remote_list_human() {
  # newline-separated listing for display / dry-run
  build_ere
  local quoted
  quoted="$(printf '%q' "$ERE")"
  if [[ -z "$MODULE" && -z "$PATTERN" ]]; then
    printf 'ls /challenge'
  else
    printf 'ls /challenge | grep -E %s' "$quoted"
  fi
}

remote_list_null() {
  # NUL-separated listing for tar --null / rsync --from0
  printf '%s | tr "\\n" "\\0"' "$(remote_list_human)"
}

main() {
  mkdir -p "$OUT"

  [[ $VERBOSE -eq 1 ]] && echo "[*] user=$DOJO_USER host=$SSH_HOST out=$OUT"

  if ! ssh_cmd true 2>/dev/null; then
    fail_key_hint
  fi

  REMOTE_LIST="$(ssh_cmd "$(remote_list_human)" || true)"
  if [[ -z "$REMOTE_LIST" ]]; then
    echo "[!] No matching entries in /challenge"
    exit 3
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[*] Dry-run: $(wc -l <<<"$REMOTE_LIST") entries would be pulled to $OUT"
    echo "$REMOTE_LIST"
    exit 0
  fi

  COUNT="$(wc -l <<<"$REMOTE_LIST")"
  echo "[*] Pulling $COUNT entries -> $OUT"

  if [[ $USE_RSYNC -eq 1 ]]; then
    ssh_cmd "$(remote_list_null)" \
      | rsync -az --from0 -e "ssh -i '$KEY_PATH'" \
        --files-from=- "$DOJO_USER@$SSH_HOST:/challenge/" "$OUT/"
  else
    ssh_cmd "$(remote_list_null) | tar czf - -C /challenge --null -T -" \
      | tar xzf - -C "$OUT"
  fi

  echo "[✓] Done."
}

main "$@"
