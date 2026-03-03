#!/usr/bin/env sh

set -eu

TARGET_FILE="/usr/local/openresty/nginx/conf/nginx.conf"

# If custom configuration is provided via environment variable
if [ -n "${NGINX_CONF:-}" ]; then
    # Case 1: Local file
    if [ -f "${NGINX_CONF}" ]; then
        echo "Using local nginx.conf: ${NGINX_CONF}"
        cp "${NGINX_CONF}" "${TARGET_FILE}"
    # Case 2: Remote URL (http/https)
    elif echo "${NGINX_CONF}" | grep -qE '^https?://'; then
        echo "Downloading nginx.conf from ${NGINX_CONF}"

        TMP_FILE="$(mktemp)"

        # Download with timeout and fail on errors
        if ! curl -fsSL --max-time 30 "${NGINX_CONF}" -o "${TMP_FILE}"; then
            echo "Failed to download nginx.conf"
            rm -f "${TMP_FILE}"
            exit 1
        fi

        # Ensure downloaded file is not empty
        if [ ! -s "${TMP_FILE}" ]; then
            echo "Downloaded nginx.conf is empty!"
            rm -f "${TMP_FILE}"
            exit 1
        fi

        cp "${TMP_FILE}" "${TARGET_FILE}"
        rm -f "${TMP_FILE}"
    else
        echo "NGINX_CONF is set but is not a valid file or http(s) URL"
        exit 1
    fi
else
    echo "Using default configuration."
fi

# Validate nginx configuration before starting
echo "Validating nginx configuration..."

if ! /usr/local/openresty/bin/openresty -t -c "${TARGET_FILE}"; then
    echo "Configuration validation failed!"
    exit 1
fi

echo "Starting OpenResty..."

# Start OpenResty in foreground mode
exec /usr/local/openresty/bin/openresty -g "daemon off;" -c "${TARGET_FILE}" -e /dev/stdout
