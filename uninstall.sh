#!/bin/bash

set -e

echo "[*] 正在检测系统..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_VER_ID=${VERSION_ID%%.*}
else
    echo "无法识别系统类型"
    exit 1
fi

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "不支持的架构: $ARCH"; exit 1 ;;
esac

echo "[*] 检测结果：$OS_ID $OS_VER_ID ($ARCH)"

uninstall_openresty_debian_ubuntu() {
    echo "[*] 卸载 OpenResty 及其组件..."
    sudo apt-get remove --purge -y openresty openresty-resty || true
    sudo apt-get autoremove -y

    echo "[*] 移除 OpenResty APT 源..."
    sudo rm -f /etc/apt/sources.list.d/openresty.list

    echo "[*] 移除 GPG 公钥..."
    sudo rm -f /etc/apt/trusted.gpg.d/openresty.gpg || true
    sudo apt-key del "$(apt-key list | grep -B1 'openresty' | head -n1 | awk '{print $2}')" 2>/dev/null || true

    echo "[*] 更新 APT 索引..."
    sudo apt-get update
}

uninstall_openresty_centos_rhel() {
    echo "[*] 卸载 OpenResty..."
    sudo yum remove -y openresty openresty-resty || true

    echo "[*] 移除 OpenResty YUM 源..."
    sudo rm -f /etc/yum.repos.d/openresty.repo
    sudo rm -f /etc/yum.repos.d/openresty2.repo

    echo "[*] 清理缓存..."
    sudo yum clean all
}

case "$OS_ID" in
    ubuntu|debian)
        uninstall_openresty_debian_ubuntu
        ;;
    centos|rhel)
        uninstall_openresty_centos_rhel
        ;;
    *)
        echo "[!] 暂不支持您的系统: $OS_ID"
        exit 1
        ;;
esac

echo "[✓] OpenResty 卸载完成！"
