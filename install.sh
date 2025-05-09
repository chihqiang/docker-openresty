#!/bin/bash

set -e

# https://openresty.org/cn/linux-packages.html

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

install_openresty_debian_ubuntu() {
    echo "[*] 安装依赖..."
    sudo apt-get -y install wget gnupg ca-certificates lsb-release

    echo "[*] 导入 GPG 公钥..."
    if [ "$OS_VER_ID" -ge 12 ]; then
        if [ ! -f /etc/apt/trusted.gpg.d/openresty.gpg ]; then
            wget -O - https://openresty.org/package/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg
        else
            echo "[i] GPG 公钥已存在，跳过导入"
        fi
    else
        if ! apt-key list | grep -q "openresty"; then
            wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
        else
            echo "[i] apt-key 已包含 openresty 公钥"
        fi
    fi

    echo "[*] 添加 APT 源..."
    codename=$(lsb_release -sc)
    list_file="/etc/apt/sources.list.d/openresty.list"

    if [ ! -f "$list_file" ]; then
        if [ "$ARCH" = "arm64" ]; then
            echo "deb http://openresty.org/package/arm64/ubuntu $codename main" | sudo tee "$list_file"
        else
            echo "deb http://openresty.org/package/ubuntu $codename main" | sudo tee "$list_file"
        fi
    else
        echo "[i] openresty.list 已存在，跳过添加"
    fi

    echo "[*] 更新并安装 openresty..."
    sudo apt-get update
    sudo apt-get -y install openresty
}

install_openresty_centos_rhel() {
    echo "[*] 安装 wget..."
    sudo yum install -y wget

    repo_file="/etc/yum.repos.d/openresty.repo"
    if [ ! -f "$repo_file" ]; then
        if [ "$OS_VER_ID" -ge 9 ]; then
            wget -q https://openresty.org/package/centos/openresty2.repo -O "$repo_file"
        else
            wget -q https://openresty.org/package/centos/openresty.repo -O "$repo_file"
        fi
    else
        echo "[i] openresty.repo 已存在，跳过下载"
    fi

    echo "[*] 安装 openresty..."
    sudo yum install -y openresty
}

case "$OS_ID" in
    ubuntu|debian)
        install_openresty_debian_ubuntu
        ;;
    centos|rhel)
        install_openresty_centos_rhel
        ;;
    *)
        echo "[!] 暂不支持您的系统: $OS_ID"
        exit 1
        ;;
esac

echo "[✓] OpenResty 安装完成！"
