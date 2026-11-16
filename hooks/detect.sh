#!/bin/sh
# Shell Guard for macOS and Linux: tell Claude what the USER's terminal can run.
# Claude's process may not have the PATH a login shell builds (~/.zprofile,
# brew shellenv, nvm, pyenv), so ask the user's login shell for its PATH.

user_shell="${SHELL:-/bin/sh}"
shell_name=$(basename "$user_shell")
os=$(uname -s)

# macOS has no `timeout`; the hook's own 15 s timeout covers a hanging profile there.
t=""; command -v timeout >/dev/null 2>&1 && t="timeout 5"
case "$shell_name" in
  fish) user_path=$($t "$user_shell" -l -c 'string join : $PATH' 2>/dev/null) ;;
  *)    user_path=$($t "$user_shell" -l -c 'printf %s "$PATH"' 2>/dev/null) ;;
esac
[ -n "$user_path" ] || user_path="$PATH"

find_tool() {
  old_ifs=$IFS; IFS=:
  for d in $user_path; do
    if [ -x "$d/$1" ]; then IFS=$old_ifs; echo "$d/$1"; return 0; fi
  done
  IFS=$old_ifs; return 1
}

echo "Shell Guard: the user's own terminal (not yours) as a new login shell would see it."
echo "OS: $os. Shell: $shell_name ($user_shell)."
case "$shell_name" in
  fish) echo "fish is not POSIX: no heredocs, use 'set -x VAR value' instead of 'VAR=value cmd', and 'and'/'or' are safest for chaining." ;;
  zsh)  echo "zsh: unquoted globs that match nothing are an error (quote URLs and args with ? or *)." ;;
esac

for t in python3 python node npm git brew; do
  [ "$t" = brew ] && [ "$os" != Darwin ] && continue
  if p=$(find_tool "$t"); then
    if [ "$os" = Darwin ] && [ "$p" = /usr/bin/python3 ] && ! xcode-select -p >/dev/null 2>&1; then
      echo "$t: only Apple's stub at $p; it asks to install the Command Line Tools instead of running."
    else
      echo "$t: $p"
    fi
  else
    echo "$t: NOT on the user's PATH."
  fi
done

echo "Rule: commands you give the user must run in this shell. If a tool is not on PATH, use its full path or tell them how to install it."
