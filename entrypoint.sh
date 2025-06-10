#!/usr/bin/env sh

set -eu

target_file="/usr/local/openresty/nginx/conf/nginx.conf"

# 判断环境变量 NGINX_CONF_PATH 是否是一个文件路径
if [ -n "${NGINX_CONF_PATH:-}" ] && [ -f "${NGINX_CONF_PATH}" ]; then
    echo "Using the nginx.conf file located at ${NGINX_CONF_PATH}."
    cat "${NGINX_CONF_PATH}" > "${target_file}"

# 判断环境变量是否以 http:// 或 https:// 开头（用简单的前缀判断）
elif [ -n "${NGINX_CONF_PATH:-}" ] && (echo "${NGINX_CONF_PATH}" | grep -qE '^https?://'); then
    echo "Downloading nginx.conf from ${NGINX_CONF_PATH} and using it as the server configuration."
    curl -fsSL "${NGINX_CONF_PATH}" > "${target_file}"

else
    echo "Using the default configuration for the server."
fi

echo "Starting OpenResty Nginx server..."

exec /usr/local/openresty/bin/openresty -g "daemon off;" -e /dev/stdout
