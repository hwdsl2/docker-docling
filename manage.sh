#!/bin/bash
#
# https://github.com/hwdsl2/docker-docling
#
# Copyright (C) 2026 Lin Song <linsongui@gmail.com>
#
# This work is licensed under the MIT License
# See: https://opensource.org/licenses/MIT

export PATH="/opt/app-root/bin:${PATH}"

DOCLING_DATA="/var/lib/docling"
PORT_FILE="${DOCLING_DATA}/.port"
SERVER_ADDR_FILE="${DOCLING_DATA}/.server_addr"
API_KEY_FILE="${DOCLING_DATA}/.api_key"
AUTH_ENABLED_FILE="${DOCLING_DATA}/.auth_enabled"

exiterr() { echo "Error: $1" >&2; exit 1; }

show_usage() {
  local exit_code="${2:-1}"
  if [ -n "$1" ]; then
    echo "Error: $1" >&2
  fi
  cat 1>&2 <<'EOF'

Docling Docker - Server Management
https://github.com/hwdsl2/docker-docling

Usage: docker exec <container> docling_manage [options]

Options:
  --showinfo                           show server info (endpoint, config)
  --showkey                            show the API key, if configured
  --getkey                             output the API key (machine-readable, no decoration)
  --showformats                        list supported input and output formats
  --downloadmodels                     download/update layout, OCR, and table models
  --version                            show docling and docling-serve versions

  -h, --help                           show this help message and exit

Examples:
  docker exec docling docling_manage --showinfo
  docker exec docling docling_manage --showkey
  docker exec docling docling_manage --getkey
  docker exec docling docling_manage --showformats
  docker exec docling docling_manage --downloadmodels
  docker exec docling docling_manage --version

EOF
  exit "$exit_code"
}

check_container() {
  if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ] \
    && [ -z "$KUBERNETES_SERVICE_HOST" ] \
    && ! head -n 1 /proc/1/sched 2>/dev/null | grep -q '^run\.sh '; then
    exiterr "This script must be run inside a container (e.g. Docker, Podman)."
  fi
}

load_config() {
  if [ -z "$DOCLING_PORT" ]; then
    if [ -f "$PORT_FILE" ]; then
      DOCLING_PORT=$(cat "$PORT_FILE")
    else
      DOCLING_PORT=5001
    fi
  fi

  if [ -f "$SERVER_ADDR_FILE" ]; then
    SERVER_ADDR=$(cat "$SERVER_ADDR_FILE")
  else
    SERVER_ADDR="<server ip>"
  fi

  if [ -f "$AUTH_ENABLED_FILE" ]; then
    DOCLING_AUTH_ENABLED=$(cat "$AUTH_ENABLED_FILE")
  fi

  if [ "$DOCLING_AUTH_ENABLED" != 0 ] && [ -z "$DOCLING_API_KEY" ] && [ -f "$API_KEY_FILE" ]; then
    DOCLING_API_KEY=$(cat "$API_KEY_FILE")
  fi

  if [ -z "$DOCLING_AUTH_ENABLED" ]; then
    if [ -n "$DOCLING_API_KEY" ]; then
      DOCLING_AUTH_ENABLED=1
    else
      DOCLING_AUTH_ENABLED=0
    fi
  fi
}

check_server() {
  if ! curl -sf "http://127.0.0.1:${DOCLING_PORT}/health" >/dev/null 2>&1; then
    exiterr "Docling server is not responding on port ${DOCLING_PORT}. Is the container fully started?"
  fi
}

parse_args() {
  show_info=0
  show_key=0
  get_key=0
  show_formats=0
  download_models=0
  show_version=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --showinfo)
        show_info=1
        shift
        ;;
      --showkey)
        show_key=1
        shift
        ;;
      --getkey)
        get_key=1
        shift
        ;;
      --showformats)
        show_formats=1
        shift
        ;;
      --downloadmodels)
        download_models=1
        shift
        ;;
      --version)
        show_version=1
        shift
        ;;
      -h|--help)
        show_usage "" 0
        ;;
      *)
        show_usage "Unknown parameter: $1"
        ;;
    esac
  done
}

check_args() {
  local action_count
  action_count=$((show_info + show_key + get_key + show_formats + download_models + show_version))

  if [ "$action_count" -eq 0 ]; then
    show_usage
  fi
  if [ "$action_count" -gt 1 ]; then
    show_usage "Specify only one action at a time."
  fi
}

do_show_key() {
  if [ "$DOCLING_AUTH_ENABLED" != 1 ]; then
    exiterr "API key authentication is disabled for this container."
  fi

  if [ -z "$DOCLING_API_KEY" ]; then
    if [ -f "$API_KEY_FILE" ]; then
      DOCLING_API_KEY=$(cat "$API_KEY_FILE")
    else
      exiterr "API key not found. Authentication may be disabled for this container."
    fi
  fi

  echo
  echo "==========================================================="
  echo " Docling API key"
  echo "==========================================================="
  echo "${DOCLING_API_KEY}"
  echo "==========================================================="
  echo
  echo "Use with: -H \"X-Api-Key: ${DOCLING_API_KEY}\""
  echo
}

do_get_key() {
  if [ "$DOCLING_AUTH_ENABLED" != 1 ]; then
    exit 1
  fi

  if [ -z "$DOCLING_API_KEY" ]; then
    if [ -f "$API_KEY_FILE" ]; then
      DOCLING_API_KEY=$(cat "$API_KEY_FILE")
    else
      exit 1
    fi
  fi

  printf '%s' "$DOCLING_API_KEY"
}

do_show_info() {
  echo
  echo "==========================================================="
  echo " Docling Document Parsing Server"
  echo "==========================================================="
  echo " Endpoint:     http://${SERVER_ADDR}:${DOCLING_PORT}"
  echo "==========================================================="
  echo
  echo "API endpoints:"
  echo "  POST http://${SERVER_ADDR}:${DOCLING_PORT}/v1/convert/source"
  echo "  POST http://${SERVER_ADDR}:${DOCLING_PORT}/v1/convert/file"
  echo "  GET  http://${SERVER_ADDR}:${DOCLING_PORT}/health"
  echo "  GET  http://${SERVER_ADDR}:${DOCLING_PORT}/version"
  echo "  GET  http://${SERVER_ADDR}:${DOCLING_PORT}/docs     (interactive docs)"
  echo
  echo "Example — convert a document from URL:"
  echo "  curl -X POST http://${SERVER_ADDR}:${DOCLING_PORT}/v1/convert/source \\"
  echo "    -H 'Content-Type: application/json' \\"
  if [ "$DOCLING_AUTH_ENABLED" = 1 ]; then
    echo "    -H \"X-Api-Key: <api-key>\" \\"
  fi
  echo "    -d '{\"sources\": [{\"kind\": \"http\", \"url\": \"https://arxiv.org/pdf/2501.17887\"}]}'"
  if [ "$DOCLING_AUTH_ENABLED" = 1 ]; then
    echo
    echo "Use '--showkey' to display the API key."
  fi
  echo
}

do_show_formats() {
  cat <<'EOF'

Supported document formats:

  Input formats:
    Format              Extensions
    ------              ----------
    PDF                 .pdf
    Microsoft Word      .docx
    Microsoft PowerPoint .pptx
    Microsoft Excel     .xlsx
    HTML                .html, .htm
    Markdown            .md
    LaTeX               .tex
    AsciiDoc            .adoc, .asciidoc
    CSV                 .csv
    Images              .png, .jpg, .jpeg, .tiff, .bmp, .gif

  Output formats:
    Format              Description
    ------              -----------
    Markdown            Structured Markdown with tables
    JSON                Full document structure as JSON
    HTML                Rendered HTML output
    Text                Plain text extraction
    DocTags             Docling's internal tagged format

  Output format is controlled per-request via the API.
  See the interactive API docs at /docs for full request options.

EOF
}

do_download_models() {
  # Block download if DOCLING_LOCAL_ONLY is set
  if [ -n "$DOCLING_LOCAL_ONLY" ]; then
    exiterr "DOCLING_LOCAL_ONLY is set — model downloads are disabled. Unset it to allow downloads."
  fi

  echo
  echo "Downloading/updating Docling models..."
  echo "This may take several minutes depending on network speed."
  echo

  local artifacts_path="${DOCLING_SERVE_ARTIFACTS_PATH:-/opt/app-root/src/.cache/docling/models}"
  docling-tools models download -o "$artifacts_path" layout tableformer picture_classifier rapidocr easyocr

  echo
  echo "Models downloaded successfully."
  echo "  Cache location: $artifacts_path"
  echo
}

do_show_version() {
  echo
  # /version endpoint is auth-exempt, always accessible
  local version_json
  version_json=$(curl -sf "http://127.0.0.1:${DOCLING_PORT}/version" 2>/dev/null)
  if [ -z "$version_json" ]; then
    exiterr "Could not retrieve version info. Is the server running?"
  fi

  echo "Docling Server Versions:"
  echo "$version_json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for key, value in data.items():
        print(f'  {key}: {value}')
except Exception:
    print('  (could not parse version response)')
" 2>/dev/null || echo "  $version_json"
  echo
}

check_container
load_config
parse_args "$@"
check_args

if [ "$show_info" = 1 ]; then
  check_server
  do_show_info
  exit 0
fi

if [ "$show_key" = 1 ]; then
  do_show_key
  exit 0
fi

if [ "$get_key" = 1 ]; then
  do_get_key
  exit 0
fi

if [ "$show_formats" = 1 ]; then
  do_show_formats
  exit 0
fi

if [ "$download_models" = 1 ]; then
  do_download_models
  exit 0
fi

if [ "$show_version" = 1 ]; then
  check_server
  do_show_version
  exit 0
fi
