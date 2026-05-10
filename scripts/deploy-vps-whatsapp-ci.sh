#!/usr/bin/env bash
set -Eeuo pipefail

: "${VPS_HOST:?VPS_HOST is required}"
: "${VPS_PORT:=22}"
: "${VPS_USER:?VPS_USER is required}"
: "${DEPLOY_ROOT:?DEPLOY_ROOT is required}"

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/shurkou_vps"
REMOTE="$VPS_USER@$VPS_HOST"
REMOTE_WHATSAPP_DIR="$DEPLOY_ROOT/go-whatsapp"

if ! command -v rsync >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y rsync
fi

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
ssh-keyscan -p "$VPS_PORT" "$VPS_HOST" >> "$SSH_DIR/known_hosts"

if [ -n "${VPS_SSH_KEY:-}" ]; then
  printf '%s\n' "$VPS_SSH_KEY" > "$SSH_KEY"
  chmod 600 "$SSH_KEY"
  SSH=(ssh -i "$SSH_KEY" -p "$VPS_PORT" -o StrictHostKeyChecking=yes)
  RSYNC_SSH="ssh -i '$SSH_KEY' -p '$VPS_PORT' -o StrictHostKeyChecking=yes"
elif [ -n "${VPS_PASSWORD:-}" ]; then
  if ! command -v sshpass >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y sshpass
  fi
  export SSHPASS="$VPS_PASSWORD"
  SSH=(sshpass -e ssh -p "$VPS_PORT" -o StrictHostKeyChecking=yes)
  RSYNC_SSH="sshpass -e ssh -p '$VPS_PORT' -o StrictHostKeyChecking=yes"
else
  echo "Either VPS_SSH_KEY or VPS_PASSWORD is required." >&2
  exit 1
fi

"${SSH[@]}" "$REMOTE" "mkdir -p '$REMOTE_WHATSAPP_DIR'"

rsync -az --delete \
  --exclude='.git' \
  --exclude='src/.env' \
  --exclude='src/.env.*' \
  --exclude='storages' \
  --exclude='statics/qrcode/*' \
  --exclude='statics/media/*' \
  -e "$RSYNC_SSH" \
  ./ "$REMOTE:$REMOTE_WHATSAPP_DIR/"

"${SSH[@]}" "$REMOTE" \
  "DEPLOY_ROOT='$DEPLOY_ROOT' '$REMOTE_WHATSAPP_DIR/scripts/deploy-vps-whatsapp.sh'"
