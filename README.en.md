# plush

[中文](README.md)

plush configures the prompt and line editing of PowerShell: the up arrow searches history by the prefix already typed, history suggestions appear inline while typing, and Tab opens a completion menu.

The prompt is drawn by a PowerShell function without spawning a process, and the git branch is read from `.git/HEAD`. One render takes less than 1 ms on Windows PowerShell 5.1; oh-my-posh starts a process for every render, which takes about 110–160 ms on the same machine.

## Install

Requires PowerShell 5.1 or later.

```powershell
git clone https://github.com/Jannchie/plush.git $HOME\plush
```

Add to `$PROFILE`:

```powershell
Import-Module $HOME\plush\plush.psd1
Enable-Plush
```

History suggestions require PSReadLine 2.1 or later. Windows PowerShell 5.1 ships with 2.0; to upgrade:

```powershell
Install-Module PSReadLine -Scope CurrentUser -Force
```

## Prompt

```
(myenv)
# % alice @ DESKTOP in ~\code\plush on git:main [16:20:49] C:1
$
```

- `(myenv)`: the active Python virtual environment or conda environment; the line is empty when there is none. When the environment directory has a generic name such as `.venv` or `venv`, the parent directory name is shown instead
- `%`: shown only in an administrator (or root) session
- `on git:main`: the current branch; a detached HEAD shows the short hash; worktrees and submodules are supported. The working tree status is not queried
- `C:1`: the exit code of the previous command, shown when it failed

The style comes from the [ys theme](https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/ys.zsh-theme) of oh-my-zsh.

## Keys

| Key | Behavior |
| --- | --- |
| `↑` / `↓` | Search history by the prefix already typed; step through history when the line is empty |
| `→` / `End` | Accept the whole suggestion |
| `Ctrl+→` | Accept the next word of the suggestion at the end of the line, otherwise move to the next word |
| `Tab` | List all completion candidates; select with `Tab` or the arrow keys |
| `Ctrl+D` | Exit when the line is empty, otherwise delete the character under the cursor |
| `Ctrl+E` | Move to the end of the line |
| `Ctrl+U` / `Ctrl+K` | Delete to the start / end of the line |

`Ctrl+D`, `Ctrl+E`, `Ctrl+U` and `Ctrl+K` are bound only when they are not already bound; existing key bindings are not overwritten.

## Options

```powershell
Enable-Plush -SkipPrompt          # keep the current prompt, configure line editing only
Enable-Plush -SkipReadLine        # keep the current PSReadLine settings, replace the prompt only
Enable-Plush -HistorySize 20000   # history entries kept in memory for search and suggestions, default 100000
```

## License

[MIT](LICENSE)
