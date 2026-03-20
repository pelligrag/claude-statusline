# claude-statusline

Custom 2-line status bar for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with burn rate, context usage, 5h rate limit bar, and git integration.

Powered by [ccusage](https://github.com/ryoppippi/ccusage).

## Preview

```
📁 ~/myproject | 🌿 main +2 ~1 | 🤖 Sonnet 4.6 | 🔥 $4.72/hr 🟢 (Normal) | 🧠 84,000 (42%)
████░░░░░░░░░░░░░░░░ 24% of 5h limit | Resets 13:00 Rome
```

**Line 1** -working directory, git branch/status, model, burn rate indicator, context window usage

**Line 2** -visual 5h rate limit bar (green/yellow/red) with reset time in your local timezone

## Requirements

- `python3` (3.9+ for `zoneinfo`)
- `ccusage` -`npm i -g ccusage`
- `git` (optional, for branch display)

## Install

```bash
# 1. Download the script
curl -fsSL https://raw.githubusercontent.com/pelligrag/claude-statusline/main/statusline-command.sh \
  -o ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh

# 2. Add to ~/.claude/settings.json
# (merge with your existing settings)
cat <<'JSON'
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh",
    "padding": 1
  }
}
JSON

# 3. Set your timezone (add to ~/.bashrc or ~/.zshrc)
export STATUSLINE_TZ="Europe/Rome"
```

## Configuration

### Timezone

Set the `STATUSLINE_TZ` environment variable to any valid [IANA timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones):

```bash
export STATUSLINE_TZ="Europe/Rome"       # Italy
export STATUSLINE_TZ="America/New_York"  # US East
export STATUSLINE_TZ="Asia/Tokyo"        # Japan
```

Default: `UTC`

### Rate limit bar thresholds

The 5h rate limit bar changes color based on usage:

| Usage   | Color  |
|---------|--------|
| < 50%   | 🟢 Green  |
| 50-79%  | 🟡 Yellow |
| ≥ 80%   | 🔴 Red    |

### Disable cost display

Cost info from `ccusage` is already stripped by default. Only burn rate (`$/hr`) is shown as a velocity indicator.

## What's displayed

| Section | Source | Description |
|---------|--------|-------------|
| 📁 Directory | Claude Code JSON | Current working directory (shortened) |
| 🌿 Git | `git` CLI (cached 5s) | Branch name, staged (+) and modified (~) counts |
| 🤖 Model | Claude Code JSON | Active model name |
| 🔥 Burn rate | `ccusage` | Cost per hour + status indicator |
| 🧠 Context | Claude Code JSON | Token count and context window % |
| ████ 5h bar | Claude Code JSON | Visual rate limit usage with reset time |

## Troubleshooting

**Status line not showing?**
- Ensure the script exits with code 0: `echo '{}' | bash ~/.claude/statusline-command.sh; echo $?`
- Check `ccusage` is installed: `ccusage --version`

**zsh shows `%` at the end?**
- Add `PROMPT_EOL_MARK=""` to your `~/.zshrc`

## License

MIT
