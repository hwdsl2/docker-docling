[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# Docling — парсинг документов на Docker

[![Статус сборки](https://github.com/hwdsl2/docker-docling/actions/workflows/main.yml/badge.svg)](https://github.com/hwdsl2/docker-docling/actions/workflows/main.yml) &nbsp;[![Docker Pulls](https://raw.githubusercontent.com/hwdsl2/badges/main/img/docker-pulls-docling-server.svg)](https://hub.docker.com/r/hwdsl2/docling-server) &nbsp;[![License: MIT](docs/images/license.svg)](https://opensource.org/licenses/MIT)

Часть [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/README-ru.md) — разверните полный самостоятельно размещённый AI-стек одной командой.

Docker-образ для запуска самостоятельно размещённого сервера парсинга документов на базе [IBM Docling](https://github.com/docling-project/docling). Конвертирует PDF, DOCX, PPTX, XLSX, HTML, Markdown, LaTeX и другие форматы в структурированный Markdown, JSON или HTML. Простой, приватный, для самостоятельного развёртывания.

**Возможности:**

- API конвертации документов — преобразование PDF, DOCX, PPTX, HTML и других форматов в Markdown/JSON
- На базе [IBM Docling](https://github.com/docling-project/docling) — высокоточный анализ макета, OCR и распознавание структуры таблиц
- Поддержка синхронной и асинхронной конвертации, загрузки файлов и ввода по URL
- Эндпоинты чанкинга для RAG-приложений (иерархический и гибридный чанкинг)
- Опциональный веб-интерфейс (`DOCLING_ENABLE_UI`)
- Управление моделями через вспомогательный скрипт (`docling_manage`)
- Данные документов остаются на вашем сервере — никакие данные не отправляются третьим сторонам
- Ускорение на GPU NVIDIA (CUDA) для более быстрого инференса (тег образа `:cuda`)
- Офлайн-режим — работа без доступа к интернету с предварительно кэшированными моделями (`DOCLING_LOCAL_ONLY`)
- Автоматически собирается и публикуется через [GitHub Actions](https://github.com/hwdsl2/docker-docling/actions/workflows/main.yml)
- Постоянное хранение данных через Docker-том
- Поддерживаемые платформы: `linux/amd64`, `linux/arm64`

**Также доступно:**

- AI-стек: [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/README-ru.md)
- Связанные AI-сервисы: [Whisper (STT)](https://github.com/hwdsl2/docker-whisper/blob/main/README-ru.md), [Kokoro (TTS)](https://github.com/hwdsl2/docker-kokoro/blob/main/README-ru.md), [Embeddings](https://github.com/hwdsl2/docker-embeddings/blob/main/README-ru.md), [LiteLLM](https://github.com/hwdsl2/docker-litellm/blob/main/README-ru.md), [Ollama (LLM)](https://github.com/hwdsl2/docker-ollama/blob/main/README-ru.md), [MCP Gateway](https://github.com/hwdsl2/docker-mcp-gateway/blob/main/README-ru.md)

**Совет:** Docling, Whisper, Kokoro, Embeddings, LiteLLM, Ollama и MCP-шлюз можно [использовать совместно](#использование-с-другими-ai-сервисами) для построения полного self-hosted AI-стека на собственном сервере — от загрузки документов и RAG до полного голосового ввода/вывода.

## Сообщество

- 📬 [Подписаться на обновления проектов](https://selfhostedstack.beehiiv.com/subscribe?utm_campaign=ai-ru) (1–2 письма в месяц) — получить бесплатные руководства по развёртыванию AI и VPN (PDF, на английском)
- 💬 Присоединяйтесь к сообществу [r/selfhostedstack](https://www.reddit.com/r/selfhostedstack/) для обсуждений и демонстрации проектов
- ⭐ Поставьте звезду репозиторию, если он оказался вам полезен — это поможет другим пользователям его найти.

Другие проекты для самостоятельного размещения: [Setup IPsec VPN](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-ru.md), [IPsec VPN на Docker](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-ru.md), [WireGuard](https://github.com/hwdsl2/docker-wireguard/blob/main/README-ru.md), [OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/README-ru.md), [Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/README-ru.md).

## Быстрый старт

Используйте эту команду для запуска сервера парсинга документов:

```bash
docker run \
    --name docling \
    --restart=always \
    -v docling-data:/var/lib/docling \
    -p 5001:5001 \
    -d hwdsl2/docling-server
```

**Примечание:** Для развёртываний с доступом из интернета **настоятельно рекомендуется** использовать [обратный прокси](#использование-обратного-прокси) для добавления HTTPS. В этом случае также замените `-p 5001:5001` на `-p 127.0.0.1:5001:5001` в команде `docker run` выше, чтобы предотвратить прямой доступ к незашифрованному порту. Установите `DOCLING_API_KEY` в вашем `env`-файле, когда сервер доступен из публичного интернета.

<details>
<summary><strong>Использование docker-compose с GPU (NVIDIA CUDA)</strong></summary>

Для развёртывания с GPU предоставляется отдельный `docker-compose.cuda.yml`:

```bash
cp docling.env.example docling.env
# Отредактируйте docling.env по необходимости, затем:
docker compose -f docker-compose.cuda.yml up -d
docker logs docling
```

Пример `docker-compose.cuda.yml` (уже включён):

```yaml
services:
  docling:
    image: hwdsl2/docling-server:cuda
    container_name: docling
    restart: always
    ports:
      - "5001:5001/tcp"  # Для обратного прокси на хосте измените на "127.0.0.1:5001:5001/tcp"
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

Установите `DOCLING_DEVICE=cuda` (или `auto`) в env-файле для использования GPU.

</details>

<details>
<summary><strong>Быстрый старт с GPU (NVIDIA CUDA)</strong></summary>

Если у вас есть GPU NVIDIA, используйте образ `:cuda` для аппаратного ускорения инференса:

```bash
docker run \
    --name docling \
    --restart=always \
    --gpus=all \
    -v docling-data:/var/lib/docling \
    -p 5001:5001 \
    -d hwdsl2/docling-server:cuda
```

**Требования:** GPU NVIDIA, [драйвер NVIDIA](https://www.nvidia.com/en-us/drivers/) 575.57.08+ (Linux) или 576.57+ (Windows), а также установленный на хосте [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html). Образ `:cuda` поддерживает только `linux/amd64`.

</details>

Модели встроены в образ и загружаются в память при первом запуске. Проверьте логи для подтверждения готовности сервера:

```bash
docker logs docling
```

Когда вы увидите "Docling document parsing server is ready", конвертируйте ваш первый документ:

```bash
curl -X POST http://IP_вашего_сервера:5001/v1/convert/source \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

## Требования

- Linux-сервер (локальный или облачный) с установленным Docker
- Поддерживаемые архитектуры: `amd64` (x86_64), `arm64` (aarch64)
- Минимум ОЗУ: ~2 ГБ свободных (для CPU-инференса с моделями по умолчанию)
- Диск: ~4 ГБ для Docker-образа
- Доступ в интернет НЕ требуется для конвертации документов (модели встроены в образ). Интернет нужен только при загрузке документов по URL.

**Для ускорения на GPU (образ `:cuda`):**

- GPU NVIDIA с поддержкой CUDA (Compute Capability 6.0+)
- [Драйвер NVIDIA](https://www.nvidia.com/en-us/drivers/) 575.57.08+ (Linux) или 576.57+ (Windows) на хосте
- Установленный [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- Образ `:cuda` поддерживает только `linux/amd64`

Для развёртываний с доступом из интернета см. [Использование обратного прокси](#использование-обратного-прокси) для добавления HTTPS.

## Загрузка

Получите доверенную сборку из [реестра Docker Hub](https://hub.docker.com/r/hwdsl2/docling-server/):

```bash
docker pull hwdsl2/docling-server
```

Альтернативно, можно загрузить с [Quay.io](https://quay.io/repository/hwdsl2/docling-server):

```bash
docker pull quay.io/hwdsl2/docling-server
docker image tag quay.io/hwdsl2/docling-server hwdsl2/docling-server
```
Для ускорения на GPU NVIDIA используйте тег `:cuda`:

```bash
docker pull hwdsl2/docling-server:cuda
```


Поддерживаемые платформы: `linux/amd64` и `linux/arm64`. Тег `:cuda` поддерживает только `linux/amd64`.

## Переменные окружения

Все переменные опциональны. Установите `DOCLING_API_KEY` для включения аутентификации по API-ключу.

Этот Docker-образ использует следующие переменные, которые можно объявить в `env`-файле (см. [пример](docling.env.example)):

| Переменная | Описание | По умолчанию |
|---|---|---|
| `DOCLING_PORT` | HTTP-порт для API (1–65535). | `5001` |
| `DOCLING_API_KEY` | Опциональный API-ключ. При установке запросы к API конвертации/чанкинга должны содержать заголовок `X-Api-Key: <key>`. Эндпоинты здоровья и версии не требуют ключа. | *(не установлен)* |
| `DOCLING_LOG_LEVEL` | Уровень логирования: `DEBUG`, `INFO`, `WARNING`, `ERROR`. | `INFO` |
| `DOCLING_WORKERS` | Количество воркеров Uvicorn. Увеличьте для повышения пропускной способности на многоядерных системах. Каждый воркер загружает модели независимо (больше ОЗУ). | `1` |
| `DOCLING_ENABLE_UI` | Включить веб-интерфейс по адресу `/ui`. Установите `true` или `false`. | `false` |
| `DOCLING_MAX_PAGES` | Максимальное количество страниц на документ. | *(без ограничений)* |
| `DOCLING_MAX_FILE_SIZE` | Максимальный размер загружаемого файла в байтах (например, `50000000` для ~50 МБ). | *(без ограничений)* |
| `DOCLING_DEVICE` | Вычислительное устройство: `cpu`, `cuda` или `auto`. | `cpu` |
| `DOCLING_LOCAL_ONLY` | При установке любого непустого значения (например, `true`) отключает все загрузки моделей HuggingFace. Для офлайн или изолированных развёртываний. | *(не установлен)* |

**Примечание:** В `env`-файле значения можно заключать в одинарные кавычки, например `VAR='value'`. Не добавляйте пробелы вокруг `=`. При изменении `DOCLING_PORT` обновите соответственно флаг `-p` в команде `docker run`.

Пример использования `env`-файла:

```bash
cp docling.env.example docling.env
# Отредактируйте docling.env с вашими настройками, затем:
docker run \
    --name docling \
    --restart=always \
    -v docling-data:/var/lib/docling \
    -v ./docling.env:/docling.env:ro \
    -p 5001:5001 \
    -d hwdsl2/docling-server
```

Env-файл монтируется в контейнер, поэтому изменения применяются при каждом перезапуске без пересоздания контейнера.

<details>
<summary>Альтернативно, передайте через <code>--env-file</code></summary>

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

## Использование docker-compose

```bash
cp docling.env.example docling.env
# Отредактируйте docling.env по необходимости, затем:
docker compose up -d
docker logs docling
```

Пример `docker-compose.yml` (уже включён):

```yaml
services:
  docling:
    image: hwdsl2/docling-server
    container_name: docling
    restart: always
    ports:
      - "5001:5001/tcp"  # Для обратного прокси на хосте измените на "127.0.0.1:5001:5001/tcp"
    volumes:
      - docling-data:/var/lib/docling
      - ./docling.env:/docling.env:ro

volumes:
  docling-data:
    name: docling-data
```

**Примечание:** Для развёртываний с доступом из интернета настоятельно рекомендуется использовать [обратный прокси](#использование-обратного-прокси) для добавления HTTPS. В этом случае также измените `"5001:5001/tcp"` на `"127.0.0.1:5001:5001/tcp"` в `docker-compose.yml`, чтобы предотвратить прямой доступ к незашифрованному порту. Установите `DOCLING_API_KEY` в вашем `env`-файле, когда сервер доступен из публичного интернета.

## Справочник API

### Конвертация документа по URL

```
POST /v1/convert/source
Content-Type: application/json
```

**Параметры:**

| Параметр | Тип | Обязателен | Описание |
|---|---|---|---|
| `sources` | массив | ✅ | Массив объектов-источников. Каждый объект содержит `kind` (`"http"`) и `url` (URL для загрузки). |

**Пример:**

```bash
curl -X POST http://IP_вашего_сервера:5001/v1/convert/source \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

С аутентификацией по API-ключу:

```bash
curl -X POST http://IP_вашего_сервера:5001/v1/convert/source \
    -H "X-Api-Key: your_api_key" \
    -H "Content-Type: application/json" \
    -d '{"sources": [{"kind": "http", "url": "https://arxiv.org/pdf/2501.17887"}]}'
```

### Конвертация загруженного файла

```
POST /v1/convert/file
Content-Type: multipart/form-data
```

**Пример:**

```bash
curl -X POST http://IP_вашего_сервера:5001/v1/convert/file \
    -F "files=@document.pdf"
```

### Асинхронная конвертация

Для больших документов используйте асинхронные эндпоинты, чтобы избежать тайм-аутов:

```
POST /v1/convert/source/async    → возвращает task_id
GET  /v1/status/poll/{task_id}   → опрос статуса задачи
GET  /v1/result/{task_id}        → получение результата
```

### Проверка здоровья

```
GET /health    → проверка жизнеспособности (всегда возвращает 200)
GET /ready     → проверка готовности (503 пока модели не загружены)
```

### Информация о версии

```
GET /version
```

Возвращает версии docling, docling-serve и docling-core.

### Интерактивная документация API

Интерактивный Swagger UI доступен по адресу:

```
http://IP_вашего_сервера:5001/docs
```

**Примечание:** Аутентификация по API-ключу использует заголовок `X-Api-Key` (не `Authorization: Bearer`). Эндпоинты здоровья, версии и документации (`/health`, `/ready`, `/version`, `/docs`) не требуют API-ключа.

## Постоянные данные

Все данные времени выполнения хранятся в Docker-томе (`/var/lib/docling` внутри контейнера):

```
/var/lib/docling/
├── .port               # Активный порт (используется docling_manage)
├── .server_addr        # Кэшированный IP сервера (используется docling_manage)
└── hub/                # Кэш HuggingFace Hub для моделей, загруженных в runtime
```

**Примечание:** Модели конвертации документов (анализ макета, структура таблиц, OCR) встроены в Docker-образ и не требуют отдельной загрузки. Docker-том хранит только данные времени выполнения.

## Управление сервером

Используйте `docling_manage` внутри работающего контейнера для просмотра и управления сервером.

**Показать информацию о сервере:**

```bash
docker exec docling docling_manage --showinfo
```

**Показать поддерживаемые форматы:**

```bash
docker exec docling docling_manage --showformats
```

**Загрузить/обновить модели:**

```bash
docker exec docling docling_manage --downloadmodels
```

**Показать информацию о версии:**

```bash
docker exec docling docling_manage --version
```

## Поддерживаемые форматы

**Входные форматы:**

| Формат | Расширения |
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
| Изображения | `.png`, `.jpg`, `.jpeg`, `.tiff`, `.bmp`, `.gif` |

**Выходные форматы:**

| Формат | Описание |
|---|---|
| Markdown | Структурированный Markdown с таблицами |
| JSON | Полная структура документа в JSON |
| HTML | Отрендеренный HTML |
| Текст | Извлечение простого текста |
| DocTags | Внутренний формат тегов Docling |

Выходной формат контролируется для каждого запроса через API. См. интерактивную документацию по адресу `/docs` для полного описания параметров запроса.

## Защита сервера

Если ваш сервер Docling доступен из публичной сети — даже кратковременно — примените как минимум следующие меры защиты. Docling принимает загружаемые документы и выполняет ресурсоёмкий анализ на CPU/GPU, поэтому незащищённая конечная точка может быть использована для злоупотребления ресурсами и утечки данных.

**1. Установите API-ключ.** Сгенерируйте надёжный случайный ключ и задайте `DOCLING_API_KEY` в `env`-файле. После этого все запросы к API конвертации и разбивки должны содержать заголовок `X-Api-Key: <ключ>`. Эндпоинты проверки работоспособности, версии и документации остаются доступными без ключа.

```bash
# Сгенерировать 32-байтовый случайный ключ
openssl rand -hex 32
```

**2. Привяжите к localhost при использовании обратного прокси.** Замените `-p 5001:5001` на `-p 127.0.0.1:5001:5001` (или измените `"5001:5001/tcp"` на `"127.0.0.1:5001:5001/tcp"` в `docker-compose.yml`), чтобы незашифрованный порт нельзя было достичь напрямую снаружи хоста.

**3. Ограничьте размер загружаемых файлов.** Документы могут быть большими. Задайте `DOCLING_MAX_FILE_SIZE` в `env`-файле (например, `DOCLING_MAX_FILE_SIZE=50000000` для ~50 МБ) и настройте обратный прокси на применение того же ограничения (например, nginx `client_max_body_size 50M;`). Это ограничивает занимаемые одним запросом ресурсы диска и памяти.

**4. Следите за уровнем журналирования.** При `DOCLING_LOG_LEVEL=DEBUG` содержимое документов может попадать в журналы. На общих системах сохраняйте уровень `INFO` или выше.

**5. Включите CORS на прокси при вызове из браузера.** Сервер по умолчанию не устанавливает заголовки `Access-Control-Allow-Origin`; добавьте их на обратном прокси, если планируете вызывать API напрямую с веб-страницы другого источника.

**6. Рассмотрите ограничение частоты запросов.** Разместите перед сервером ограничитель частоты (например, nginx `limit_req_zone`, Caddy `rate_limit`), чтобы ограничить количество одновременных запросов конвертации документов на один IP-адрес клиента.

## Использование обратного прокси

Для развёртываний с доступом из интернета разместите обратный прокси перед сервером Docling для обработки HTTPS. Сервер работает без HTTPS в локальной или доверенной сети, но HTTPS рекомендуется при доступе API из публичного интернета.

Для доступа к контейнеру Docling из обратного прокси используйте один из следующих адресов:

- **`docling:5001`** — если обратный прокси работает как контейнер в **той же Docker-сети**, что и Docling (например, в том же `docker-compose.yml`).
- **`127.0.0.1:5001`** — если обратный прокси работает **на хосте** и порт `5001` опубликован (по умолчанию в `docker-compose.yml`).

**Пример с [Caddy](https://caddyserver.com/docs/) ([Docker-образ](https://hub.docker.com/_/caddy))** (автоматический TLS через Let's Encrypt, обратный прокси в той же Docker-сети):

`Caddyfile`:
```
docling.example.com {
  reverse_proxy docling:5001
}
```

**Пример с nginx** (обратный прокси на хосте):

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

Установите `DOCLING_API_KEY` в вашем `env`-файле, когда сервер доступен из публичного интернета.

## Обновление Docker-образа

Для обновления Docker-образа и контейнера сначала [загрузите](#загрузка) последнюю версию:

```bash
docker pull hwdsl2/docling-server
```

Если Docker-образ уже актуален, вы увидите:

```
Status: Image is up to date for hwdsl2/docling-server:latest
```

В противном случае будет загружена последняя версия. Удалите и пересоздайте контейнер:

```bash
docker rm -f docling
# Затем повторно выполните команду docker run из раздела Быстрый старт с тем же томом и портом.
```

Ваши данные времени выполнения сохранятся в томе `docling-data`.

## Использование с другими AI-сервисами

Docling, Whisper (STT), Embeddings, LiteLLM, Kokoro (TTS), Ollama (LLM) и MCP-шлюз можно комбинировать для построения полного self-hosted AI-стека на собственном сервере — от загрузки документов и семантического поиска до RAG и полного голосового ввода/вывода. Docling, Whisper, Kokoro и Embeddings работают полностью локально. Ollama выполняет весь LLM-инференс локально, данные не отправляются третьим сторонам. При использовании LiteLLM с внешними провайдерами (например, OpenAI, Anthropic) ваши данные будут отправлены этим провайдерам.

| Сервис | Роль | Порт по умолчанию |
|---|---|---|
| **[Docling](https://github.com/hwdsl2/docker-docling/blob/main/README-ru.md)** | Конвертирует документы (PDF, DOCX, HTML и др.) в структурированный текст | `5001` |
| **[Embeddings](https://github.com/hwdsl2/docker-embeddings/blob/main/README-ru.md)** | Преобразует текст в векторы для семантического поиска и RAG | `8000` |
| **[Whisper (STT)](https://github.com/hwdsl2/docker-whisper/blob/main/README-ru.md)** | Транскрибирует речь в текст | `9000` |
| **[LiteLLM](https://github.com/hwdsl2/docker-litellm/blob/main/README-ru.md)** | AI-шлюз — маршрутизирует запросы к OpenAI, Anthropic, Ollama и 100+ провайдерам | `4000` |
| **[Kokoro (TTS)](https://github.com/hwdsl2/docker-kokoro/blob/main/README-ru.md)** | Преобразует текст в естественную речь | `8880` |
| **[Ollama (LLM)](https://github.com/hwdsl2/docker-ollama/blob/main/README-ru.md)** | Запускает локальные LLM-модели (llama3, qwen, mistral и др.) | `11434` |
| **[MCP-шлюз](https://github.com/hwdsl2/docker-mcp-gateway/blob/main/README-ru.md)** | Предоставляет AI-сервисы как MCP-инструменты для AI-ассистентов (Claude, Cursor и др.) | `3000` |

**См. также: [Self-Hosted AI Stack](https://github.com/hwdsl2/self-hosted-ai-stack/blob/main/README-ru.md)** — разверните полный стек одной командой с готовыми конфигурациями и примерами пайплайнов.

## Технические детали

- Базовый образ: `ghcr.io/docling-project/docling-serve-cpu:latest` (CentOS Stream 9), CUDA: `ghcr.io/docling-project/docling-serve:latest`
- Движок парсинга: [IBM Docling](https://github.com/docling-project/docling) с [Docling Serve](https://github.com/docling-project/docling-serve) API
- API: RESTful эндпоинты `/v1/convert/*` и `/v1/chunk/*` (на FastAPI/Uvicorn)
- Модели: Анализ макета, распознавание структуры таблиц, OCR — встроены в образ
- Каталог данных: `/var/lib/docling` (Docker-том для данных времени выполнения)
- Аутентификация: Опциональный заголовок `X-Api-Key` (эндпоинты здоровья/версии освобождены)

## Лицензия

**Примечание:** Программные компоненты внутри предсобранного образа (такие как IBM Docling и его зависимости) распространяются под лицензиями, выбранными их правообладателями. При использовании предсобранного образа пользователь несёт ответственность за соблюдение всех лицензий программного обеспечения, содержащегося в образе.

Copyright (C) 2026 Lin Song   
Эта работа лицензирована под [лицензией MIT](https://opensource.org/licenses/MIT).

**Docling** и **Docling Serve** — Copyright (C) 2024 International Business Machines, распространяются под [лицензией MIT](https://github.com/docling-project/docling/blob/main/LICENSE).

Этот проект является независимой Docker-обёрткой для IBM Docling и не связан с International Business Machines (IBM), не одобрен и не спонсируется ею.
