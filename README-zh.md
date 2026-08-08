[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# Docling 文档解析 Docker 镜像

[![构建状态](https://github.com/hwdsl2/docker-docling/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/docker-docling/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-docling-server.svg)](https://hub.docker.com/r/hwdsl2/docling-server) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT)

[Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/README-zh.md) 的一部分 ─ 一条命令部署完整的自托管 AI 技术栈。

使用 [IBM Docling](https://github.com/docling-project/docling) 在 Docker 容器中运行文档解析服务器。将 PDF、DOCX、PPTX、XLSX、HTML、Markdown、LaTeX 等格式转换为结构化的 Markdown、JSON 或 HTML 输出。简单、私密、可自托管。

**功能特性：**

- 文档转文本 API — 将 PDF、DOCX、PPTX、HTML 等转换为 Markdown/JSON
- 由 [IBM Docling](https://github.com/docling-project/docling) 驱动 — 高精度的版面分析、OCR 和表格结构识别
- 支持同步和异步转换，文件上传和基于 URL 的输入
- 为 RAG 应用提供分块端点（分层分块和混合分块）
- 可选的 Web UI 演示界面 (`DOCLING_ENABLE_UI`)
- 通过辅助脚本 (`docling_manage`) 管理模型
- 文档数据留在您的服务器上，不发送给第三方
- NVIDIA GPU (CUDA) 加速推理（使用 `:cuda` 镜像标签）
- 离线/隔离网络模式 — 使用预先缓存的模型无需互联网访问 (`DOCLING_LOCAL_ONLY`)
- 通过 [GitHub Actions](https://github.com/hwdsl2/docker-docling/actions) 自动构建和发布
- 通过 Docker 数据卷持久化数据
- 支持平台：`linux/amd64`、`linux/arm64`

**另提供：**

- AI 套件：[Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/README-zh.md)
- 相关 AI 服务：[Whisper](https://github.com/hwdsl2/docker-whisper/blob/main/README-zh.md)、[Kokoro](https://github.com/hwdsl2/docker-kokoro/blob/main/README-zh.md)、[Embeddings](https://github.com/hwdsl2/docker-embeddings/blob/main/README-zh.md)、[LiteLLM](https://github.com/hwdsl2/docker-litellm/blob/main/README-zh.md)、[Ollama](https://github.com/hwdsl2/docker-ollama/blob/main/README-zh.md)、[MCP Gateway](https://github.com/hwdsl2/docker-mcp-gateway/blob/main/README-zh.md)
- 图书：[The Self-Hosted AI Builder’s Guide](https://books2read.com/aiguide?store=amazon)——在完整的私有 AI 技术栈中使用此服务

## 社区

- 📬 [订阅项目更新](https://selfhostedstack.beehiiv.com/subscribe?utm_campaign=ai-zh)（每月 1–2 封邮件）——获取免费的 AI 和 VPN 部署指南（PDF，英文）
- 💬 加入 [r/selfhostedstack](https://www.reddit.com/r/selfhostedstack/) 社区，参与讨论和项目展示
- ⭐ 如果你觉得本项目有用，请为仓库加星——这有助于让更多人发现它。

<details>
<summary>自托管 VPN 和网络项目</summary>

- [Setup IPsec VPN](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-zh.md)
- [Docker 上的 IPsec VPN](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md)
- [WireGuard](https://github.com/hwdsl2/docker-wireguard/blob/main/README-zh.md)
- [OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/README-zh.md)
- [Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/README-zh.md)

</details>

## 快速开始

使用以下命令启动文档解析服务器：

```bash
docker run \
    --name docling \
    --restart=always \
    -v docling-data:/var/lib/docling \
    -p 5001:5001 \
    -d hwdsl2/docling-server
```

**注：** 如需面向互联网的部署，**强烈建议**使用[反向代理](#使用反向代理)来添加 HTTPS。此时，还应将上述 `docker run` 命令中的 `-p 5001:5001` 替换为 `-p 127.0.0.1:5001:5001`，以防止从外部直接访问未加密端口。

<details>
<summary><strong>使用 docker-compose 配合 GPU（NVIDIA CUDA）</strong></summary>

为 GPU 部署提供了单独的 `docker-compose.cuda.yml`：

```bash
cp docling.env.example docling.env
# 按需编辑 docling.env，然后：
docker compose -f docker-compose.cuda.yml up -d
docker logs docling
```

`docker-compose.cuda.yml` 示例（已包含在仓库中）：

```yaml
services:
  docling:
    image: hwdsl2/docling-server:cuda
    container_name: docling
    restart: always
    ports:
      - "5001:5001/tcp"  # 使用主机反向代理时，改为 "127.0.0.1:5001:5001/tcp"
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

在 env 文件中设置 `DOCLING_DEVICE=cuda`（或 `auto`）以使用 GPU。

</details>

<details>
<summary><strong>GPU 快速开始（NVIDIA CUDA）</strong></summary>

如果您有 NVIDIA GPU，可使用 `:cuda` 镜像进行硬件加速推理：

```bash
docker run \
    --name docling \
    --restart=always \
    --gpus=all \
    -v docling-data:/var/lib/docling \
    -p 5001:5001 \
    -d hwdsl2/docling-server:cuda
```

**要求：** NVIDIA GPU、[NVIDIA 驱动](https://www.nvidia.com/en-us/drivers/) 575.57.08+（Linux）或 576.57+（Windows），以及主机上已安装 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)。`:cuda` 镜像仅支持 `linux/amd64`。

</details>

模型已内置在镜像中，首次启动时加载到内存。查看日志确认服务器已就绪：

```bash
docker logs docling
```

看到 "Docling document parsing server is ready" 后，转换您的第一个文档：

```bash
curl -X POST http://您的服务器IP:5001/v1/convert/source \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

## 系统要求

- 已安装 Docker 的 Linux 服务器（本地或云端）
- 支持的架构：`amd64`（x86_64）、`arm64`（aarch64）
- 最低内存：约 2 GB 可用（使用默认模型进行 CPU 推理）
- 磁盘：Docker 镜像约 4 GB
- 文档转换**不需要**互联网访问（模型已内置在镜像中）。仅在从 URL 获取文档时需要网络。

**GPU 加速（`:cuda` 镜像）要求：**

- 支持 CUDA 的 NVIDIA GPU（计算能力 6.0+）
- 主机已安装 [NVIDIA 驱动](https://www.nvidia.com/en-us/drivers/) 575.57.08+（Linux）或 576.57+（Windows）
- 已安装 [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- `:cuda` 镜像仅支持 `linux/amd64`

如需面向公网部署，请参阅[使用反向代理](#使用反向代理)以启用 HTTPS。

## 下载

从 [Docker Hub](https://hub.docker.com/r/hwdsl2/docling-server/) 获取可信构建：

```bash
docker pull hwdsl2/docling-server
```

也可从 [Quay.io](https://quay.io/repository/hwdsl2/docling-server) 下载：

```bash
docker pull quay.io/hwdsl2/docling-server
docker image tag quay.io/hwdsl2/docling-server hwdsl2/docling-server
```

如需 NVIDIA GPU 加速，请拉取 `:cuda` 标签：

```bash
docker pull hwdsl2/docling-server:cuda
```

支持平台：`linux/amd64` 和 `linux/arm64`。`:cuda` 标签仅支持 `linux/amd64`。

## 环境变量

所有变量均为可选。挂载 `/var/lib/docling` 数据卷的新安装会自动生成 API 密钥。没有密钥的既有安装会保持开放以兼容旧行为。

此 Docker 镜像使用以下变量，可在 `env` 文件中声明（参见[示例](docling.env.example)）：

| 变量 | 说明 | 默认值 |
|---|---|---|
| `DOCLING_PORT` | API 的 HTTP 端口（1–65535）。 | `5001` |
| `DOCLING_API_KEY` | 可选的 API 密钥。新持久化安装会自动生成。设置后，转换/分块 API 请求须包含 `X-Api-Key: <key>` 头。健康检查和版本端点不需要密钥。显式设置为空可禁用认证。 | 新持久化安装自动生成 |
| `DOCLING_LOG_LEVEL` | 日志级别：`DEBUG`、`INFO`、`WARNING`、`ERROR`。 | `INFO` |
| `DOCLING_WORKERS` | Uvicorn 工作进程数。在多核系统上增加可提高吞吐量。每个工作进程独立加载模型（更高内存）。 | `1` |
| `DOCLING_ENABLE_UI` | 在 `/ui` 启用 Web UI 演示界面。设为 `true` 或 `false`。 | `false` |
| `DOCLING_MAX_PAGES` | 每个文档的最大页数。 | *（无限制）* |
| `DOCLING_MAX_FILE_SIZE` | 上传文件的最大大小（字节），如 `50000000` 表示约 50 MB。 | *（无限制）* |
| `DOCLING_DEVICE` | 计算设备：`cpu`、`cuda` 或 `auto`。 | `cpu` |
| `DOCLING_LOCAL_ONLY` | 设为任意非空值（如 `true`）时，禁止所有 HuggingFace 模型下载。适用于离线或隔离网络部署。 | *（未设置）* |
| `DOCLING_DISABLE_USAGE_COUNTS` | 设为 `1` 可禁用匿名聚合使用计数。 | *（未设置）* |

**注：** 在 `env` 文件中，值可用单引号括起，例如 `VAR='value'`。`=` 两侧不要有空格。如更改 `DOCLING_PORT`，请相应更新 `docker run` 命令中的 `-p` 参数。

使用 `env` 文件的示例：

```bash
cp docling.env.example docling.env
# 编辑 docling.env 配置您的设置，然后：
docker run \
    --name docling \
    --restart=always \
    -v docling-data:/var/lib/docling \
    -v ./docling.env:/docling.env:ro \
    -p 5001:5001 \
    -d hwdsl2/docling-server
```

`env` 文件以绑定挂载方式传入容器，每次重启时自动生效，无需重建容器。

<details>
<summary>也可通过 <code>--env-file</code> 传入</summary>

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
# 按需编辑 docling.env，然后：
docker compose up -d
docker logs docling
```

示例 `docker-compose.yml`（已包含在项目中）：

```yaml
services:
  docling:
    image: hwdsl2/docling-server
    container_name: docling
    restart: always
    ports:
      - "5001:5001/tcp"  # 如使用主机反向代理，改为 "127.0.0.1:5001:5001/tcp"
    volumes:
      - docling-data:/var/lib/docling
      - ./docling.env:/docling.env:ro

volumes:
  docling-data:
    name: docling-data
```

**注：** 如需面向公网部署，强烈建议使用[反向代理](#使用反向代理)启用 HTTPS。此时请将 `docker-compose.yml` 中的 `"5001:5001/tcp"` 改为 `"127.0.0.1:5001:5001/tcp"`，以防止未加密端口被直接访问。

## API 参考

### 通过 URL 转换文档

```
POST /v1/convert/source
Content-Type: application/json
```

**参数：**

| 参数 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `sources` | 数组 | ✅ | 源对象数组。每个对象包含 `kind`（`"http"`）和 `url`（要获取的 URL）。 |

**示例：**

```bash
curl -X POST http://您的服务器IP:5001/v1/convert/source \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

使用 API 密钥认证：

```bash
curl -X POST http://您的服务器IP:5001/v1/convert/source \
    -H "X-Api-Key: your_api_key" \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

### 上传文件转换

```
POST /v1/convert/file
Content-Type: multipart/form-data
```

**示例：**

```bash
curl -X POST http://您的服务器IP:5001/v1/convert/file \
    -F "files=@document.pdf"
```

### 异步转换

对于大型文档，使用异步端点以避免超时：

```
POST /v1/convert/source/async    → 返回 task_id
GET  /v1/status/poll/{task_id}   → 查询任务状态
GET  /v1/result/{task_id}        → 获取结果
```

### 健康检查

```
GET /health    → 存活检查（始终返回 200）
GET /ready     → 就绪检查（模型加载完成前返回 503）
```

### 版本信息

```
GET /version
```

返回 docling、docling-serve 和 docling-core 版本。

### 交互式 API 文档

可在以下地址访问交互式 Swagger UI：

```
http://您的服务器IP:5001/docs
```

**注：** API 密钥认证使用 `X-Api-Key` 头（不是 `Authorization: Bearer`）。健康检查、版本和文档端点（`/health`、`/ready`、`/version`、`/docs`）不需要 API 密钥。

## 持久化数据

所有运行时数据存储在 Docker 数据卷（容器内的 `/var/lib/docling`）中：

```
/var/lib/docling/
├── .port               # 当前端口（供 docling_manage 使用）
├── .server_addr        # 缓存的服务器 IP（供 docling_manage 使用）
└── hub/                # HuggingFace Hub 缓存（运行时下载的模型）
```

**注：** 文档转换模型（版面分析、表格结构、OCR）已内置在 Docker 镜像中，无需单独下载。Docker 数据卷仅存储运行时数据。

## 管理服务器

在运行中的容器内使用 `docling_manage` 来查看和管理服务器。

**显示服务器信息：**

```bash
docker exec docling docling_manage --showinfo
```

**列出支持的格式：**

```bash
docker exec docling docling_manage --showformats
```

**下载/更新模型：**

```bash
docker exec docling docling_manage --downloadmodels
```

**显示版本信息：**

```bash
docker exec docling docling_manage --version
```

## 支持的格式

**输入格式：**

| 格式 | 扩展名 |
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
| 图片 | `.png`、`.jpg`、`.jpeg`、`.tiff`、`.bmp`、`.gif` |

**输出格式：**

| 格式 | 说明 |
|---|---|
| Markdown | 结构化 Markdown，包含表格 |
| JSON | 完整文档结构的 JSON |
| HTML | 渲染后的 HTML 输出 |
| 文本 | 纯文本提取 |
| DocTags | Docling 的内部标签格式 |

输出格式通过 API 按请求控制。请参阅 `/docs` 上的交互式 API 文档了解完整请求选项。

## 保护你的服务器

如果你的 Docling 服务器可从公网访问 —— 即使只是短暂可达 —— 也请至少采取以下保护措施。Docling 接受上传的文档并进行 CPU/GPU 密集型解析，未做防护的接口可能遭受资源滥用和数据泄露。

**1. 使用 API 密钥。** 挂载 `/var/lib/docling` 数据卷的新安装会自动生成 API 密钥。可用 `docker exec docling docling_manage --showkey` 查看；脚本中可用 `docker exec docling docling_manage --getkey`。没有密钥的既有安装会保持开放以兼容旧行为；也可以在 `env` 文件中设置 `DOCLING_API_KEY` 手动启用认证。转换和分块 API 请求必须包含 `X-Api-Key: <key>`。健康检查、版本和文档端点无需密钥即可访问。

```bash
# 生成 32 字节的随机密钥
openssl rand -hex 32
```

**2. 在反向代理后面时绑定到 localhost。** 将 `-p 5001:5001` 替换为 `-p 127.0.0.1:5001:5001`（或在 `docker-compose.yml` 中将 `"5001:5001/tcp"` 改为 `"127.0.0.1:5001:5001/tcp"`），使未加密端口无法从主机外部直接访问。

**3. 限制上传大小。** 文档文件可能很大。在 `env` 文件中设置 `DOCLING_MAX_FILE_SIZE`（例如 `DOCLING_MAX_FILE_SIZE=50000000` 约为 50 MB），并配置反向代理强制相同限制（例如 nginx `client_max_body_size 50M;`），从而限制单个请求占用的磁盘和内存。

**4. 注意日志级别。** `DOCLING_LOG_LEVEL=DEBUG` 可能会将文档内容写入日志。在共享系统上请保持 `INFO` 或更高级别。

**5. 浏览器调用时在代理处启用 CORS。** 本服务器默认不设置 `Access-Control-Allow-Origin` 响应头；若需在不同源的网页中直接调用本 API，请在反向代理处添加 CORS 头。

**6. 考虑限流。** 在服务器前部署限流（如 nginx `limit_req_zone`、Caddy `rate_limit`），限制每个客户端 IP 的并发文档转换请求数。

## 使用反向代理

如需面向公网部署，可在文档解析服务器前置反向代理处理 HTTPS 终止。在本地或可信网络中使用无需 HTTPS，但将 API 端点暴露在公网时建议启用 HTTPS。

从反向代理访问 Docling 容器时使用以下地址之一：

- **`docling:5001`** — 如果反向代理作为容器运行在与 Docling 服务器**同一 Docker 网络**中（例如定义在同一 `docker-compose.yml` 中）。
- **`127.0.0.1:5001`** — 如果反向代理运行在**主机上**且端口 `5001` 已发布（默认 `docker-compose.yml` 会发布该端口）。

**使用 [Caddy](https://caddyserver.com/docs/)（[Docker 镜像](https://hub.docker.com/_/caddy)）的示例**（自动 Let's Encrypt TLS，反向代理在同一 Docker 网络中）：

`Caddyfile`：
```
docling.example.com {
  reverse_proxy docling:5001
}
```

**使用 nginx 的示例**（反向代理运行在主机上）：

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

## 更新 Docker 镜像

如需更新 Docker 镜像和容器，首先[下载](#下载)最新版本：

```bash
docker pull hwdsl2/docling-server
```

如果镜像已是最新版本，您将看到：

```
Status: Image is up to date for hwdsl2/docling-server:latest
```

否则将下载最新版本。删除并重新创建容器：

```bash
docker rm -f docling
# 然后使用相同的数据卷和端口重新运行快速开始中的 docker run 命令。
```

您的运行时数据将保留在 `docling-data` 数据卷中。

## 与其他 AI 服务配合使用

Docling 可作为更广泛的自托管 AI 设置中的文档转换服务。

如需完整和轻量级 Docker Compose 技术栈、手动 `docker run` 示例，以及结合 Kokoro、Embeddings、LiteLLM、Ollama、Docling 和 MCP Gateway 的语音/RAG/MCP 流水线示例，请参阅 [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/README-zh.md)。

## 使用计数

此镜像使用公开的 GitHub Release 资源下载次数进行匿名聚合使用计数。计数是近似值，不代表唯一用户或活跃安装。镜像不会发送遥测负载，也不会使用私有收集器。仅当服务器成功启动且挂载了 `/var/lib/docling` 卷后，才会以尽力而为方式计数；当该持久化安装首次运行不同镜像构建时，也会再次计数。要退出，请设置 `DOCLING_DISABLE_USAGE_COUNTS=1`。

## 技术细节

- 基础镜像：`ghcr.io/docling-project/docling-serve-cpu:latest`（CentOS Stream 9），CUDA：`ghcr.io/docling-project/docling-serve:latest`
- 文档解析引擎：[IBM Docling](https://github.com/docling-project/docling) 配合 [Docling Serve](https://github.com/docling-project/docling-serve) API
- API：RESTful `/v1/convert/*` 和 `/v1/chunk/*` 端点（由 FastAPI/Uvicorn 提供）
- 模型：版面分析、表格结构识别、OCR — 已内置在镜像中
- 数据目录：`/var/lib/docling`（Docker 数据卷，用于运行时数据）
- 认证：可选的 `X-Api-Key` 头（健康检查/版本端点不受限）

## 授权协议

**注：** 预构建镜像中包含的软件组件（如 IBM Docling 及其依赖项）均受各自版权持有者所选许可证约束。使用预构建镜像时，用户有责任确保其使用方式符合镜像内所有软件的相关许可证要求。

版权所有 (C) 2026 Lin Song   
本作品采用 [MIT 许可证](https://opensource.org/licenses/MIT)授权。

**Docling** 和 **Docling Serve** 版权归 International Business Machines（2024）所有，依据 [MIT 许可证](https://github.com/docling-project/docling/blob/main/LICENSE) 分发。

本项目是 IBM Docling 的独立 Docker 封装，与 International Business Machines (IBM) 无关联，未获其背书或赞助。
