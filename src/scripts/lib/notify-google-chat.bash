# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 Kaptain contributors (Fred Cooke)
#
# Shared helpers for the Google Chat notify providers. Sourced, not executed.
#
# Configuration is one key per file, as Kubernetes mounts a ConfigMap/Secret:
#
#   ${NOTIFY_SECRETS_BASE}/googleChatWebhookUrl       Webhook for the deploy thread space
#   ${NOTIFY_SECRETS_BASE}/googleChatAlertWebhookUrl  Webhook for the alert space, separate from the deploy one
#   ${NOTIFY_CONFIG_BASE}/googleChatRequired          Optional, 'true' makes validation failure block the deploy
#   ${NOTIFY_CONFIG_BASE}/googleChatSuccessToChannel  Optional, 'true' also posts success to the space, as failure always is
#   ${NOTIFY_CONFIG_BASE}/googleChatAlertMention      Optional, mention before alert posts, default <users/all>, empty for none
#   ${NOTIFY_CONFIG_BASE}/googleChat<Level>Prefix     Optional, text put before each message of that level, see google_chat_prefix
#   ${NOTIFY_CONFIG_BASE}/googleChatCurl<Setting>     Optional, curl retry and timeouts, see google_chat_curl_settings
#
# Webhook URLs carry their own key and token, so they are secrets.
#
# The optional entries' defaults are files in lib/notify-google-chat-defaults/,
# one per entry, packaged there from src/defaults. Absent gives the default,
# present but empty turns it off.
#
# NOTIFY_CONFIG_BASE, NOTIFY_SECRETS_BASE and NOTIFY_WORK_BASE must be set by
# the caller, there are no defaults.
#
# NOTIFY_THREAD_KEY, set by the caller, makes runs with the same key share one
# thread, for example an env name and version. Google Chat threads by a key we
# choose, so no lookup is needed. Unset, the first post of the run makes up a
# key and records it under ${NOTIFY_WORK_BASE}/notify/google-chat.
#
# Webhooks cannot react to or edit messages, or DM people. The outcome shows as
# the prefix on the final reply instead of a reaction on the opening post, and
# googleChatSuccessToChannel can post success to the space too.

# shellcheck disable=SC2154 # NOTIFY_*_BASE are set by the caller, see above
GOOGLE_CHAT_DEFAULTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/notify-google-chat-defaults"

# Print the value of a config or secret key, empty if absent
google_chat_read_key() {
  local file="$1/$2"
  [[ -f "${file}" ]] || return 0
  tr -d '\r\n' < "${file}"
}

# Print an optional entry's value: the config entry when present, empty
# included, which turns it off, otherwise the plugin's default
google_chat_setting() {
  local key="$1"
  if [[ -f "${NOTIFY_CONFIG_BASE}/${key}" ]]; then
    google_chat_read_key "${NOTIFY_CONFIG_BASE}" "${key}"
  else
    google_chat_read_key "${GOOGLE_CHAT_DEFAULTS_DIR}" "${key}"
  fi
}

# Print the message prefix for a level followed by a space, from
# googleChat<Level>Prefix, for example googleChatWarningPrefix
google_chat_prefix() {
  local level="$1"
  local value
  value=$(google_chat_setting "googleChat${level}Prefix")
  if [[ -n "${value}" ]]; then
    printf '%s ' "${value}"
  fi
}

# Print the curl retry and timeout arguments. Defaults favour getting every
# message through, in order, on unreliable networks over speed. Each can be
# overridden with a whole number in googleChatCurl<Setting>, for example
# googleChatCurlMaxTime. Invalid or empty values fall back to the default.
google_chat_curl_settings() {
  local setting
  local value
  for setting in Retry RetryDelay ConnectTimeout MaxTime RetryMaxTime; do
    value=$(google_chat_read_key "${NOTIFY_CONFIG_BASE}" "googleChatCurl${setting}")
    if [[ ! "${value}" =~ ^[0-9]+$ ]]; then
      value=$(google_chat_read_key "${GOOGLE_CHAT_DEFAULTS_DIR}" "googleChatCurl${setting}")
    fi
    case "${setting}" in
      Retry) printf -- '--retry\n%s\n' "${value}" ;;
      RetryDelay) printf -- '--retry-delay\n%s\n' "${value}" ;;
      ConnectTimeout) printf -- '--connect-timeout\n%s\n' "${value}" ;;
      MaxTime) printf -- '--max-time\n%s\n' "${value}" ;;
      RetryMaxTime) printf -- '--retry-max-time\n%s\n' "${value}" ;;
    esac
  done
}

# Send a message to the webhook in the given secret key. With a thread key it
# goes into that thread, starting it if need be. Without one it starts a new
# thread of its own. Returns non-zero with the reason on stderr on failure.
google_chat_send() {
  local webhook_key="$1"
  local thread_key="$2"
  local text="$3"
  local url
  url=$(google_chat_read_key "${NOTIFY_SECRETS_BASE}" "${webhook_key}")
  if [[ -z "${url}" ]]; then
    echo "google-chat: ${webhook_key} not found in ${NOTIFY_SECRETS_BASE}" >&2
    return 1
  fi
  if [[ -n "${thread_key}" ]]; then
    url+="&threadKey=${thread_key}&messageReplyOption=REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD"
  fi

  local body
  body=$(GOOGLE_CHAT_TEXT="${text}" yq -n -o json -I0 '.text = strenv(GOOGLE_CHAT_TEXT)')

  local curl_settings=()
  local line
  while IFS= read -r line; do
    curl_settings+=("${line}")
  done < <(google_chat_curl_settings)

  # URL goes in via a config on stdin so its key and token never show up in ps
  local response
  if ! response=$(printf 'url = "%s"\n' "${url}" |
      curl -sS --fail-with-body "${curl_settings[@]}" -K - \
        -H 'Content-Type: application/json; charset=utf-8' \
        --data-binary "${body}"); then
    echo "google-chat: failed to send message: ${response}" >&2
    return 1
  fi
}

# Print the thread key for this run, NOTIFY_THREAD_KEY if set, otherwise one
# made up on first use and recorded for the rest of the run
google_chat_thread_key() {
  if [[ -n "${NOTIFY_THREAD_KEY:-}" ]]; then
    printf '%s\n' "${NOTIFY_THREAD_KEY}"
    return 0
  fi
  local state_dir="${NOTIFY_WORK_BASE}/notify/google-chat"
  if [[ ! -f "${state_dir}/thread-key" ]]; then
    mkdir -p "${state_dir}"
    printf 'run-%s-%s\n' "$(date -u '+%Y%m%dT%H%M%SZ')" "${RANDOM}" > "${state_dir}/thread-key"
  fi
  cat "${state_dir}/thread-key"
}

# Post into the deploy thread, starting it if this is the first message
google_chat_thread_post() {
  google_chat_send googleChatWebhookUrl "$(google_chat_thread_key)" "$1"
}
