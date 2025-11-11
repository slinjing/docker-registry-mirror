# Docker 多架构多仓库镜像加速器
基于 Docker Registry + Cloudflare 自建镜像加速器，支持 ARM/AMD64 多架构，适配 Docker Hub、K8s 官方仓库（registry.k8s.io/k8s.gcr.io）、GCR、Quay.io 等主流镜像仓库，解决镜像拉取慢、访问受限问题。


## ✨ 核心特性
- **多仓库支持**：Docker Hub、registry.k8s.io、k8s.gcr.io、gcr.io、quay.io
- **多架构兼容**：自动适配 ARM64（arm）、AMD64（x86_64）客户端
- **HTTPS 加密**：基于 Let's Encrypt 免费证书，安全无风险
- **缓存管理**：100G 缓存容量，LRU 自动清理最久未使用镜像
- **Cloudflare 适配**：支持 CF 代理模式，域名访问稳定可靠
- **K8s 兼容**：支持 Containerd/Docker 运行时，无缝集成 K8s 集群


## 🚀 快速部署（管理员操作）
### 前置条件
- 服务器：ARM/AMD64 架构，开放 80（证书申请）、443（HTTPS）端口
- 域名：已解析到服务器 IP（如 `csg.cloudns.ch`），托管至 Cloudflare
- 环境：已安装 Docker（20.10+）


### 1. 克隆项目
```bash
git clone https://github.com/你的用户名/docker-registry-mirror.git
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
certbot certonly --standalone -d csg.cloudns.ch --email your-email@xxx.com --agree-tos --non-interactive

# 复制证书到项目目录
mkdir -p certs
cp /etc/letsencrypt/live/csg.cloudns.ch/fullchain.pem certs/
cp /etc/letsencrypt/live/csg.cloudns.ch/privkey.pem certs/
chmod -R 644 certs/
```

### 4. 启动服务
```bash
# 启动镜像加速器（后台运行）
docker-compose up -d

# 查看服务状态（Status 为 Up 则正常）
docker-compose ps
```

### 5. 证书自动续期
添加定时任务，自动续期 Let's Encrypt 证书（有效期 90 天）：
```bash
# 编辑定时任务
crontab -e

# 添加以下内容（每月1号凌晨3点续期）
0 3 1 * * certbot renew --quiet && cp /etc/letsencrypt/live/csg.cloudns.ch/fullchain.pem /path/to/docker-registry-mirror/certs/ && cp /etc/letsencrypt/live/csg.cloudns.ch/privkey.pem /path/to/docker-registry-mirror/certs/ && docker-compose restart
```


## 📖 使用指南
### 1. Docker 客户端配置
编辑 Docker 配置文件 `/etc/docker/daemon.json：`
```bash
{
  "registry-mirrors": ["https://csg.cloudns.ch"],
  "registry-config": {
    "k8s.gcr.io": { "mirror": ["https://csg.cloudns.ch"] },
    "registry.k8s.io": { "mirror": ["https://csg.cloudns.ch"] },
    "gcr.io": { "mirror": ["https://csg.cloudns.ch"] },
    "quay.io": { "mirror": ["https://csg.cloudns.ch"] }
  }
}
```

重启 Docker 生效：
```bash
systemctl daemon-reload && systemctl restart docker
```

### 2. K8s 集群配置（Containerd 运行时）
编辑所有 K8s 节点的 /etc/containerd/config.toml，替换 registry 节点配置：
```toml
[plugins."io.containerd.grpc.v1.cri".registry]
  config_path = ""

  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
      endpoint = ["https://csg.cloudns.ch"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
      endpoint = ["https://csg.cloudns.ch"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."k8s.gcr.io"]
      endpoint = ["https://csg.cloudns.ch"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."gcr.io"]
      endpoint = ["https://csg.cloudns.ch"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."quay.io"]
      endpoint = ["https://csg.cloudns.ch"]

  [plugins."io.containerd.grpc.v1.cri".registry.configs]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."csg.cloudns.ch".tls]
      ca_file = "/etc/containerd/certs.d/isrgrootx1.pem"
```

安装根证书并重启 Containerd：
```bash
mkdir -p /etc/containerd/certs.d
curl -o /etc/containerd/certs.d/isrgrootx1.pem https://letsencrypt.org/certs/isrgrootx1.pem
systemctl restart containerd
```

### 3. 镜像拉取（无需修改命令）
直接使用官方仓库地址拉取，加速器自动拦截加速：
```bash
# Docker Hub
docker pull nginx:latest

# K8s 官方仓库
docker pull registry.k8s.io/pause:3.9

# GCR
docker pull gcr.io/google-containers/busybox:1.35

# Quay.io
docker pull quay.io/etcd-io/etcd:v3.5.9
```


## 🔧 校验工具
使用脚本快速验证加速器可用性、多仓库兼容性、架构适配：
```bash
# 下载校验脚本
curl -O https://csg.cloudns.ch/check-registry-multi-repo.sh
# 或从项目中获取
chmod +x scripts/check-registry-multi-repo.sh

# 执行校验
./scripts/check-registry-multi-repo.sh
```

## 📚 详细文档
用户使用手册：完整客户端 / K8s 配置、问题排查
部署指南：管理员进阶配置（访问限制、缓存调整等）


## ❌ 常见问题
| 问题现象 | 解决方案 |
| ------- | ------- |
| 证书错误 `x509: certificate signed by unknown authority` | 参考使用手册，手动安装 Let's Encrypt 根证书 |
| K8s 拉取失败 `ImagePullBackOff` | 确认所有节点配置 Containerd 并安装证书，执行 `systemctl restart containerd` |
| 缓存未生效（二次拉取未提速） | 	确认拉取同一标签镜像，大镜像（如 ingress-controller）提速效果更明显 |
| 多仓库加速未生效 | 	检查 Docker/Containerd 配置文件中仓库映射是否正确，重启对应服务 |


## 📄 许可证
本项目基于 MIT 许可证 开源，欢迎 Fork、Star 和贡献代码！

## 🤝 贡献
1. Fork 本仓库
2. 创建特性分支（git checkout -b feature/xxx）
3. 提交修改（git commit -m 'Add xxx feature'）
4. 推送分支（git push origin feature/xxx）
5. 发起 Pull Request

