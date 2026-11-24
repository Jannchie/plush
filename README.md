# plush

[English](README.en.md)

plush 为 PowerShell 配置提示符和行编辑：上箭头按已输入的前缀搜索历史，输入时显示来自历史的灰字建议，Tab 打开补全菜单。

提示符由 PowerShell 函数直接绘制，不启动外部进程，git 分支从 `.git/HEAD` 读取。在 Windows PowerShell 5.1 上单次绘制不到 1 ms；oh-my-posh 每次绘制都要启动一个进程，在同一台机器上约 110–160 ms。

## 安装

需要 PowerShell 5.1 或更高版本。

```powershell
git clone https://github.com/Jannchie/plush.git $HOME\plush
```

在 `$PROFILE` 中加入：

```powershell
Import-Module $HOME\plush\plush.psd1
Enable-Plush
```

历史建议需要 PSReadLine 2.1 或更高版本。Windows PowerShell 5.1 自带 2.0，升级命令：

```powershell
Install-Module PSReadLine -Scope CurrentUser -Force
```

## 提示符

```
(myenv)
# % alice @ DESKTOP in ~\code\plush on git:main [16:20:49] C:1
$
```

- `(myenv)`：当前激活的 Python 虚拟环境或 conda 环境；没有时该行为空行。虚拟环境目录名为 `.venv`、`venv` 等通用名时，显示其上一级目录名
- `%`：仅在管理员（或 root）会话中显示
- `on git:main`：当前分支；游离 HEAD 显示短哈希；支持 worktree 和 submodule。不查询工作区是否有改动
- `C:1`：上一条命令失败时显示其退出码

样式来自 oh-my-zsh 的 [ys 主题](https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/ys.zsh-theme)。

## 按键

| 按键 | 行为 |
| --- | --- |
| `↑` / `↓` | 按已输入的前缀搜索历史；输入为空时逐条翻阅 |
| `→` / `End` | 接受整条灰字建议 |
| `Ctrl+→` | 光标在行尾时接受建议中的下一个词，否则跳到下一个词 |
| `Tab` | 列出全部补全候选，用 `Tab` 或方向键选择 |
| `Ctrl+D` | 输入为空时退出，否则删除光标处的字符 |
| `Ctrl+E` | 跳到行尾 |
| `Ctrl+U` / `Ctrl+K` | 删除到行首 / 行尾 |

`Ctrl+D`、`Ctrl+E`、`Ctrl+U`、`Ctrl+K` 仅在尚未绑定时才会绑定，已有的按键不会被覆盖。

## 选项

```powershell
Enable-Plush -SkipPrompt          # 保留现有提示符，只配置行编辑
Enable-Plush -SkipReadLine        # 保留现有 PSReadLine 设置，只替换提示符
Enable-Plush -HistorySize 20000   # 读入内存供搜索和建议使用的历史条数，默认 100000
```

## License

[MIT](LICENSE)
