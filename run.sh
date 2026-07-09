#!/bin/bash
#
# Docker script to configure and start a Docling document parsing server
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC! THIS IS ONLY MEANT TO BE RUN
# IN A CONTAINER!
#
# This file is part of Docling Docker image, available at:
# https://github.com/hwdsl2/docker-docling
#
# Copyright (C) 2026 Lin Song <linsongui@gmail.com>
#
# This work is licensed under the MIT License
# See: https://opensource.org/licenses/MIT

# Preserve the base image PATH (sclorg convention: /opt/app-root/bin is on PATH)
export PATH="/opt/app-root/bin:${PATH}"

exiterr()  { echo "Error: $1" >&2; exit 1; }
nospaces() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
noquotes() { printf '%s' "$1" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"; }

check_port() {
  printf '%s' "$1" | tr -d '\n' | grep -Eq '^[0-9]+$' \
  && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
}

check_ip() {
  IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}

# Source bind-mounted env file if present (takes precedence over --env-file)
if [ -f /docling.env ]; then
  # shellcheck disable=SC1091
  . /docling.env
fi

if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ] \
  && [ -z "$KUBERNETES_SERVICE_HOST" ] \
  && ! head -n 1 /proc/1/sched 2>/dev/null | grep -q '^run\.sh '; then
  exiterr "This script ONLY runs in a container (e.g. Docker, Podman)."
fi

DOCLING_API_KEY_WAS_SET=${DOCLING_API_KEY+x}

# Read and sanitize environment variables
DOCLING_PORT=$(nospaces "$DOCLING_PORT")
DOCLING_PORT=$(noquotes "$DOCLING_PORT")
DOCLING_API_KEY=$(nospaces "$DOCLING_API_KEY")
DOCLING_API_KEY=$(noquotes "$DOCLING_API_KEY")
DOCLING_LOG_LEVEL=$(nospaces "$DOCLING_LOG_LEVEL")
DOCLING_LOG_LEVEL=$(noquotes "$DOCLING_LOG_LEVEL")
DOCLING_WORKERS=$(nospaces "$DOCLING_WORKERS")
DOCLING_WORKERS=$(noquotes "$DOCLING_WORKERS")
DOCLING_ENABLE_UI=$(nospaces "$DOCLING_ENABLE_UI")
DOCLING_ENABLE_UI=$(noquotes "$DOCLING_ENABLE_UI")
DOCLING_MAX_PAGES=$(nospaces "$DOCLING_MAX_PAGES")
DOCLING_MAX_PAGES=$(noquotes "$DOCLING_MAX_PAGES")
DOCLING_MAX_FILE_SIZE=$(nospaces "$DOCLING_MAX_FILE_SIZE")
DOCLING_MAX_FILE_SIZE=$(noquotes "$DOCLING_MAX_FILE_SIZE")
DOCLING_DEVICE=$(nospaces "$DOCLING_DEVICE")
DOCLING_DEVICE=$(noquotes "$DOCLING_DEVICE")
DOCLING_LOCAL_ONLY=$(nospaces "$DOCLING_LOCAL_ONLY")
DOCLING_LOCAL_ONLY=$(noquotes "$DOCLING_LOCAL_ONLY")

# Apply defaults
[ -z "$DOCLING_PORT" ]      && DOCLING_PORT=5001
[ -z "$DOCLING_LOG_LEVEL" ] && DOCLING_LOG_LEVEL=INFO
[ -z "$DOCLING_WORKERS" ]   && DOCLING_WORKERS=1
[ -z "$DOCLING_ENABLE_UI" ] && DOCLING_ENABLE_UI=false
[ -z "$DOCLING_DEVICE" ]    && DOCLING_DEVICE=cpu

# Validate port
if ! check_port "$DOCLING_PORT"; then
  exiterr "DOCLING_PORT must be an integer between 1 and 65535."
fi

# Validate log level
case "$DOCLING_LOG_LEVEL" in
  DEBUG|INFO|WARNING|ERROR) ;;
  *) exiterr "DOCLING_LOG_LEVEL must be one of: DEBUG, INFO, WARNING, ERROR." ;;
esac

# Validate workers
if ! printf '%s' "$DOCLING_WORKERS" | grep -Eq '^[1-9][0-9]*$'; then
  exiterr "DOCLING_WORKERS must be a positive integer."
fi

# Validate enable UI
case "$DOCLING_ENABLE_UI" in
  true|false) ;;
  *) exiterr "DOCLING_ENABLE_UI must be one of: true, false." ;;
esac

# Validate device
case "$DOCLING_DEVICE" in
  cpu|cuda) ;;
  auto)
    if [ -e /dev/nvidia0 ] || nvidia-smi >/dev/null 2>&1; then
      DOCLING_DEVICE=cuda
    else
      DOCLING_DEVICE=cpu
    fi
    ;;
  *) exiterr "DOCLING_DEVICE must be one of: cpu, cuda, auto." ;;
esac

# Validate max pages
if [ -n "$DOCLING_MAX_PAGES" ]; then
  if ! printf '%s' "$DOCLING_MAX_PAGES" | grep -Eq '^[1-9][0-9]*$'; then
    exiterr "DOCLING_MAX_PAGES must be a positive integer."
  fi
fi

# Validate max file size
if [ -n "$DOCLING_MAX_FILE_SIZE" ]; then
  if ! printf '%s' "$DOCLING_MAX_FILE_SIZE" | grep -Eq '^[1-9][0-9]*$'; then
    exiterr "DOCLING_MAX_FILE_SIZE must be a positive integer (bytes)."
  fi
fi

mkdir -p /var/lib/docling 2>/dev/null || true

DATA_DIR="/var/lib/docling"
API_KEY_FILE="${DATA_DIR}/.api_key"
AUTH_ENABLED_FILE="${DATA_DIR}/.auth_enabled"
AUTO_API_KEY_MARKER="${DATA_DIR}/.auto_api_key_created"
USAGE_STATE_DIR="${DATA_DIR}/.docling-usage"
USAGE_BASE_URL=${DOCLING_USAGE_BASE_URL:-https://github.com/hwdsl2/ai-stack-extras/releases/download/v1.0.0}
data_mounted=false
data_existing=false

if grep -q " ${DATA_DIR} " /proc/mounts 2>/dev/null; then
  data_mounted=true
fi
if $data_mounted && find "$DATA_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null | grep -q .; then
  data_existing=true
fi

usage_arch() {
  local arch
  arch=$(uname -m 2>/dev/null || printf 'unknown')
  case "$arch" in
    x86_64|amd64) printf 'amd64' ;;
    aarch64|arm64) printf 'arm64' ;;
    *) printf 'other' ;;
  esac
}

write_usage_state() {
  local state_file version tmp_file
  state_file=$1
  version=$2
  mkdir -p "$USAGE_STATE_DIR"
  tmp_file=$(mktemp "$USAGE_STATE_DIR/.usage.XXXXXX")
  printf '%s\n' "$version" > "$tmp_file"
  chmod 0644 "$tmp_file" 2>/dev/null || true
  mv "$tmp_file" "$state_file"
}

fetch_usage_asset() {
  local asset base_url
  asset=$1
  base_url=${USAGE_BASE_URL%/}
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --max-time 5 -o /dev/null "$base_url/$asset" >/dev/null 2>&1
  elif command -v wget >/dev/null 2>&1; then
    wget -q -T 5 -O /dev/null "$base_url/$asset" >/dev/null 2>&1
  else
    return 1
  fi
}

read_state_value() {
  [ -r "$1" ] || return 0
  tr -d '[:space:]' < "$1"
}

report_usage_counts() {
  local current_version accel arch state_file last_version action

  [ "${DOCLING_DISABLE_USAGE_COUNTS:-0}" != "1" ] || return 0
  $data_mounted || return 0

  current_version="${IMAGE_FLAVOR:-unknown}-${IMAGE_VER:-unknown}"
  case "${IMAGE_FLAVOR:-}" in
    cuda) accel=cuda ;;
    *) accel=cpu ;;
  esac
  arch=$(usage_arch)

  state_file="$USAGE_STATE_DIR/docling.version"
  last_version=$(read_state_value "$state_file")
  action=

  if [ -z "$last_version" ]; then
    if $data_existing; then
      action=upgrade
    else
      action=deploy
    fi
  elif [ "$last_version" != "$current_version" ]; then
    action=upgrade
  fi

  if [ -n "$action" ]; then
    if fetch_usage_asset "cu-v1-docling-$action-$accel-$arch"; then
      write_usage_state "$state_file" "$current_version"
    fi
  fi
}

if [ -n "$DOCLING_API_KEY" ]; then
  printf '%s' "$DOCLING_API_KEY" > "$API_KEY_FILE" 2>/dev/null || true
  chmod 600 "$API_KEY_FILE" 2>/dev/null || true
elif [ -z "$DOCLING_API_KEY_WAS_SET" ] && [ -f "$API_KEY_FILE" ]; then
  DOCLING_API_KEY=$(cat "$API_KEY_FILE")
elif [ -z "$DOCLING_API_KEY_WAS_SET" ] && $data_mounted && ! $data_existing; then
  DOCLING_API_KEY="docling-$(head -c 32 /dev/urandom | od -A n -t x1 | tr -d ' \n' | head -c 48)"
  printf '%s' "$DOCLING_API_KEY" > "$API_KEY_FILE" 2>/dev/null || true
  chmod 600 "$API_KEY_FILE" 2>/dev/null || true
  printf '%s\n' "true" > "$AUTO_API_KEY_MARKER" 2>/dev/null || true
  chmod 600 "$AUTO_API_KEY_MARKER" 2>/dev/null || true
fi
if [ -n "$DOCLING_API_KEY" ]; then
  printf '%s' "1" > "$AUTH_ENABLED_FILE" 2>/dev/null || true
else
  printf '%s' "0" > "$AUTH_ENABLED_FILE" 2>/dev/null || true
fi

# Map our simplified env vars to upstream docling-serve env vars
export UVICORN_PORT="$DOCLING_PORT"
export UVICORN_HOST="0.0.0.0"
export DOCLING_SERVE_LOG_LEVEL="$DOCLING_LOG_LEVEL"

if [ "$DOCLING_WORKERS" -gt 1 ]; then
  export UVICORN_WORKERS="$DOCLING_WORKERS"
fi

if [ "$DOCLING_ENABLE_UI" = "true" ]; then
  export DOCLING_SERVE_ENABLE_UI=1
fi

if [ -n "$DOCLING_API_KEY" ]; then
  export DOCLING_SERVE_API_KEY="$DOCLING_API_KEY"
fi

if [ -n "$DOCLING_MAX_PAGES" ]; then
  export DOCLING_SERVE_MAX_NUM_PAGES="$DOCLING_MAX_PAGES"
fi

if [ -n "$DOCLING_MAX_FILE_SIZE" ]; then
  export DOCLING_SERVE_MAX_FILE_SIZE="$DOCLING_MAX_FILE_SIZE"
fi

# Enable management endpoints for docling_manage --version
export DOCLING_SERVE_ENABLE_MANAGEMENT_ENDPOINTS=true

# Point HuggingFace Hub at the persistent Docker volume for runtime downloads
export HF_HOME=/var/lib/docling

# Set offline flag for HuggingFace Hub libraries if local-only mode is enabled
if [ -n "$DOCLING_LOCAL_ONLY" ]; then
  export HF_HUB_OFFLINE=1
fi

# Determine server address for display
public_ip=$(curl -s --max-time 10 http://ipv4.icanhazip.com 2>/dev/null || true)
check_ip "$public_ip" || public_ip=$(curl -s --max-time 10 http://ip1.dynupdate.no-ip.com 2>/dev/null || true)
if check_ip "$public_ip"; then
  server_addr="$public_ip"
else
  server_addr="<server ip>"
fi

# Persist config values so docling_manage can read them without the env file
printf '%s' "$DOCLING_PORT" > /var/lib/docling/.port 2>/dev/null || true
printf '%s' "$server_addr"  > /var/lib/docling/.server_addr 2>/dev/null || true

echo
echo "Docling Docker - https://github.com/hwdsl2/docker-docling"

if ! grep -q " /var/lib/docling " /proc/mounts 2>/dev/null; then
  echo
  echo "Note: /var/lib/docling is not mounted. Runtime data will be lost on"
  echo "      container removal. Mount a Docker volume at /var/lib/docling"
  echo "      to persist data across container restarts."
  if [ -z "$DOCLING_API_KEY" ] && [ -z "$DOCLING_API_KEY_WAS_SET" ]; then
    echo "      API key authentication was not auto-enabled because the"
    echo "      data directory is not persistent."
  fi
elif [ -z "$DOCLING_API_KEY" ] && [ -z "$DOCLING_API_KEY_WAS_SET" ] && $data_existing; then
  echo
  echo "Warning: Existing Docling data was found but no API key is configured."
  echo "         Preserving no-auth behavior for backward compatibility."
  echo "         Set DOCLING_API_KEY to enable authentication."
fi

echo
echo "Starting Docling document parsing server..."
echo "  Port:      $DOCLING_PORT"
echo "  Device:    $DOCLING_DEVICE"
echo "  Log level: $DOCLING_LOG_LEVEL"
echo "  Workers:   $DOCLING_WORKERS"
if [ "$DOCLING_ENABLE_UI" = "true" ]; then
  echo "  UI:        enabled"
fi
if [ -n "$DOCLING_LOCAL_ONLY" ]; then
  echo "  Mode:      local-only (no HuggingFace downloads)"
fi
echo

# Graceful shutdown — registered before starting the server so any SIGTERM
# received during the model-loading startup phase is handled cleanly.
cleanup() {
  echo
  echo "Stopping Docling server..."
  kill "${DOCLING_PID:-}" 2>/dev/null
  wait "${DOCLING_PID:-}" 2>/dev/null
  exit 0
}
trap cleanup INT TERM

# Start the docling-serve server in the background
docling-serve run &
DOCLING_PID=$!

# Wait for the server to become ready.
# Allow up to 600 seconds — model loading on first start can take several minutes,
# especially on systems with limited CPU/memory.
wait_for_server() {
  local i=0
  while [ "$i" -lt 600 ]; do
    if ! kill -0 "$DOCLING_PID" 2>/dev/null; then
      return 1
    fi
    # /ready returns 503 until models are loaded, then 200
    if curl -sf "http://127.0.0.1:${DOCLING_PORT}/ready" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

if ! wait_for_server; then
  if ! kill -0 "$DOCLING_PID" 2>/dev/null; then
    echo "Error: Docling server failed to start. Check the container logs for details." >&2
  else
    echo "Error: Docling server did not become ready within 600 seconds." >&2
    kill "$DOCLING_PID" 2>/dev/null
  fi
  exit 1
fi

report_usage_counts

echo
echo "==========================================================="
echo " Docling document parsing server is ready"
echo "==========================================================="
echo " Endpoint: http://${server_addr}:${DOCLING_PORT}"
echo "==========================================================="
echo
echo "Convert a document (from URL):"
echo "  curl -X POST http://${server_addr}:${DOCLING_PORT}/v1/convert/source \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"sources\": [{\"kind\": \"http\", \"url\": \"https://arxiv.org/pdf/2501.17887\"}]}'"
echo
if [ -n "$DOCLING_API_KEY" ]; then
  echo "API key authentication is enabled."
  echo "Include header:  -H \"X-Api-Key: \$DOCLING_API_KEY\""
  echo
fi
echo "Interactive API docs: http://${server_addr}:${DOCLING_PORT}/docs"
if [ "$DOCLING_ENABLE_UI" = "true" ]; then
  echo "UI playground:        http://${server_addr}:${DOCLING_PORT}/ui"
fi
echo
echo "To set up HTTPS, see: Using a reverse proxy"
echo "  https://github.com/hwdsl2/docker-docling#using-a-reverse-proxy"
echo
echo "Setup complete."
echo

# Wait for the server process to exit
wait "$DOCLING_PID"
