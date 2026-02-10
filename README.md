# hapi-docker

Docker image for HAPI Runner with Claude Code & Codex support.

## Quick Start

### 1. Docker 部署（Server + Runner）

```bash
# 克隆仓库
git clone https://github.com/CherryLover/hapi-docker.git
cd hapi-docker

# 复制并修改配置
cp docker-compose.yml docker-compose.override.yml
# 编辑 docker-compose.override.yml，填入你的实际配置

# 创建数据目录
mkdir -p hapi-data data

# 启动
docker compose up -d
```

### 2. 本地 Runner 注册

在已安装 `hapi` 的本地机器上（macOS / Linux），设置环境变量后启动 runner：

```bash
export HAPI_API_URL=https://your-hapi-server.example.com
export CLI_API_TOKEN=your-hapi-token
hapi runner start
```

如需持久化，将以上 `export` 添加到 `~/.zshrc`（macOS）或 `~/.bashrc`（Linux）中。

## 运行模式

通过 `HAPI_MODE` 环境变量控制：

| HAPI_MODE | 说明 | 适用场景 |
|-----------|------|----------|
| （不设置） | 仅 Runner | 其他机器作为 runner 接入 |
| `server` | 仅 Server | 只需要 server 的场景 |
| `all` | Server + Runner | 单机同时运行 server 和 runner |

## 环境变量

### 基础配置

| 变量 | 说明 | 必填 |
|------|------|------|
| `HAPI_API_URL` | HAPI Server 地址 | Runner 模式必填 |
| `CLI_API_TOKEN` | HAPI 认证 Token | 是 |

### Server 模式配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `HAPI_MODE` | 运行模式 | runner |
| `HAPI_LISTEN_HOST` | 监听地址 | `127.0.0.1` |
| `HAPI_LISTEN_PORT` | 监听端口 | `3006` |
| `HAPI_PUBLIC_URL` | 公开访问地址 | `http://localhost:3006` |

### AI 服务配置

| 变量 | 说明 |
|------|------|
| `ANTHROPIC_API_KEY` | Claude Code API Key |
| `ANTHROPIC_BASE_URL` | 自定义 Anthropic API 地址（可选） |

### Codex 配置

Codex 通过 `~/.codex/config.toml` 配置。可以将配置文件通过 volume 挂载到容器中：

```yaml
volumes:
  - ./codex-config:/home/claude/.codex
```

`config.toml` 示例：

```toml
model_provider = "openai"
model = "gpt-5.2-codex"
model_reasoning_effort = "xhigh"
disable_response_storage = true

[model_providers.openai]
name = "OpenAI"
base_url = "https://api.openai.com/v1"
wire_api = "responses"
env_key = "OPENAI_API_KEY"
```

如使用自定义代理，修改 `base_url` 和 `env_key` 即可。

## 反向代理（Traefik）

如果使用 Traefik 作为反向代理，在 `docker-compose.yml` 中添加：

```yaml
services:
  hapi-runner:
    # ... 其他配置
    networks:
      - default
      - traefik-network
    labels:
      - traefik.enable=true
      - traefik.http.routers.hapi-server.rule=Host(`your-domain.example.com`)
      - traefik.http.routers.hapi-server.entrypoints=websecure
      - traefik.http.routers.hapi-server.tls.certresolver=letsencrypt
      - traefik.http.services.hapi-server.loadbalancer.server.port=3006

networks:
  traefik-network:
    external: true
```

## 构建镜像

```bash
# 本地构建
docker compose build

# 或直接使用预构建镜像
docker pull ghcr.io/cherrylover/hapi-docker:latest
```

## 目录结构

```
.
├── Dockerfile           # 镜像定义
├── entrypoint.sh        # 启动脚本，支持多种运行模式
├── docker-compose.yml   # Compose 模板
└── .github/workflows/   # GitHub Actions 自动构建
```

## 注意事项

- 容器内使用 `claude` 用户（UID/GID: 1000），挂载目录需确保权限匹配
- 首次启动前创建数据目录：`mkdir -p hapi-data data && chown -R 1000:1000 hapi-data data`
- Server 模式需要设置 `HAPI_LISTEN_HOST=0.0.0.0` 才能从容器外访问
