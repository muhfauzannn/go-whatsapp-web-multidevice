#!/usr/bin/env bash
set -Eeuo pipefail

: "${DEPLOY_ROOT:?DEPLOY_ROOT is required}"

CONFIG_FILE="$DEPLOY_ROOT/deploy.env"
WHATSAPP_DIR="$DEPLOY_ROOT/go-whatsapp"
WHATSAPP_ENV_FILE="$DEPLOY_ROOT/env/whatsapp.env"
COMPOSE_FILE="$DEPLOY_ROOT/docker-compose.deploy.yml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Missing deploy config: $CONFIG_FILE" >&2
  exit 1
fi

set -a
. "$CONFIG_FILE"
set +a

: "${PROJECT_NAME:?PROJECT_NAME is required in deploy.env}"

if [ ! -d "$WHATSAPP_DIR" ]; then
  echo "Missing WhatsApp directory: $WHATSAPP_DIR" >&2
  exit 1
fi

if [ ! -f "$WHATSAPP_ENV_FILE" ]; then
  echo "Missing WhatsApp env file: $WHATSAPP_ENV_FILE" >&2
  exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Missing compose file: $COMPOSE_FILE" >&2
  echo "Run the backend deploy once first so docker-compose.deploy.yml exists." >&2
  exit 1
fi

install -m 600 "$WHATSAPP_ENV_FILE" "$WHATSAPP_DIR/src/.env"
mkdir -p \
  "$WHATSAPP_DIR/storages" \
  "$WHATSAPP_DIR/statics/qrcode" \
  "$WHATSAPP_DIR/statics/media" \
  "$WHATSAPP_DIR/statics/senditems"

docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" up -d --build --no-deps whatsapp-go
docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" ps whatsapp-go
