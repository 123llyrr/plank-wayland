#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

follow_icon_theme_enabled() {
  local line
  [[ -r "$project_dir/settings.js" ]] || return 0
  while IFS= read -r line; do
    if [[ "$line" =~ "followSystemIconTheme"[[:space:]]*:[[:space:]]*false ]]; then
      return 1
    fi
  done < "$project_dir/settings.js"
  return 0
}

detect_icon_theme() {
  local file line in_icons

  for file in \
    "$HOME/.config/gtk-3.0/settings.ini" \
    "$HOME/.config/gtk-4.0/settings.ini"; do
    [[ -r "$file" ]] || continue
    while IFS= read -r line; do
      if [[ "$line" =~ ^[[:space:]]*gtk-icon-theme-name[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
      fi
    done < "$file"
  done

  file="$HOME/.config/kdeglobals"
  if [[ -r "$file" ]]; then
    in_icons=0
    while IFS= read -r line; do
      [[ "$line" == "[Icons]" ]] && { in_icons=1; continue; }
      [[ "$line" == \[* ]] && in_icons=0
      if [[ "$in_icons" == 1 && "$line" =~ ^[[:space:]]*Theme[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
      fi
    done < "$file"
  fi
}

if follow_icon_theme_enabled && [[ -z "${QS_ICON_THEME:-}" ]]; then
  icon_theme="$(detect_icon_theme || true)"
  if [[ -n "$icon_theme" ]]; then
    export QS_ICON_THEME="$icon_theme"
  fi
fi

exec quickshell --path "$project_dir/shell.qml"
