# plush：PowerShell 的提示符和行编辑配置

$e = [char]27
$onWindows = [Environment]::OSVersion.Platform -eq 'Win32NT'

function Test-Elevated {
  if (-not $onWindows) { return [Environment]::UserName -eq 'root' }
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-HostName {
  # Windows 上读注册表比 [Net.Dns]::GetHostName() 快几毫秒，后者首次调用要加载网络程序集
  # 不用 $env:COMPUTERNAME：它是 NetBIOS 名，超过 15 个字符会被截断
  $name = $null
  if ($onWindows) {
    $name = [Microsoft.Win32.Registry]::GetValue('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 'Hostname', $null)
  }
  if ($name) { $name } else { [Net.Dns]::GetHostName() }
}

# 从 $dir 往上找 .git 并读 HEAD，不启动 git 进程
# 返回分支名；游离 HEAD 返回短哈希；不在仓库里返回 $null
function Get-GitHead([string]$dir) {
  try {
    while ($dir) {
      $dotGit = [IO.Path]::Combine($dir, '.git')
      # 先探 .git\HEAD：普通仓库只需一次文件检查
      $headFile = [IO.Path]::Combine($dotGit, 'HEAD')
      $found = [IO.File]::Exists($headFile)
      if (-not $found -and [IO.File]::Exists($dotGit)) {
        # worktree / submodule：.git 是个文件，内容是 "gitdir: <真正的 git 目录>"
        $pointer = [IO.File]::ReadAllText($dotGit).Trim()
        if ($pointer.StartsWith('gitdir: ')) {
          $headFile = [IO.Path]::Combine($dir, $pointer.Substring(8), 'HEAD')
          $found = [IO.File]::Exists($headFile)
        }
      }
      if ($found) {
        $head = [IO.File]::ReadAllText($headFile).Trim()
        if ($head.StartsWith('ref: refs/heads/')) { return $head.Substring(16) }
        if ($head.StartsWith('ref: ')) { return $head.Substring(5) }
        if ($head.Length -ge 7) { return $head.Substring(0, 7) }
        return $head
      }
      $dir = [IO.Path]::GetDirectoryName($dir)
    }
  } catch { }
  $null
}

# 当前激活的 Python 环境名，没有则返回 $null
# 用 .NET 调用读环境变量：这段每次画提示符都会跑，比 $env: 快约 0.1 ms
function Get-VenvName {
  $venv = [Environment]::GetEnvironmentVariable('VIRTUAL_ENV')
  if (-not $venv) { return [Environment]::GetEnvironmentVariable('CONDA_DEFAULT_ENV') }
  $name = [IO.Path]::GetFileName($venv)
  # 目录名是 .venv 这类通用名时，上一级（项目）目录名更有辨识度
  if ('.venv', 'venv', '.env', 'env' -contains $name) {
    $name = [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($venv))
  }
  $name
}

# 三行提示符，样式来自 oh-my-zsh 的 ys 主题：
#   (venv)                                        <- 没有虚拟环境时是空行
#   # user @ host in ~\path on git:main [12:34:56] C:1
#   $
# $promptHead 是其中不变的部分（# [%] 用户名 @ 主机名 in），由 Enable-Plush 算一次
$promptBlock = {
  # 必须是第一条语句：上一条命令是否成功
  $ok = $?
  $code = $global:LASTEXITCODE

  $venv = Get-VenvName
  $venvText = if ($venv) { "${e}[37m(${venv})" } else { '' }

  # 当前路径，家目录缩写成 ~
  $loc = $PWD
  $isFs = $loc.Provider.Name -eq 'FileSystem'
  $path = if ($isFs) { $loc.ProviderPath } else { $loc.Path }
  $shown = $path
  if ($isFs -and $path.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase) -and
      ($path.Length -eq $HOME.Length -or $path[$HOME.Length] -eq [IO.Path]::DirectorySeparatorChar)) {
    $shown = '~' + $path.Substring($HOME.Length)
  }

  $branch = if ($isFs) { Get-GitHead $path }
  $gitText = if ($branch) { "${e}[90mon ${e}[37mgit:${e}[36m${branch} " } else { '' }

  # 上一条命令失败时显示退出码；cmdlet 失败没有退出码，显示 1
  $statusText = ''
  if (-not $ok) {
    $shownCode = if ($code) { $code } else { 1 }
    $statusText = " ${e}[31mC:${shownCode}"
  }

  $time = [DateTime]::Now.ToString('HH:mm:ss')
  "${venvText}`n${promptHead}${e}[93m${shown} ${gitText}${e}[90m[${time}]${statusText}${e}[0m`n${e}[91m`$${e}[0m "
}
# 光标所在行上方的行数，即上面格式串里 `n 的个数；PSReadLine 重绘提示符时需要知道
$promptExtraLines = 2

function Initialize-ReadLine([int]$HistorySize, [int]$ExtraPromptLines) {
  # 非交互会话用不到行编辑
  if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { return }

  $module = Get-Module PSReadLine
  if (-not $module) {
    try { $module = Import-Module PSReadLine -PassThru -ErrorAction Stop } catch { return }
  }
  # 历史建议、AcceptNextSuggestionWord、Get-PSReadLineKeyHandler -Chord 都是 2.1 加入的
  $modern = $module.Version -ge [version]'2.1.0'

  # 默认只把最近 4096 条历史读进内存，更早的命令搜不到；搜到后光标停在行尾
  Set-PSReadLineOption -MaximumHistoryCount $HistorySize -HistorySearchCursorMovesToEnd
  if ($ExtraPromptLines) {
    Set-PSReadLineOption -ExtraPromptLineCount $ExtraPromptLines
  }

  # 上/下箭头按已输入的前缀搜历史；空行时就是上一条/下一条
  Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
  # Tab 列出全部候选，Tab / 方向键选择
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

  if ($modern) {
    # 输入时以灰字显示历史里匹配的命令，→ 或 End 接受整条
    # 终端不支持 VT 转义序列时这个选项会抛错，此时不开启建议
    try { Set-PSReadLineOption -PredictionSource History -ErrorAction Stop } catch { }

    # Ctrl+→：光标在行尾时只接受建议里的下一个词，否则照常跳词
    Set-PSReadLineKeyHandler -Key Ctrl+RightArrow `
      -BriefDescription AcceptNextSuggestionWordOrNextWord `
      -Description 'Accept the next word of the suggestion at end of line, otherwise move to the next word' `
      -ScriptBlock {
        param($key, $arg)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($cursor -lt $line.Length) {
          [Microsoft.PowerShell.PSConsoleReadLine]::NextWord($key, $arg)
        } else {
          [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
        }
      }
  } else {
    Write-Warning "plush: history suggestions need PSReadLine 2.1+, found $($module.Version). Upgrade with: Install-Module PSReadLine -Scope CurrentUser -Force"
  }

  # 几个 Emacs 风格的常用键，只在还没有绑定时才加，不覆盖已有按键
  $extraKeys = @{
    'Ctrl+d' = 'DeleteCharOrExit'
    'Ctrl+e' = 'EndOfLine'
    'Ctrl+u' = 'BackwardDeleteLine'
    'Ctrl+k' = 'ForwardDeleteLine'
  }
  # 只查这几个键比列出全部绑定快得多
  $handlers = if ($modern) { Get-PSReadLineKeyHandler -Chord @($extraKeys.Keys) } else { Get-PSReadLineKeyHandler -Bound }
  $bound = @(foreach ($handler in $handlers) { $handler.Key })
  foreach ($key in $extraKeys.Keys) {
    if ($bound -cnotcontains $key) {
      Set-PSReadLineKeyHandler -Key $key -Function $extraKeys[$key]
    }
  }
}

<#
.SYNOPSIS
Turns on the plush prompt and line editing for the current session.

.DESCRIPTION
Replaces the prompt with a three-line prompt drawn in pure PowerShell (no external
process, git branch read from .git/HEAD), and configures PSReadLine so that the
arrow keys search history by prefix, history suggestions appear inline, and Tab
opens a completion menu.

.PARAMETER SkipPrompt
Keep the current prompt; only configure line editing.

.PARAMETER SkipReadLine
Keep the current PSReadLine settings; only replace the prompt.

.PARAMETER HistorySize
How many history entries PSReadLine keeps in memory for search and suggestions.

.EXAMPLE
Enable-Plush

.EXAMPLE
Enable-Plush -SkipPrompt -HistorySize 20000
#>
function Enable-Plush {
  [CmdletBinding()]
  param(
    [switch]$SkipPrompt,
    [switch]$SkipReadLine,
    [ValidateRange(1, [int]::MaxValue)]
    [int]$HistorySize = 100000
  )

  if (-not $SkipPrompt) {
    $adminMark = if (Test-Elevated) { "${e}[31m% " } else { '' }
    $script:promptHead = "${e}[94m# ${adminMark}${e}[36m$([Environment]::UserName) ${e}[90m@ ${e}[32m$(Get-HostName) ${e}[90min "

    # venv 的激活脚本默认会自己改 prompt，关掉，由上面的提示符统一画
    $env:VIRTUAL_ENV_DISABLE_PROMPT = '1'
    # 不用 Set-Item：首次调用 provider cmdlet 要多花约 90 ms
    ${function:global:prompt} = $promptBlock
  }

  if (-not $SkipReadLine) {
    $extraLines = if ($SkipPrompt) { 0 } else { $promptExtraLines }
    Initialize-ReadLine -HistorySize $HistorySize -ExtraPromptLines $extraLines
  }
}

Export-ModuleMember -Function Enable-Plush
