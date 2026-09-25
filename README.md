# claude-code-statusline

A simple, non-intrusive status line for the [Claude Code](https://claude.com/claude-code) terminal app (CLI) that shows your model, effort level, context usage, and plan limits at a glance.

```
Opus 5.5 (medium) | Ctx: 35306 tok (4%) | 5h: 1% (resets Fri 14:10)  7d: 0% (resets Thu 09:00)
```

| Part                  | Meaning                                                                     |
| --------------------- | --------------------------------------------------------------------------- |
| `Opus 5.5 (medium)`   | Current model and effort level. Updates when you use `/model` or `/effort`. |
| `Ctx: 35306 tok (4%)` | Tokens in the current conversation and how full the context window is.      |
| `5h: 1%`              | How much of your 5-hour usage limit you've used, and when it resets.        |
| `7d: 0%`              | How much of your weekly usage limit you've used, and when it resets.        |

**Colours:**

| Part        | Yellow                                                  | Red           |
| ----------- | ------------------------------------------------------- | ------------- |
| `Ctx`       | From 100k tokens **or** 50% full, whichever comes first | From 75% full |
| `5h` / `7d` | From 50% used                                           | From 75% used |

### Colour coding

- **Context yellow (100k tokens):** a lean context is better. Claude tends to be sharpest with a focused conversation, and a long session full of old detours costs more per message and can distract it. Yellow is just a nudge: nothing breaks, but it's a good time to start thinking about finishing up and start fresh (read more about this in the tips section below).
- **Context red (75% full):** when the window fills up, Claude Code automatically *compacts* the conversation, replacing older messages with a summary, and detail can get lost. Red means that's getting close, so ideally, you should clear or compact now, when you choose to, rather than letting it happen while you're busy working on a task.
- **Limits (`5h` / `7d`):** yellow and red warn you before you hit your plan's usage cap and get paused until the reset time shown.

## Install

### Easiest: let Claude Code do it

Paste this into Claude Code:

```
Install the status line from https://github.com/Cyber-Dani/claude-code-statusline. Download the right script for my OS into ~/.claude/ and add the statusLine setting to ~/.claude/settings.json as described in its README.
```

### Manual: two steps

**macOS / Linux**

1. Download the script (requires [jq](https://jqlang.org/download/): `brew install jq` or `sudo apt install jq`):
   
   ```sh
   curl -fsSL https://raw.githubusercontent.com/Cyber-Dani/claude-code-statusline/main/statusline.sh -o ~/.claude/statusline.sh
   ```

2. Add this to `~/.claude/settings.json`:
   
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash ~/.claude/statusline.sh"
   }
   ```

**Windows**

1. Download the script (in PowerShell):
   
   ```powershell
   Invoke-WebRequest https://raw.githubusercontent.com/Cyber-Dani/claude-code-statusline/main/statusline.ps1 -OutFile "$HOME\.claude\statusline.ps1"
   ```

2. Add this to `.claude\settings.json`:
   
   ```json
   "statusLine": {
     "type": "command",
     "command": "powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"$HOME/.claude/statusline.ps1\""
   }
   ```

The status line appears the next time Claude Code refreshes it. You don't need to restart.

## Compatibility

|                   | Requirement                                                                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Windows**       | Windows PowerShell 5.1 (built in) or PowerShell 7. Nothing to install.                                                                                 |
| **macOS / Linux** | bash and [jq](https://jqlang.org/download/).                                                                                                           |
| **Claude Code**   | A recent version. Built against 2.1.282. Older versions may not report the effort level. In that case the script shows just the model name.            |
| **Plan limits**   | The `5h` / `7d` numbers only appear on Claude.ai subscription plans (Pro, Max). With an API key you'll see `limits: n/a`. Everything else still works. |
| **Terminal**      | Any terminal that supports ANSI colours. That includes all modern ones: Windows Terminal, iTerm2, macOS Terminal, VS Code, most Linux terminals.       |

Anything the script can't find is shown as `n/a` or left out. It never breaks your status line.

## Tips for keeping context lean

| Do this                        | How                                                                                     | Why                                                                                                                                                                                                                                                                      |
| ------------------------------ | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Start fresh between tasks**  | `/clear`                                                                                | This is the simplest win. Use it when you move on to something unrelated to what you've done so far: a new feature, a different bug, or a separate chunk of work. A new task doesn't always needs the old conversation, so keep that in mind while working on something. |
| **Compact on your terms**      | `/compact`, optionally with what to keep, e.g. `/compact keep the API design decisions` | Replaces the whole conversation so far with a short summary. Claude keeps the key points but loses the exact wording and details. Doing it yourself, when you choose, beats an automatic compact mid-task.                                                               |
| **Undo a wrong turn**          | `/rewind`, or press `Esc` twice                                                         | Use it when Claude misunderstood you or went down a path you don't want. Jump back to the message before it went wrong and ask again, more clearly. The failed attempt then stops taking up context and stops steering Claude.                                           |
| **See what's using space**     | `/context`                                                                              | Breaks down what's filling the window: conversation, tool definitions, memory files, and so on.                                                                                                                                                                          |
| **Be specific**                | Point at files with `@path/to/file`                                                     | Saves Claude from reading half the project to find the right file.                                                                                                                                                                                                       |
| **Trim always-loaded context** | Keep `CLAUDE.md` short. Disable MCP servers you aren't using.                           | These load into every conversation before you type anything.                                                                                                                                                                                                             |

**Rewind vs. correcting.** If Claude went down the wrong path, rewinding to just before it and rephrasing your request usually works better than saying "no, not like that". Corrections leave the wrong attempt in the context, and Claude keeps seeing it.

**Rewind the conversation, not the code.** When you rewind, Claude Code asks what to restore: the conversation, the code, or both. Pick **conversation only** unless you really want to throw the code changes away. Restoring the code undoes every file edit Claude made since that point, and that work is gone.

## Customise

The colour thresholds are at the top of each script:

```
WARN_PCT    = 50       # yellow from this % (context and limits)
CRIT_PCT    = 75       # red from this % (context and limits)
WARN_TOKENS = 100000   # context also turns yellow from this many tokens
```

## Uninstall

Delete the `statusLine` block from `settings.json`, then delete the script from `~/.claude/`.

## License

[MIT](LICENSE). Free to use, change, and share.
