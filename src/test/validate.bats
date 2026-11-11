#!/usr/bin/env bats
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 Kaptain contributors (Fred Cooke)
#
# Validation: presence and shape only, blocking only when googleChatRequired
# is true. Webhooks cannot be checked without posting.

load test_helper

@test "a complete configuration passes without calling Google" {
  run validate-notify-google-chat
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"OK: Google Chat notify configuration"* ]]
  [[ ! -e "${FAKE_DIR}/calls" ]]
}

@test "failures are reported but do not block by default" {
  rm "${NOTIFY_SECRETS_BASE}/googleChatWebhookUrl"
  run validate-notify-google-chat
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"FAIL: googleChatWebhookUrl not found"* ]]
}

@test "failures block when googleChatRequired is true" {
  rm "${NOTIFY_SECRETS_BASE}/googleChatWebhookUrl"
  echo true > "${NOTIFY_CONFIG_BASE}/googleChatRequired"
  run validate-notify-google-chat
  [[ "${status}" -eq 1 ]]
}

@test "bad values are each reported" {
  echo "https://example.com/hook" > "${NOTIFY_SECRETS_BASE}/googleChatAlertWebhookUrl"
  echo "fast" > "${NOTIFY_CONFIG_BASE}/googleChatCurlMaxTime"
  echo "yes" > "${NOTIFY_CONFIG_BASE}/googleChatSuccessToChannel"
  run validate-notify-google-chat
  [[ "${output}" == *"googleChatAlertWebhookUrl is not a Google Chat webhook URL"* ]]
  [[ "${output}" == *"googleChatCurlMaxTime 'fast'"* ]]
  [[ "${output}" == *"googleChatSuccessToChannel 'yes' is not true or false"* ]]
}

@test "tooling validation finds curl and yq" {
  run validate-tooling-google-chat
  [[ "${status}" -eq 0 ]]
}
