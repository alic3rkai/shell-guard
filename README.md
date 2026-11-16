# Shell Guard

A Claude Code plugin that tells Claude what **your** terminal can actually run.

Claude's own shell is not your terminal. It may have a different PATH, a different shell, or tools you don't. The result: Claude hands you a command, you paste it, and it fails. `&&` in Windows PowerShell 5.1, `python` that isn't on your PATH, the Microsoft Store `python` stub, Apple's `python3` stub, bash syntax in fish.

Shell Guard runs once when a session starts, checks what a fresh terminal of yours would see, and gives Claude a short note like this:

```
Shell Guard: the user's own terminal (not yours) as a fresh window would see it.
Default shell: Windows PowerShell 5.1. No '&&' or '||'; use 'A; if ($?) { B }'.
python: C:\Users\you\AppData\Local\Programs\Python\Python312\python.exe
py: NOT on the user's PATH.
node: C:\Program Files\nodejs\node.exe
git: C:\Program Files\Git\cmd\git.exe
```

## Install

```
claude plugin marketplace add alic3rkai/shell-guard
claude plugin install shell-guard@shell-guard
```

Then start a new session. On Windows you can also clone the repo and double-click `install.bat`.

## What it checks

| | Windows | macOS / Linux |
|---|---|---|
| Shell | Windows PowerShell 5.1 rules, notes PowerShell 7 if installed | Your login shell (bash, zsh, fish) and its quirks |
| PATH | Read from the registry, the way a new terminal gets it | Asked from your login shell, so `.zprofile`, Homebrew, nvm and pyenv count |
| Tools | python, py, node, npm, git | python3, python, node, npm, git, brew |
| Traps | Microsoft Store `python` stub, Python installed but off PATH | Apple's `python3` stub without Command Line Tools |

## Limits

- It describes the terminal; it does not rewrite Claude's commands.
- It assumes you use your default shell. If you switch shells, Claude won't know.
- macOS and Linux are tested in CI only, not yet by daily users. Reports welcome.

## How it works

`hooks/hooks.json` registers one `SessionStart` hook. On Windows it runs `hooks/detect.ps1`; elsewhere `hooks/detect.sh`. Whatever the script prints is added to Claude's context. No network, no files written.

## Licence

MIT
