# Docker-Registry-Mirror 镜像加速器
本项目参考了 Docker-Proxy 项目，基于官方 Registry + Nginx 反向代理构建，是一款支持 多架构（AMD64/ARM64/ARMv7 等） 的 Docker 镜像加速代理服务。核心解决 Docker Hub、k8s.gcr.io、ghcr.io 等主流仓库因网络限制导致的拉取缓慢 / 失败问题，同时完美兼容多架构镜像分发，满足不同硬件环境（如 x86 服务器、ARM 开发板）的使用需求。


## ✨ 功能特点
- 支持 Docker Hub、k8s.gcr.io、ghcr.io 等主流镜像仓库的代理加速
- 基于 Docker Compose 一键部署，操作简单
- 可配置 SSL 证书，保障通信安全
- 支持客户端通过简单配置实现镜像加速拉取


## 🚀 快速部署
### 前置条件
- 服务器：ARM/AMD64 架构，开放 80（证书申请）、443（HTTPS）端口
- 域名：已解析到服务器 IP，本项目使用免费域名托管至 Cloudflare
- 环境：已安装 Docker（20.10+）


### 1. 克隆项目
```bash
git clone https://github.com/slinjing/docker-registry-mirror.git
cd docker-registry-mirror
```

### 2. 安装 Docker Compose（若未安装）
```bash
# 执行安装脚本
chmod +x scripts/install-docker-compose.sh
./scripts/install-docker-compose.sh
```

### 3. 申请 HTTPS 证书
```bash
# 安装 Certbot
apt install -y certbot

# 申请证书（替换为你的域名和邮箱）
certbot certonly --standalone -d your-domain.com --email your-email@xxx.com --agree-tos --non-interactive

# 复制证书到项目目录
mkdir -p certs
cp /etc/letsencrypt/live/your-domain.com/fullchain.pem certs/
cp /etc/letsencrypt/live/your-domain.com/privkey.pem certs/
chmod -R 644 certs/
```

### 4. 修改 nginx 配置文件
将 server_name 字段的值改为自己的域名，并且确保证书路径一致。

```bash
    server {
        listen       443 ssl;  
        server_name  your-domain.com;  # 替换为你的域名

        # Certbot 证书路径
        ssl_certificate      /etc/nginx/certs/fullchain.pem;
        ssl_certificate_key  /etc/nginx/certs/privkey.pem;
```

### 5. 启动服务
```bash
# 启动镜像加速器（后台运行）
docker-compose up -d

# 查看服务状态（Status 为 Up 则正常）
docker-compose ps
```

### 6. 证书自动续期
添加定时任务，自动续期 Let's Encrypt 证书（有效期 90 天）：
```bash
# 编辑定时任务
crontab -e

# 添加以下内容（每月1号凌晨3点续期）
0 3 1 * * certbot renew --quiet && cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /path/to/docker-registry-mirror/certs/ && cp /etc/letsencrypt/live/your-domain.com/privkey.pem /path/to/docker-registry-mirror/certs/ && docker-compose restart
```


## 📖 使用指南
### 1. Docker 客户端配置
编辑 Docker 配置文件 `/etc/docker/daemon.json：`
```bash
{
    "registry-mirrors": ["https://your-domain.com"],
    "log-opts": {
        "max-size": "100m",
        "max-file": "5"
    }
}
```

重启 Docker 生效：
```bash
systemctl daemon-reload && systemctl restart docker
```

### 2. 拉取镜像
拉取 Docker Hub 镜像：直接使用 docker pull + 镜像名 即可，例如：
```bash
docker pull nginx:latest
docker pull redis:alpine
```

拉取其他仓库镜像：需要在镜像名称前加上你的域名，例如拉取 k8s.gcr.io 仓库的镜像：
```bash
docker pull your-domain.com/k8s.gcr.io/kube-apiserver:v1.19.0
```



## 📄 许可证
本项目基于 MIT 许可证 开源，欢迎 Fork、Star 和贡献代码！

## 🤝 贡献
1. Fork 本仓库
2. 创建特性分支（git checkout -b feature/xxx）
3. 提交修改（git commit -m 'Add xxx feature'）
4. 推送分支（git push origin feature/xxx）
5. 发起 Pull Request

