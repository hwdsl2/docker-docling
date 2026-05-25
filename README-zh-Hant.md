[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# Docling 文件解析 Docker 映像

[![建置狀態](https://github.com/hwdsl2/docker-docling/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/docker-docling/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-docling-server.svg)](https://hub.docker.com/r/hwdsl2/docling-server) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT)

[Docker AI Stack](https://github.com/hwdsl2/docker-ai-stack/blob/main/README-zh-Hant.md) 的一部分 ─ 一條命令部署完整的自託管 AI 技術棧。

使用 [IBM Docling](https://github.com/docling-project/docling) 在 Docker 容器中執行文件解析伺服器。將 PDF、DOCX、PPTX、XLSX、HTML、Markdown、LaTeX 等格式轉換為結構化的 Markdown、JSON 或 HTML 輸出。簡單、私密、可自架。

**功能特性：**

- 文件轉文字 API — 將 PDF、DOCX、PPTX、HTML 等轉換為 Markdown/JSON
- 由 [IBM Docling](https://github.com/docling-project/docling) 驅動 — 高精度的版面分析、OCR 和表格結構辨識
- 支援同步和非同步轉換，檔案上傳和基於 URL 的輸入
- 為 RAG 應用程式提供分塊端點（階層式分塊和混合分塊）
- 可選的 Web UI 示範介面 (`DOCLING_ENABLE_UI`)
- 透過輔助腳本 (`docling_manage`) 管理模型
- 文件資料留在您的伺服器上，不傳送給第三方
- NVIDIA GPU (CUDA) 加速推論（使用 `:cuda` 映像標籤）
- 離線/隔離網路模式 — 使用預先快取的模型無需網際網路連線 (`DOCLING_LOCAL_ONLY`)
- 透過 [GitHub Actions](https://github.com/hwdsl2/docker-docling/actions/workflows/main.yml) 自動建置並發布
- 透過 Docker 資料卷持久化資料
- 支援平台：`linux/amd64`、`linux/arm64`

**另提供：**

- AI/音訊：[Whisper (STT)](https://github.com/hwdsl2/docker-whisper/blob/main/README-zh-Hant.md)、[Kokoro (TTS)](https://github.com/hwdsl2/docker-kokoro/blob/main/README-zh-Hant.md)、[Embeddings](https://github.com/hwdsl2/docker-embeddings/blob/main/README-zh-Hant.md)、[LiteLLM](https://github.com/hwdsl2/docker-litellm/blob/main/README-zh-Hant.md)、[Ollama (LLM)](https://github.com/hwdsl2/docker-ollama/blob/main/README-zh-Hant.md)
- VPN：[WireGuard](https://github.com/hwdsl2/docker-wireguard/blob/main/README-zh-Hant.md)、[OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/README-zh-Hant.md)、[IPsec VPN](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh-Hant.md)、[Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/README-zh-Hant.md)
- 工具：[MCP Gateway](https://github.com/hwdsl2/docker-mcp-gateway/blob/main/README-zh-Hant.md)

**提示：** Docling、Whisper、Kokoro、Embeddings、LiteLLM、Ollama 和 MCP 閘道可以[搭配使用](#與其他-ai-服務搭配使用)，在您自己的伺服器上建立完整的自託管 AI 系統 — 從文件匯入和 RAG 到完整的語音輸入/輸出。

## 社群

- 訂閱專案更新（每月 1-2 封郵件）：[Self-Hosted Stack](https://selfhostedstack.beehiiv.com/subscribe?utm_campaign=ai)
- 社群討論與展示：[r/selfhostedstack](https://www.reddit.com/r/selfhostedstack/)

## 快速開始

使用以下命令啟動文件解析伺服器：

```bash
docker run \
    --name docling \
    --restart=always \
    -v docling-data:/var/lib/docling \
    -p 5001:5001 \
    -d hwdsl2/docling-server
```

**注：** 如需面向網際網路的部署，**強烈建議**使用[反向代理](#使用反向代理)來新增 HTTPS。此時，還應將上述 `docker run` 命令中的 `-p 5001:5001` 替換為 `-p 127.0.0.1:5001:5001`，以防止從外部直接存取未加密連接埠。當伺服器可從公網存取時，請在 `env` 檔案中設定 `DOCLING_API_KEY`。

<details>
<summary><strong>使用 docker-compose 搭配 GPU（NVIDIA CUDA）</strong></summary>

為 GPU 部署提供了獨立的 `docker-compose.cuda.yml`：

```bash
cp docling.env.example docling.env
# 按需編輯 docling.env，然後：
docker compose -f docker-compose.cuda.yml up -d
docker logs docling
```

`docker-compose.cuda.yml` 範例（已包含在儲存庫中）：

```yaml
services:
  docling:
    image: hwdsl2/docling-server:cuda
    container_name: docling
    restart: always
    ports:
      - "5001:5001/tcp"  # 使用主機反向代理時，改為 "127.0.0.1:5001:5001/tcp"
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

在 env 檔案中設定 `DOCLING_DEVICE=cuda`（或 `auto`）以使用 GPU。

</details>

<details>
<summary><strong>GPU 快速開始（NVIDIA CUDA）</strong></summary>

如果您有 NVIDIA GPU，可使用 `:cuda` 映像進行硬體加速推論：

```bash
docker run \
    --name docling \
    --restart=always \
    --gpus=all \
    -v docling-data:/var/lib/docling \
    -p 5001:5001 \
    -d hwdsl2/docling-server:cuda
```

**需求：** NVIDIA GPU、[NVIDIA 驅動程式](https://www.nvidia.com/en-us/drivers/) 535+，以及主機上已安裝 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)。`:cuda` 映像僅支援 `linux/amd64`。

</details>

模型已內建在映像中，首次啟動時載入記憶體。查看日誌確認伺服器已就緒：

```bash
docker logs docling
```

看到 "Docling document parsing server is ready" 後，轉換您的第一個文件：

```bash
curl -X POST http://您的伺服器IP:5001/v1/convert/source \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

## 系統需求

- 已安裝 Docker 的 Linux 伺服器（本機或雲端）
- 支援的架構：`amd64`（x86_64）、`arm64`（aarch64）
- 最低記憶體：約 2 GB 可用（使用預設模型進行 CPU 推論）
- 磁碟：Docker 映像約 4 GB
- 文件轉換**不需要**網際網路連線（模型已內建在映像中）。僅在從 URL 取得文件時需要網路。

**GPU 加速（`:cuda` 映像）需求：**

- 支援 CUDA 的 NVIDIA GPU（計算能力 6.0+）
- 主機已安裝 [NVIDIA 驅動程式](https://www.nvidia.com/en-us/drivers/) 535 或更新版本
- 已安裝 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- `:cuda` 映像僅支援 `linux/amd64`

如需面向公網部署，請參閱[使用反向代理](#使用反向代理)以啟用 HTTPS。

## 下載

從 [Docker Hub](https://hub.docker.com/r/hwdsl2/docling-server/) 取得可信建置：

```bash
docker pull hwdsl2/docling-server
```

也可從 [Quay.io](https://quay.io/repository/hwdsl2/docling-server) 下載：

```bash
docker pull quay.io/hwdsl2/docling-server
docker image tag quay.io/hwdsl2/docling-server hwdsl2/docling-server
```
如需 NVIDIA GPU 加速，請拉取 `:cuda` 標籤：

```bash
docker pull hwdsl2/docling-server:cuda
```


支援平台：`linux/amd64` 和 `linux/arm64`。`:cuda` 標籤僅支援 `linux/amd64`。

## 環境變數

所有變數均為可選。設定 `DOCLING_API_KEY` 可啟用 API 金鑰認證。

此 Docker 映像使用以下變數，可在 `env` 檔案中宣告（參見[範例](docling.env.example)）：

| 變數 | 說明 | 預設值 |
|---|---|---|
| `DOCLING_PORT` | API 的 HTTP 連接埠（1–65535）。 | `5001` |
| `DOCLING_API_KEY` | 可選的 API 金鑰。設定後，轉換/分塊 API 請求須包含 `X-Api-Key: <key>` 標頭。健康檢查和版本端點不需要金鑰。 | *（未設定）* |
| `DOCLING_LOG_LEVEL` | 日誌等級：`DEBUG`、`INFO`、`WARNING`、`ERROR`。 | `INFO` |
| `DOCLING_WORKERS` | Uvicorn 工作程序數。在多核心系統上增加可提高吞吐量。每個工作程序獨立載入模型（更高記憶體）。 | `1` |
| `DOCLING_ENABLE_UI` | 在 `/ui` 啟用 Web UI 示範介面。設為 `true` 或 `false`。 | `false` |
| `DOCLING_MAX_PAGES` | 每個文件的最大頁數。 | *（無限制）* |
| `DOCLING_MAX_FILE_SIZE` | 上傳檔案的最大大小（位元組），如 `50000000` 表示約 50 MB。 | *（無限制）* |
| `DOCLING_DEVICE` | 運算裝置：`cpu`、`cuda` 或 `auto`。 | `cpu` |
| `DOCLING_LOCAL_ONLY` | 設為任意非空值（如 `true`）時，禁止所有 HuggingFace 模型下載。適用於離線或隔離網路部署。 | *（未設定）* |

**注：** 在 `env` 檔案中，值可用單引號括起，例如 `VAR='value'`。`=` 兩側不要有空格。如更改 `DOCLING_PORT`，請相應更新 `docker run` 命令中的 `-p` 參數。

使用 `env` 檔案的範例：

```bash
cp docling.env.example docling.env
# 編輯 docling.env 設定您的選項，然後：
docker run \
    --name docling \
    --restart=always \
    -v docling-data:/var/lib/docling \
    -v ./docling.env:/docling.env:ro \
    -p 5001:5001 \
    -d hwdsl2/docling-server
```

`env` 檔案以繫結掛載方式傳入容器，每次重啟時自動生效，無需重建容器。

<details>
<summary>也可透過 <code>--env-file</code> 傳入</summary>

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

## 使用 docker-compose

```bash
cp docling.env.example docling.env
# 按需編輯 docling.env，然後：
docker compose up -d
docker logs docling
```

範例 `docker-compose.yml`（已包含在專案中）：

```yaml
services:
  docling:
    image: hwdsl2/docling-server
    container_name: docling
    restart: always
    ports:
      - "5001:5001/tcp"  # 如使用主機反向代理，改為 "127.0.0.1:5001:5001/tcp"
    volumes:
      - docling-data:/var/lib/docling
      - ./docling.env:/docling.env:ro

volumes:
  docling-data:
    name: docling-data
```

**注：** 如需面向公網部署，強烈建議使用[反向代理](#使用反向代理)啟用 HTTPS。此時請將 `docker-compose.yml` 中的 `"5001:5001/tcp"` 改為 `"127.0.0.1:5001:5001/tcp"`，以防止未加密連接埠被直接存取。當伺服器可從公網存取時，請在 `env` 檔案中設定 `DOCLING_API_KEY`。

## API 參考

### 透過 URL 轉換文件

```
POST /v1/convert/source
Content-Type: application/json
```

**參數：**

| 參數 | 類型 | 必填 | 說明 |
|---|---|---|---|
| `sources` | 陣列 | ✅ | 來源物件陣列。每個物件包含 `kind`（`"http"`）和 `url`（要取得的 URL）。 |

**範例：**

```bash
curl -X POST http://您的伺服器IP:5001/v1/convert/source \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

使用 API 金鑰認證：

```bash
curl -X POST http://您的伺服器IP:5001/v1/convert/source \
    -H "X-Api-Key: your_api_key" \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

### 上傳檔案轉換

```
POST /v1/convert/file
Content-Type: multipart/form-data
```

**範例：**

```bash
curl -X POST http://您的伺服器IP:5001/v1/convert/file \
    -F "files=@document.pdf"
```

### 非同步轉換

對於大型文件，使用非同步端點以避免逾時：

```
POST /v1/convert/source/async    → 回傳 task_id
GET  /v1/status/poll/{task_id}   → 查詢任務狀態
GET  /v1/result/{task_id}        → 取得結果
```

### 健康檢查

```
GET /health    → 存活檢查（始終回傳 200）
GET /ready     → 就緒檢查（模型載入完成前回傳 503）
```

### 版本資訊

```
GET /version
```

回傳 docling、docling-serve 和 docling-core 版本。

### 互動式 API 文件

可在以下位址存取互動式 Swagger UI：

```
http://您的伺服器IP:5001/docs
```

**注：** API 金鑰認證使用 `X-Api-Key` 標頭（不是 `Authorization: Bearer`）。健康檢查、版本和文件端點（`/health`、`/ready`、`/version`、`/docs`）不需要 API 金鑰。

## 持久化資料

所有執行階段資料儲存在 Docker 資料卷（容器內的 `/var/lib/docling`）中：

```
/var/lib/docling/
├── .port               # 目前連接埠（供 docling_manage 使用）
├── .server_addr        # 快取的伺服器 IP（供 docling_manage 使用）
└── hub/                # HuggingFace Hub 快取（執行階段下載的模型）
```

**注：** 文件轉換模型（版面分析、表格結構、OCR）已內建在 Docker 映像中，無需另外下載。Docker 資料卷僅儲存執行階段資料。

## 管理伺服器

在執行中的容器內使用 `docling_manage` 來檢視和管理伺服器。

**顯示伺服器資訊：**

```bash
docker exec docling docling_manage --showinfo
```

**列出支援的格式：**

```bash
docker exec docling docling_manage --showformats
```

**下載/更新模型：**

```bash
docker exec docling docling_manage --downloadmodels
```

**顯示版本資訊：**

```bash
docker exec docling docling_manage --version
```

## 支援的格式

**輸入格式：**

| 格式 | 副檔名 |
|---|---|
| PDF | `.pdf` |
| Microsoft Word | `.docx` |
| Microsoft PowerPoint | `.pptx` |
| Microsoft Excel | `.xlsx` |
| HTML | `.html`、`.htm` |
| Markdown | `.md` |
| LaTeX | `.tex` |
| AsciiDoc | `.adoc`、`.asciidoc` |
| CSV | `.csv` |
| 圖片 | `.png`、`.jpg`、`.jpeg`、`.tiff`、`.bmp`、`.gif` |

**輸出格式：**

| 格式 | 說明 |
|---|---|
| Markdown | 結構化 Markdown，包含表格 |
| JSON | 完整文件結構的 JSON |
| HTML | 轉譯後的 HTML 輸出 |
| 文字 | 純文字擷取 |
| DocTags | Docling 的內部標籤格式 |

輸出格式透過 API 按請求控制。請參閱 `/docs` 上的互動式 API 文件了解完整請求選項。

## 使用反向代理

如需面向公網部署，可在文件解析伺服器前置反向代理處理 HTTPS 終止。在本機或可信網路中使用無需 HTTPS，但將 API 端點暴露在公網時建議啟用 HTTPS。

從反向代理存取 Docling 容器時使用以下位址之一：

- **`docling:5001`** — 如果反向代理作為容器執行在與 Docling 伺服器**同一 Docker 網路**中（例如定義在同一 `docker-compose.yml` 中）。
- **`127.0.0.1:5001`** — 如果反向代理執行在**主機上**且連接埠 `5001` 已發布（預設 `docker-compose.yml` 會發布該連接埠）。

**使用 [Caddy](https://caddyserver.com/docs/)（[Docker 映像](https://hub.docker.com/_/caddy)）的範例**（自動 Let's Encrypt TLS，反向代理在同一 Docker 網路中）：

`Caddyfile`：
```
docling.example.com {
  reverse_proxy docling:5001
}
```

**使用 nginx 的範例**（反向代理執行在主機上）：

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

如伺服器對公網開放，請在 `env` 檔案中設定 `DOCLING_API_KEY`。

## 更新 Docker 映像

如需更新 Docker 映像和容器，首先[下載](#下載)最新版本：

```bash
docker pull hwdsl2/docling-server
```

如果映像已是最新版本，您將看到：

```
Status: Image is up to date for hwdsl2/docling-server:latest
```

否則將下載最新版本。刪除並重新建立容器：

```bash
docker rm -f docling
# 然後使用相同的資料卷和連接埠重新執行快速開始中的 docker run 命令。
```

您的執行階段資料將保留在 `docling-data` 資料卷中。

## 與其他 AI 服務搭配使用

Docling、Whisper (STT)、Embeddings、LiteLLM、Kokoro (TTS)、Ollama (LLM) 和 MCP 閘道 映像可以組合使用，在您自己的伺服器上建立完整的自託管 AI 系統 — 從文件匯入和語意搜尋到 RAG 和完整的語音輸入/輸出。Docling、Whisper、Kokoro 和 Embeddings 完全在本機執行。Ollama 在本機執行所有 LLM 推論，無需向第三方傳送資料。如果您將 LiteLLM 設定為使用外部供應商（例如 OpenAI、Anthropic），您的資料將被傳送至這些供應商處理。

| 服務 | 功能 | 預設連接埠 |
|---|---|---|
| **[Docling](https://github.com/hwdsl2/docker-docling/blob/main/README-zh-Hant.md)** | 將文件（PDF、DOCX、HTML 等）轉換為結構化文字 | `5001` |
| **[Embeddings](https://github.com/hwdsl2/docker-embeddings/blob/main/README-zh-Hant.md)** | 將文字轉換為向量，用於語意搜尋和 RAG | `8000` |
| **[Whisper (STT)](https://github.com/hwdsl2/docker-whisper/blob/main/README-zh-Hant.md)** | 將語音音訊轉錄為文字 | `9000` |
| **[LiteLLM](https://github.com/hwdsl2/docker-litellm/blob/main/README-zh-Hant.md)** | AI 閘道——將請求路由至 OpenAI、Anthropic、Ollama 及 100+ 其他供應商 | `4000` |
| **[Kokoro (TTS)](https://github.com/hwdsl2/docker-kokoro/blob/main/README-zh-Hant.md)** | 將文字轉換為自然語音 | `8880` |
| **[Ollama (LLM)](https://github.com/hwdsl2/docker-ollama/blob/main/README-zh-Hant.md)** | 執行本機 LLM 模型（llama3、qwen、mistral 等） | `11434` |
| **[MCP 閘道](https://github.com/hwdsl2/docker-mcp-gateway/blob/main/README-zh-Hant.md)** | 將 AI 服務作為 MCP 工具暴露給 AI 助手（Claude、Cursor 等） | `3000` |

**另請參閱：[Docker AI Stack](https://github.com/hwdsl2/docker-ai-stack)** — 一條命令即可部署完整技術堆疊，提供現成的組態和管線範例。

## 技術細節

- 基礎映像：`ghcr.io/docling-project/docling-serve-cpu:latest`（CentOS Stream 9），CUDA：`ghcr.io/docling-project/docling-serve:latest`
- 文件解析引擎：[IBM Docling](https://github.com/docling-project/docling) 搭配 [Docling Serve](https://github.com/docling-project/docling-serve) API
- API：RESTful `/v1/convert/*` 和 `/v1/chunk/*` 端點（由 FastAPI/Uvicorn 提供）
- 模型：版面分析、表格結構辨識、OCR — 已內建在映像中
- 資料目錄：`/var/lib/docling`（Docker 資料卷，用於執行階段資料）
- 認證：可選的 `X-Api-Key` 標頭（健康檢查/版本端點不受限）

## 授權條款

**注：** 預建置映像中包含的軟體元件（如 IBM Docling 及其相依性）均受各自版權持有者所選授權條款約束。使用預建置映像時，使用者有責任確保其使用方式符合映像內所有軟體的相關授權條款要求。

版權所有 (C) 2026 Lin Song   
本作品採用 [MIT 授權條款](https://opensource.org/licenses/MIT)授權。

**Docling** 和 **Docling Serve** 版權歸 International Business Machines（2024）所有，依據 [MIT 授權條款](https://github.com/docling-project/docling/blob/main/LICENSE) 散布。

本專案是 IBM Docling 的獨立 Docker 封裝，與 International Business Machines (IBM) 無關聯，未獲其背書或贊助。