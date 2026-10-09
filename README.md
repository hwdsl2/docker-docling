[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# ParseCrate

**Open-source, self-hosted document processing API.**

[![Build Status](https://github.com/hwdsl2/parsecrate/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/parsecrate/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-docling-server.svg)](https://hub.docker.com/r/hwdsl2/docling-server) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT)

ParseCrate is a self-hosted document processing API powered by [Docling](https://github.com/docling-project/docling) and [docling-serve](https://github.com/docling-project/docling-serve). Convert PDF, DOCX, PPTX, XLSX, HTML, Markdown, LaTeX, and other supported formats into structured Markdown, JSON, or HTML on your own server. Deploy with Docker on CPU or an NVIDIA GPU.

> Previously known as **docker-docling**, maintained by [hwdsl2](https://github.com/hwdsl2). The Docker image remains `hwdsl2/docling-server`; existing configuration, API endpoints, and persistent data remain compatible.

**Features:**

- **Document conversion API:** convert PDF, DOCX, PPTX, HTML, and more to Markdown/JSON.
- **Private, local processing:** document data stays on your server and is not sent to third parties.
- **Layout, OCR, and tables:** powered by [IBM Docling](https://github.com/docling-project/docling) for high-accuracy layout analysis, OCR, and table structure recognition.
- **Flexible input and processing:** synchronous and asynchronous conversion with file uploads or URL-based input.
- **RAG chunking:** hierarchical and hybrid chunking endpoints for RAG applications.
- **Web playground:** optional web UI playground enabled with `DOCLING_ENABLE_UI`.
- **CPU and GPU support:** run on CPU or use the `:cuda` image for NVIDIA GPU acceleration.
- **Offline operation:** run without internet access using pre-cached models (`DOCLING_LOCAL_ONLY`).
- **Automated builds:** images are automatically built and published through [GitHub Actions](https://github.com/hwdsl2/parsecrate/actions).

Also available as part of the [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack), which deploys a complete self-hosted AI stack with a single command.

> 📘 [The Self-Hosted AI Builder’s Guide](https://books2read.com/aiguide?store=amazon) is a practical guide to building, securing, and operating your own private AI stack.

**Also available:**

- Related AI services: [ScribeCrate](https://github.com/hwdsl2/scribecrate), [SpeakCrate](https://github.com/hwdsl2/speakcrate), [EmbedCrate](https://github.com/hwdsl2/embedcrate), [GatewayCrate](https://github.com/hwdsl2/gatewaycrate), [InferCrate](https://github.com/hwdsl2/infercrate), [ToolUplink](https://github.com/hwdsl2/tooluplink)

## Quick start

Use this command to set up a ParseCrate server:

```bash
docker run \
    --name docling \
    --restart=always \
    -v docling-data:/var/lib/docling \
    -p 5001:5001 \
    -d hwdsl2/docling-server
```

> [!NOTE]
> For internet-facing deployments, use a [reverse proxy](#using-a-reverse-proxy) to add HTTPS. Also replace `-p 5001:5001` with `-p 127.0.0.1:5001:5001` in the `docker run` command above, to prevent direct access to the unencrypted port.

<details>
<summary><strong>Using docker-compose with GPU (NVIDIA CUDA)</strong></summary>

A separate `docker-compose.cuda.yml` is provided for GPU deployments:

```bash
cp docling.env.example docling.env
# Edit docling.env as needed, then:
docker compose -f docker-compose.cuda.yml up -d
docker logs docling
```

Example `docker-compose.cuda.yml` (already included):

```yaml
services:
  docling:
    image: hwdsl2/docling-server:cuda
    container_name: docling
    restart: always
    ports:
      - "5001:5001/tcp"  # For a host-based reverse proxy, change to "127.0.0.1:5001:5001/tcp"
    volumes:
      - docling-data:/var/lib/docling
      - ./docling.env:/docling.env:ro
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

volumes:
  docling-data:
    name: docling-data
```

Set `DOCLING_DEVICE=cuda` (or `auto`) in your env file to use the GPU.

</details>

<details>
<summary><strong>GPU quick start (NVIDIA CUDA)</strong></summary>

If you have an NVIDIA GPU, use the `:cuda` image for hardware-accelerated inference:

```bash
docker run \
    --name docling \
    --restart=always \
    --gpus=all \
    -v docling-data:/var/lib/docling \
    -p 5001:5001 \
    -d hwdsl2/docling-server:cuda
```

**Requirements:** NVIDIA GPU, [NVIDIA driver](https://www.nvidia.com/en-us/drivers/) 575.57.08+ (Linux) or 576.57+ (Windows), and the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed on the host. The `:cuda` image is `linux/amd64` only.

</details>

Models are baked into the image and loaded into memory on first start. Check the logs to confirm the server is ready:

```bash
docker logs docling
```

Once you see "ParseCrate document parsing server is ready", convert your first document:

Fresh persistent installations require an API key. Retrieve it for the following examples:

```bash
parse_api_key="$(docker exec docling docling_manage --getkey)"
```

```bash
curl -X POST http://your_server_ip:5001/v1/convert/source \
    -H "X-Api-Key: $parse_api_key" \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

## Community

- 📬 [Get project updates and free deployment guides](https://selfhostedstack.beehiiv.com/subscribe?utm_campaign=ai) (1–2 emails/month)
- 💬 Join the [r/selfhostedstack](https://www.reddit.com/r/selfhostedstack/) community for discussions and showcases
- ⭐ Star the repository if you find it useful — it helps others discover it

<details>
<summary>Self-hosted VPN & networking projects</summary>

- [Setup IPsec VPN](https://github.com/hwdsl2/setup-ipsec-vpn)
- [IPsec VPN on Docker](https://github.com/hwdsl2/docker-ipsec-vpn-server)
- [WireGuard](https://github.com/hwdsl2/docker-wireguard)
- [OpenVPN](https://github.com/hwdsl2/docker-openvpn)
- [Headscale](https://github.com/hwdsl2/docker-headscale)

</details>

## Requirements

- A Linux server (local or cloud) with Docker installed
- Supported architectures: `amd64` (x86_64), `arm64` (aarch64)
- Minimum RAM: ~2 GB free (for CPU inference with default models)
- Disk: ~4 GB for the Docker image
- Internet access is NOT required for document conversion (models are baked into the image). Internet is needed only if fetching documents from URLs.

**For GPU acceleration (`:cuda` image):**

- NVIDIA GPU with CUDA support (Compute Capability 6.0+)
- [NVIDIA driver](https://www.nvidia.com/en-us/drivers/) 575.57.08+ (Linux) or 576.57+ (Windows) installed on the host
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed
- The `:cuda` image supports `linux/amd64` only

For internet-facing deployments, see [Using a reverse proxy](#using-a-reverse-proxy) to add HTTPS.

## Download

Get the trusted build from the [Docker Hub registry](https://hub.docker.com/r/hwdsl2/docling-server/):

```bash
docker pull hwdsl2/docling-server
```

Alternatively, you may download from [Quay.io](https://quay.io/repository/hwdsl2/docling-server):

```bash
docker pull quay.io/hwdsl2/docling-server
docker image tag quay.io/hwdsl2/docling-server hwdsl2/docling-server
```

For NVIDIA GPU acceleration, pull the `:cuda` tag instead:

```bash
docker pull hwdsl2/docling-server:cuda
```

Supported platforms: `linux/amd64` and `linux/arm64`. The `:cuda` tag supports `linux/amd64` only.

## Environment variables

All variables are optional. Fresh installs with a mounted `/var/lib/docling` volume auto-generate an API key. Existing installs without a key remain open for backward compatibility.

This Docker image uses the following variables, that can be declared in an `env` file (see [example](docling.env.example)):

| Variable | Description | Default |
|---|---|---|
| `DOCLING_PORT` | HTTP port for the API (1–65535). | `5001` |
| `DOCLING_API_KEY` | Optional API key. Fresh persistent installs auto-generate one. If set, conversion/chunk API requests must include `X-Api-Key: <key>` header. Health and version endpoints do not require the key. Set explicitly empty to disable authentication. | Auto-generated for fresh persistent installs |
| `DOCLING_LOG_LEVEL` | Log level: `DEBUG`, `INFO`, `WARNING`, `ERROR`. | `INFO` |
| `DOCLING_WORKERS` | Number of Uvicorn workers. Increase for higher throughput on multi-core systems. Each worker loads models independently (higher RAM). | `1` |
| `DOCLING_ENABLE_UI` | Enable the web UI playground at `/ui`. Set to `true` or `false`. | `false` |
| `DOCLING_MAX_PAGES` | Maximum number of pages per document. | *(unlimited)* |
| `DOCLING_MAX_FILE_SIZE` | Maximum file size for uploads in bytes (e.g. `50000000` for ~50 MB). | *(unlimited)* |
| `DOCLING_DEVICE` | Compute device: `cpu`, `cuda`, or `auto`. | `cpu` |
| `DOCLING_LOCAL_ONLY` | When set to any non-empty value (e.g. `true`), disables all HuggingFace model downloads. For offline or air-gapped deployments. | *(not set)* |
| `DOCLING_DISABLE_USAGE_COUNTS` | Set to `1` to disable anonymous aggregate usage counts. | *(not set)* |

**Note:** In your `env` file, you may enclose values in single quotes, e.g. `VAR='value'`. Do not add spaces around `=`. If you change `DOCLING_PORT`, update the `-p` flag in the `docker run` command accordingly.

Example using an `env` file:

```bash
cp docling.env.example docling.env
# Edit docling.env with your settings, then:
docker run \
    --name docling \
    --restart=always \
    -v docling-data:/var/lib/docling \
    -v ./docling.env:/docling.env:ro \
    -p 5001:5001 \
    -d hwdsl2/docling-server
```

The env file is bind-mounted into the container, so changes are picked up on every restart without recreating the container.

<details>
<summary>Alternatively, pass it with <code>--env-file</code></summary>

```bash
docker run \
    --name docling \
    --restart=always \
    -v docling-data:/var/lib/docling \
    -p 5001:5001 \
    --env-file=docling.env \
    -d hwdsl2/docling-server
```

</details>

## Using docker-compose

```bash
cp docling.env.example docling.env
# Edit docling.env as needed, then:
docker compose up -d
docker logs docling
```

Example `docker-compose.yml` (already included):

```yaml
services:
  docling:
    image: hwdsl2/docling-server
    container_name: docling
    restart: always
    ports:
      - "5001:5001/tcp"  # For a host-based reverse proxy, change to "127.0.0.1:5001:5001/tcp"
    volumes:
      - docling-data:/var/lib/docling
      - ./docling.env:/docling.env:ro

volumes:
  docling-data:
    name: docling-data
```

> [!NOTE]
> For internet-facing deployments, use a [reverse proxy](#using-a-reverse-proxy) to add HTTPS. Also change `"5001:5001/tcp"` to `"127.0.0.1:5001:5001/tcp"` in `docker-compose.yml`, to prevent direct access to the unencrypted port.

## API reference

Fresh persistent installations require an API key. Retrieve it for the following examples:

```bash
parse_api_key="$(docker exec docling docling_manage --getkey)"
```

If API key authentication is disabled, omit the `X-Api-Key` header.

### Convert a document from URL

```
POST /v1/convert/source
Content-Type: application/json
```

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `sources` | array | ✅ | Array of source objects. Each object has `kind` (`"http"`) and `url` (URL to fetch). |

**Example:**

```bash
curl -X POST http://your_server_ip:5001/v1/convert/source \
    -H "X-Api-Key: $parse_api_key" \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

With API key authentication:

```bash
curl -X POST http://your_server_ip:5001/v1/convert/source \
    -H "X-Api-Key: $parse_api_key" \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

### Convert an uploaded file

```
POST /v1/convert/file
Content-Type: multipart/form-data
```

**Example:**

```bash
curl -X POST http://your_server_ip:5001/v1/convert/file \
    -H "X-Api-Key: $parse_api_key" \
    -F "files=@document.pdf"
```

### Async conversion

For large documents, use async endpoints to avoid timeouts:

```
POST /v1/convert/source/async    → returns task_id
GET  /v1/status/poll/{task_id}   → poll task status
GET  /v1/result/{task_id}        → retrieve result
```

### Health check

```
GET /health    → liveness check (always returns 200)
GET /ready     → readiness check (503 until models are loaded)
```

### Version info

```
GET /version
```

Returns docling, docling-serve, and docling-core versions.

### Interactive API docs

A full interactive Swagger UI is available at:

```
http://your_server_ip:5001/docs
```

**Note:** API key authentication uses the `X-Api-Key` header (not `Authorization: Bearer`). Health, version, and documentation endpoints (`/health`, `/ready`, `/version`, `/docs`) do not require the API key.

## Persistent data

All runtime data is stored in the Docker volume (`/var/lib/docling` inside the container):

```
/var/lib/docling/
├── .port               # Active port (used by docling_manage)
├── .server_addr        # Cached server IP (used by docling_manage)
└── hub/                # HuggingFace Hub cache for runtime-downloaded models
```

**Note:** Document conversion models (layout, table structure, OCR) are baked into the Docker image and do not need to be downloaded separately. The Docker volume stores runtime data only.

## Managing the server

Use `docling_manage` inside the running container to inspect and manage the server.

**Show server info:**

```bash
docker exec docling docling_manage --showinfo
```

**List supported formats:**

```bash
docker exec docling docling_manage --showformats
```

**Download/update models:**

```bash
docker exec docling docling_manage --downloadmodels
```

**Show version info:**

```bash
docker exec docling docling_manage --version
```

## Supported formats

**Input formats:**

| Format | Extensions |
|---|---|
| PDF | `.pdf` |
| Microsoft Word | `.docx` |
| Microsoft PowerPoint | `.pptx` |
| Microsoft Excel | `.xlsx` |
| HTML | `.html`, `.htm` |
| Markdown | `.md` |
| LaTeX | `.tex` |
| AsciiDoc | `.adoc`, `.asciidoc` |
| CSV | `.csv` |
| Images | `.png`, `.jpg`, `.jpeg`, `.tiff`, `.bmp`, `.gif` |

**Output formats:**

| Format | Description |
|---|---|
| Markdown | Structured Markdown with tables |
| JSON | Full document structure as JSON |
| HTML | Rendered HTML output |
| Text | Plain text extraction |
| DocTags | Docling's internal tagged format |

Output format is controlled per-request via the API. See the interactive API docs at `/docs` for full request options.

## Securing your server

If your ParseCrate server is reachable from the public internet — even briefly — apply at minimum these protections. ParseCrate accepts uploaded documents and performs CPU/GPU-intensive parsing, making an unprotected endpoint a target for resource abuse and data leakage.

**1. Use an API key.** Fresh installs with a mounted `/var/lib/docling` volume auto-generate an API key. Display it with `docker exec docling docling_manage --showkey`, or use `docker exec docling docling_manage --getkey` in scripts. Existing installs without a key remain open for backward compatibility; set `DOCLING_API_KEY` in your `env` file to enable authentication manually. Conversion and chunking API requests must include `X-Api-Key: <key>`. Health, version, and documentation endpoints remain accessible without the key.

```bash
# Generate a 32-byte random key
openssl rand -hex 32
```

**2. Bind to localhost when fronted by a reverse proxy.** Replace `-p 5001:5001` with `-p 127.0.0.1:5001:5001` (or change `"5001:5001/tcp"` to `"127.0.0.1:5001:5001/tcp"` in `docker-compose.yml`) so the unencrypted port is not reachable directly from outside the host.

**3. Limit upload size.** Document files can be large. Set `DOCLING_MAX_FILE_SIZE` in your `env` file (e.g. `DOCLING_MAX_FILE_SIZE=50000000` for ~50 MB) and configure your reverse proxy to enforce the same limit (e.g. nginx `client_max_body_size 50M;`). This bounds the disk and memory footprint of a single request.

**4. Mind the log level.** `DOCLING_LOG_LEVEL=DEBUG` may write document content to logs. Keep it at `INFO` or higher on shared systems.

**5. Enable CORS at the proxy if calling from a browser.** The server does not set `Access-Control-Allow-Origin` headers by default; add them at your reverse proxy if you intend to call the API directly from a web page on a different origin.

**6. Consider rate limiting.** Place a rate-limit (e.g. nginx `limit_req_zone`, Caddy `rate_limit`) in front of the server to cap concurrent document conversion requests per client IP.

## Using a reverse proxy

For internet-facing deployments, place a reverse proxy in front of the ParseCrate server to handle HTTPS termination. The server works without HTTPS on a local or trusted network, but HTTPS is recommended when the API endpoint is exposed to the internet.

Use one of the following addresses to reach the ParseCrate container from your reverse proxy:

- **`docling:5001`** — if your reverse proxy runs as a container in the **same Docker network** as the ParseCrate server (e.g. defined in the same `docker-compose.yml`).
- **`127.0.0.1:5001`** — if your reverse proxy runs **on the host** and port `5001` is published (the default `docker-compose.yml` publishes it).

**Example with [Caddy](https://caddyserver.com/docs/) ([Docker image](https://hub.docker.com/_/caddy))** (automatic TLS via Let's Encrypt, reverse proxy in the same Docker network):

`Caddyfile`:
```
docling.example.com {
  reverse_proxy docling:5001
}
```

**Example with nginx** (reverse proxy on the host):

```nginx
server {
    listen 443 ssl;
    server_name docling.example.com;

    ssl_certificate     /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass         http://127.0.0.1:5001;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
    }
}
```

## Update Docker image

To update the Docker image and container, first [download](#download) the latest version:

```bash
docker pull hwdsl2/docling-server
```

If the Docker image is already up to date, you should see:

```
Status: Image is up to date for hwdsl2/docling-server:latest
```

Otherwise, it will download the latest version. Remove and re-create the container:

```bash
docker rm -f docling
# Then re-run the docker run command from Quick start with the same volume and port.
```

Your runtime data is preserved in the `docling-data` volume.

## Using with other AI services

ParseCrate can be used as the document conversion service in a broader self-hosted AI setup.

For full and lightweight Docker Compose stacks, manual `docker run` examples, and voice/RAG/MCP pipeline examples with SpeakCrate, EmbedCrate, GatewayCrate, InferCrate, ParseCrate, and ToolUplink, see [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack).

## Usage counts

This image uses public GitHub release asset download counts for anonymous, aggregate usage counts. Counts are approximate and are not unique users or active installs. The image does not send a telemetry payload or use a private collector. It only attempts the best-effort count after the server starts successfully with a mounted `/var/lib/docling` volume, and again when that persistent install first runs a different image build. To opt out, set `DOCLING_DISABLE_USAGE_COUNTS=1`.

## Technical details

- Base image: `ghcr.io/docling-project/docling-serve-cpu:latest` (CentOS Stream 9), CUDA: `ghcr.io/docling-project/docling-serve:latest`
- Document parsing engine: [IBM Docling](https://github.com/docling-project/docling) with [Docling Serve](https://github.com/docling-project/docling-serve) API
- API: RESTful `/v1/convert/*` and `/v1/chunk/*` endpoints (served by FastAPI/Uvicorn)
- Models: Layout analysis, table structure recognition, OCR — baked into the image
- Data directory: `/var/lib/docling` (Docker volume for runtime data)
- Authentication: Optional `X-Api-Key` header (health/version endpoints exempt)

## License

**Note:** The software components inside the pre-built image (such as IBM Docling and its dependencies) are under the respective licenses chosen by their respective copyright holders. As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

Copyright (C) 2026 Lin Song   
This work is licensed under the [MIT License](https://opensource.org/licenses/MIT).

**Docling** and **Docling Serve** are Copyright (C) 2024 International Business Machines, and are distributed under the [MIT License](https://github.com/docling-project/docling/blob/main/LICENSE).

This project is an independent Docker setup for IBM Docling and is not affiliated with, endorsed by, or sponsored by International Business Machines (IBM).
