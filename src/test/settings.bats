#!/usr/bin/env bats
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 Kaptain contributors (Fred Cooke)
#
# curl flags, retry and timeout settings.

load test_helper

@test "curl fails on HTTP errors and gets the reliable defaults" {
  notify-info-google-chat start
  grep -q -- '--fail-with-body --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 20 --retry-max-time 70' "${FAKE_DIR}/argv"
}

@test "curl settings can be overridden, invalid values fall back" {
  echo 0 > "${NOTIFY_CONFIG_BASE}/googleChatCurlRetry"
  echo 5 > "${NOTIFY_CONFIG_BASE}/googleChatCurlMaxTime"
  echo junk > "${NOTIFY_CONFIG_BASE}/googleChatCurlRetryDelay"
  notify-info-google-chat start
  grep -q -- '--retry 0 --retry-delay 2 --connect-timeout 10 --max-time 5 --retry-max-time 70' "${FAKE_DIR}/argv"
}
