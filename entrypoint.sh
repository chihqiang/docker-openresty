#!/usr/bin/env sh

set -eu

target_file="/usr/local/openresty/nginx/conf/nginx.conf"

if [[ -f "${NGINX_CONF_PATH}" ]]; then  # Check if NGINX_CONF is a file
   echo "Using the nginx.conf file located at ${NGINX_CONF_PATH}."
   cat "${NGINX_CONF_PATH}" > "${target_file}"
elif [[ "${NGINX_CONF_PATH}" =~ ^https?:// ]]; then  # Check if NGINX_CONF is an HTTP/HTTPS URL
   echo "Downloading nginx.conf from ${NGINX_CONF_PATH} and using it as the server configuration."
   curl "${NGINX_CONF_PATH}" > "${target_file}"
else
   echo "Using the default configuration for the server."
fi

echo "Starting OpenResty Nginx server..."

/usr/local/openresty/bin/openresty -g "daemon off;" -e /dev/stdout