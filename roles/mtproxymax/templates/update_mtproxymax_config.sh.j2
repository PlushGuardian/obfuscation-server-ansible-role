#!/usr/bin/env bash
# Managed by Ansible (mtproxymax role) - do not edit by hand.
#
# Fetches Telegram's proxy config and only replaces the live config /
# restarts the service if the content actually changed. This avoids the
# daily unconditional restart the old cron job used to do.
set -euo pipefail

CONFIG_URL="https://core.telegram.org/getProxyConfig"
CONFIG_PATH="{{ mtproxymax_config_path }}"
TMP_PATH="$(mktemp)"
trap 'rm -f "$TMP_PATH"' EXIT

curl -fsS "$CONFIG_URL" -o "$TMP_PATH"

if [ ! -s "$TMP_PATH" ]; then
  echo "Downloaded config is empty, refusing to apply it" >&2
  exit 1
fi

if [ ! -f "$CONFIG_PATH" ] || ! cmp -s "$TMP_PATH" "$CONFIG_PATH"; then
  install -m 0644 "$TMP_PATH" "$CONFIG_PATH"
  systemctl restart mtproxymax
fi
