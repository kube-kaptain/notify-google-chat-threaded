# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 Kaptain contributors (Fred Cooke)
#
# Shared setup for the Google Chat provider tests. Each test gets its own
# config, secret and work dirs, plus a fake curl first on PATH that answers
# like a Google Chat webhook and records what it was asked.
#
# Fake curl records, per call:
#   calls  one line: <space> <query after the key and token> <JSON body>
#   argv   one line: every argument curl was given
#   stdin  whatever came in on stdin, the -K config holding the URL
#
# FAKE_HTTP_ERROR makes it answer like curl --fail-with-body on a 404.

setup() {
  export NOTIFY_CONFIG_BASE="${BATS_TEST_TMPDIR}/config"
  export NOTIFY_SECRETS_BASE="${BATS_TEST_TMPDIR}/secrets"
  export NOTIFY_WORK_BASE="${BATS_TEST_TMPDIR}/work"
  mkdir -p "${NOTIFY_CONFIG_BASE}" "${NOTIFY_SECRETS_BASE}" "${NOTIFY_WORK_BASE}"

  echo "https://chat.googleapis.com/v1/spaces/DEPLOY/messages?key=K1&token=T1" > "${NOTIFY_SECRETS_BASE}/googleChatWebhookUrl"
  echo "https://chat.googleapis.com/v1/spaces/ALERT/messages?key=K2&token=T2" > "${NOTIFY_SECRETS_BASE}/googleChatAlertWebhookUrl"

  unset NOTIFY_THREAD_KEY FAKE_HTTP_ERROR

  export FAKE_DIR="${BATS_TEST_TMPDIR}"
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  cat > "${BATS_TEST_TMPDIR}/bin/curl" <<'FAKE'
#!/usr/bin/env bash
config=$(cat)
echo "${config}" >> "${FAKE_DIR}/stdin"
echo "$*" >> "${FAKE_DIR}/argv"

data=""
prev=""
for arg in "$@"; do
  if [[ "${prev}" == --data-binary ]]; then
    data="${arg}"
  fi
  prev="${arg}"
done
url="${config#url = \"}"
url="${url%\"}"
space="${url#*/spaces/}"
space="${space%%/*}"
query="${url#*token=}"
query="${query#T[0-9]}"
query="${query#&}"
echo "${space} ${query:--} ${data}" >> "${FAKE_DIR}/calls"

if [[ -n "${FAKE_HTTP_ERROR:-}" ]]; then
  echo '{"error":{"code":404,"message":"Space not found"}}'
  exit 22
fi
echo '{"name":"spaces/X/messages/Y"}'
FAKE
  chmod 755 "${BATS_TEST_TMPDIR}/bin/curl"
  export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
}

# Print the recorded calls
calls() {
  cat "${FAKE_DIR}/calls"
}
