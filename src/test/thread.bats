#!/usr/bin/env bats
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 Kaptain contributors (Fred Cooke)
#
# Threading by key: NOTIFY_THREAD_KEY when set, otherwise one made up for the
# run and reused by every post in it.

load test_helper

@test "providers need a message" {
  run notify-info-google-chat
  [[ "${status}" -eq 42 ]]
}

@test "posts go into the thread named by NOTIFY_THREAD_KEY" {
  export NOTIFY_THREAD_KEY=run-stage-1.2.3
  run notify-info-google-chat start
  [[ "${status}" -eq 0 ]]
  [[ "$(calls)" == 'DEPLOY threadKey=run-stage-1.2.3&messageReplyOption=REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD {"text":"start"}' ]]
}

@test "without NOTIFY_THREAD_KEY every post in the run shares a made up key" {
  notify-info-google-chat one
  notify-info-google-chat two
  key=$(cat "${NOTIFY_WORK_BASE}/notify/google-chat/thread-key")
  [[ "${key}" == run-* ]]
  [[ "$(grep -c "threadKey=${key}&" "${FAKE_DIR}/calls")" -eq 2 ]]
}

@test "quotes and newlines survive into the JSON body" {
  notify-info-google-chat 'say "hi"
line two'
  [[ "$(calls)" == *'{"text":"say \"hi\"\nline two"}' ]]
}

@test "level prefixes default, can be replaced, and can be turned off" {
  notify-warning-google-chat w
  echo "🔥" > "${NOTIFY_CONFIG_BASE}/googleChatWarningPrefix"
  notify-warning-google-chat w2
  : > "${NOTIFY_CONFIG_BASE}/googleChatWarningPrefix"
  notify-warning-google-chat w3
  [[ "$(sed -n 1p "${FAKE_DIR}/calls")" == *'{"text":"⚠️ w"}' ]]
  [[ "$(sed -n 2p "${FAKE_DIR}/calls")" == *'{"text":"🔥 w2"}' ]]
  [[ "$(sed -n 3p "${FAKE_DIR}/calls")" == *'{"text":"w3"}' ]]
}

@test "the webhook URL is passed on stdin, never as an argument" {
  notify-info-google-chat start
  ! grep -q 'chat.googleapis.com' "${FAKE_DIR}/argv"
  grep -q 'url = "https://chat.googleapis.com/v1/spaces/DEPLOY/messages?key=K1&token=T1&threadKey=' "${FAKE_DIR}/stdin"
}

@test "an HTTP error fails the provider with the response body" {
  export FAKE_HTTP_ERROR=1
  run notify-info-google-chat start
  [[ "${status}" -ne 0 ]]
  [[ "${output}" == *"Space not found"* ]]
}
