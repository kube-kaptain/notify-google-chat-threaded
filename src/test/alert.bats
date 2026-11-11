#!/usr/bin/env bats
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 Kaptain contributors (Fred Cooke)
#
# Alerts: posts of their own to the alert space, with a mention.

load test_helper

@test "alerts go to the alert space with @all and no thread" {
  export NOTIFY_THREAD_KEY=k
  run alert-google-chat drift
  [[ "${status}" -eq 0 ]]
  [[ "$(calls)" == 'ALERT - {"text":"<users/all> 🚨 drift"}' ]]
}

@test "the alert mention can be replaced or turned off" {
  echo "<users/123>" > "${NOTIFY_CONFIG_BASE}/googleChatAlertMention"
  alert-google-chat one
  : > "${NOTIFY_CONFIG_BASE}/googleChatAlertMention"
  alert-google-chat two
  [[ "$(sed -n 1p "${FAKE_DIR}/calls")" == *'{"text":"<users/123> 🚨 one"}' ]]
  [[ "$(sed -n 2p "${FAKE_DIR}/calls")" == *'{"text":"🚨 two"}' ]]
}

@test "alerts need their own webhook" {
  rm "${NOTIFY_SECRETS_BASE}/googleChatAlertWebhookUrl"
  run alert-google-chat drift
  [[ "${status}" -ne 0 ]]
  [[ ! -e "${FAKE_DIR}/calls" ]]
}
