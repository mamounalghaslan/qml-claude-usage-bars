# Claude Usage Bars

A Plasma 6 panel widget showing your Claude **weekly** and **Fable** usage limits as
two horizontal bars, styled to match the stock System Monitor "Horizontal Bars" face.

Pure QML plus a small Python poller — no C++ plugin, nothing under `/usr`.

## How it works

- `scripts/claude-usage-fetch` reads the OAuth token Claude Code keeps in
  `~/.claude/.credentials.json`, makes one read-only request to the usage endpoint,
  and writes `~/.cache/claude-usage/usage.json`.
- It never refreshes the token (Claude Code rotates refresh tokens; a second client
  refreshing could log it out). If the token has expired it keeps the last good
  numbers and marks them stale.
- A systemd user timer runs the script every 3 minutes.
- The widget (`package/`) reads that file every 30 s. Left-click refreshes immediately
  (runs the fetch script, then re-reads); middle-click opens the popup with labels and
  reset times; hover for a tooltip. Each bar is split into five 20% sections by thin
  gaps so the level reads at a glance. Bars use the accent color and switch
  to the warning color above 90%. Stale data is dimmed.

## Install

```
ln -sfn "$PWD/scripts/claude-usage-fetch" ~/.local/bin/claude-usage-fetch
ln -sfn "$PWD/package" ~/.local/share/plasma/plasmoids/local.claudeusagebars
ln -sfn "$PWD/systemd/claude-usage-fetch.service" ~/.config/systemd/user/
ln -sfn "$PWD/systemd/claude-usage-fetch.timer" ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now claude-usage-fetch.timer
```

Then add "Claude Usage Bars" to a panel.

## Tests

```
python3 -I -m unittest discover -s tests
```
