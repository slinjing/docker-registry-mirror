#!/bin/bash
set -e

# 安装Docker Compose（Linux x86_64/arm64）
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  COMPOSE_ARCH="docker-compose-linux-x86_64"
elif [ "$ARCH" = "aarch64" ]; then
  COMPOSE_ARCH="docker-compose-linux-aarch64"
else
  echo "不支持的架构：$ARCH"
  exit 1
fi

# 下载最新稳定版（可替换为指定版本）
LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
curl -SL https://github.com/docker/compose/releases/download/$LATEST_VERSION/$COMPOSE_ARCH -o /usr/local/bin/docker-compose

# 赋予执行权限
chmod +x /usr/local/bin/docker-compose

# 验证安装
echo "Docker Compose 安装完成，版本："
docker-compose --version