# Message Formatting

Google Chat renders a small markup in message text. It works anywhere text reaches the space: the messages
the deploy sends, the level prefixes and the alert mention.

| Write                         | Shows as                                     |
|-------------------------------|----------------------------------------------|
| `*bold*`                      | **bold**                                     |
| `_italic_`                    | *italic*                                     |
| `~strike~`                    | ~~strike~~                                   |
| `` `code` ``                  | `code`, inline                               |
| ```` ```...``` ````           | A code block, spacing kept, on its own lines |
| `<https://example.com\|Text>` | A link reading Text                          |
| `https://example.com`         | The URL, linked                              |
| `<users/all>`                 | @all, notifying everyone in the space        |

Everything else arrives as written: line breaks, tabs, quotes, backslashes, `<`, `>`, `&`, accents and emoji.
Emoji go in as the characters themselves, such as ⚠️, since Google Chat does not convert `:warning:` style codes.
