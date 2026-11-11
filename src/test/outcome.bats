#!/usr/bin/env bats
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 Kaptain contributors (Fred Cooke)
#
# Outcomes: webhooks cannot react, so the prefix marks the outcome, and failure
# is posted a second time on its own so it shows in the space.

load test_helper

@test "success replies with a tick" {
  export NOTIFY_THREAD_KEY=k
  run notify-success-google-chat done
  [[ "${status}" -eq 0 ]]
  [[ "$(calls)" == 'DEPLOY threadKey=k&messageReplyOption=REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD {"text":"✅ done"}' ]]
}

@test "failure replies in the thread and again on its own" {
  export NOTIFY_THREAD_KEY=k
  run notify-failure-google-chat broke
  [[ "${status}" -eq 0 ]]
  [[ "$(sed -n 1p "${FAKE_DIR}/calls")" == 'DEPLOY threadKey=k&messageReplyOption=REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD {"text":"❌ broke"}' ]]
  [[ "$(sed -n 2p "${FAKE_DIR}/calls")" == 'DEPLOY - {"text":"❌ broke"}' ]]
}

@test "success stays in the thread by default" {
  export NOTIFY_THREAD_KEY=k
  notify-success-google-chat done
  [[ "$(wc -l < "${FAKE_DIR}/calls" | tr -d ' ')" -eq 1 ]]
}

@test "success is also posted on its own when googleChatSuccessToChannel is true" {
  export NOTIFY_THREAD_KEY=k
  echo true > "${NOTIFY_CONFIG_BASE}/googleChatSuccessToChannel"
  run notify-success-google-chat done
  [[ "${status}" -eq 0 ]]
  [[ "$(sed -n 1p "${FAKE_DIR}/calls")" == 'DEPLOY threadKey=k&messageReplyOption=REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD {"text":"✅ done"}' ]]
  [[ "$(sed -n 2p "${FAKE_DIR}/calls")" == 'DEPLOY - {"text":"✅ done"}' ]]
}
