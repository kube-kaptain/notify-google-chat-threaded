# Notify Google Chat Threaded

The Google Chat notify plugin for Kaptain Deploy and Kaptain Build.

Each deploy from a particular environment version posts into the same thread in
a Google Chat space. The thread is identified by the value of `NOTIFY_THREAD_KEY`
which is the version appended to the name. That means that a restarted deploy
of the same version carries on where it left off instead of spamming the
channel with a new thread. Only failures are also posted to the space itself
since there's no other way of exposing that on Google Chat. For example an
emoji on the original post would serve a similar purpose less obviously but
that's not available on Google Chat. Alerts, if any, go to a separate space
with an `@all`.

The `googleChatSuccessToChannel` setting causes success messages to post to the
same space too, if you want it seen without opening the thread.


## Google Chat Setup

In each space, **Apps & integrations**, then **Webhooks**, add a webhook and
copy its URL. One space for the deploy threads and one for alerts.


## Configuration

### Environment

| Variable              | Purpose                                         |
|-----------------------|-------------------------------------------------|
| `NOTIFY_CONFIG_BASE`  | Directory of config entries, one file per entry |
| `NOTIFY_SECRETS_BASE` | Directory of secret entries, one file per entry |
| `NOTIFY_WORK_BASE`    | Writable directory for per-run state            |
| `NOTIFY_THREAD_KEY`   | Optional, runs with the same key share a thread |

The Kaptain deploy base images set the first three. The `deploy` script entry
point sets `NOTIFY_THREAD_KEY` to `<environment>-<version>`.

### Secrets

| Entry                       | Purpose                                                                     |
|-----------------------------|-----------------------------------------------------------------------------|
| `googleChatWebhookUrl`      | Webhook for the deploy threads, `https://chat.googleapis.com/v1/spaces/...` |
| `googleChatAlertWebhookUrl` | Webhook for alerts, a separate space                                        |

The URLs carry their own key and token, so they are secrets.

### Optional Config

Absent gives the default, present but empty turns it off, anything else
replaces it.

| Entry                          | Default                                                   |
|--------------------------------|-----------------------------------------------------------|
| `googleChatRequired`           | `false`, `true` makes validation failures stop the deploy |
| `googleChatSuccessToChannel`   | `false`, `true` also posts success to the space           |
| `googleChatAlertMention`       | `<users/all>`                                             |
| `googleChatInfoPrefix`         | none                                                      |
| `googleChatWarningPrefix`      | ⚠️                                                         |
| `googleChatErrorPrefix`        | 🚨                                                        |
| `googleChatSuccessPrefix`      | ✅                                                        |
| `googleChatFailurePrefix`      | ❌                                                        |
| `googleChatAlertPrefix`        | 🚨                                                        |
| `googleChatCurlRetry`          | `3`                                                       |
| `googleChatCurlRetryDelay`     | `2`                                                       |
| `googleChatCurlConnectTimeout` | `10`                                                      |
| `googleChatCurlMaxTime`        | `20`                                                      |
| `googleChatCurlRetryMaxTime`   | `70`                                                      |

The curl defaults favour every message arriving, and in order, ie coherency,
and completeness over speed.

See [MessageFormatting.md](MessageFormatting.md) for the markup Google Chat
renders in messages, prefixes and the alert mention.

Every entry is listed in `src/fields/` with its canonical token name, and every
 default in `src/defaults/`, shipped as the image's `/fields` and the
`notify-google-chat-threaded-fields.zip` release file.


## Messages

| Command                                         | In Google Chat                                                           |
|-------------------------------------------------|--------------------------------------------------------------------------|
| `notify-info`, `notify-warning`, `notify-error` | A reply in the thread, the first message of a run opens it               |
| `notify-success`                                | A reply, and a post of its own if `googleChatSuccessToChannel` is `true` |
| `notify-failure`                                | A reply, and a post of its own                                           |
| `alert`                                         | A post of its own in the alert space                                     |

`validate-notify-google-chat` checks the webhook URLs are present and shaped
right, since a webhook cannot be checked without posting.
`validate-tooling-google-chat` checks `curl` and `yq` are present.


## Use

### Kaptain Deploy

Add [layer-notify-google-chat-threaded](https://github.com/kube-kaptain/layer-notify-google-chat-threaded)
to your environment project KaptainPM.yaml. It puts the scripts in the deploy
image and the entries in the environment's ConfigMap and Secret, as tokens for
your run-platform to supply.

To build the plugin into your own image instead, copy the scripts in beside the
deploy scripts:

```dockerfile
COPY --from=ghcr.io/kube-kaptain/notify/notify-google-chat-threaded:<version> /scripts /kd/bin
```

Then supply your own ConfigMap and Secret, starting from
`templates/env-configmap/` or a subset thereof and `templates/env-secret/`.

<todo ### Kaptain Build>

<todo some setting in early build that pulls in and wires up to logging system>
