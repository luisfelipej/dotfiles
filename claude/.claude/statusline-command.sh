#!/bin/sh
input=$(cat)

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
exceeds_200k=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')
session_id=$(echo "$input" | jq -r '.session_id // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
short_cwd=$(echo "$cwd" | awk -F/ '{if(NF>=2) print $(NF-1)"/"$NF; else print $NF}')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
duration_label=$(echo "$duration_ms" | awk '{
  s = int($1 / 1000);
  if (s >= 3600) printf "%dh%dm", s/3600, (s%3600)/60;
  else if (s >= 60) printf "%dm", s/60;
  else printf "%ds", s;
}')

# Context rot notification — fires once per session when crossing 200K
if [ "$exceeds_200k" = "true" ] && [ -n "$session_id" ]; then
  flag_file="/tmp/claude-rot-notified-${session_id}"
  if [ ! -f "$flag_file" ]; then
    touch "$flag_file"
    osascript -e 'display notification "Context exceeds 200K tokens. Consider starting a new conversation." with title "Claude Code" subtitle "Context Rot Warning" sound name "Funk"' 2>/dev/null &
  fi
fi

if [ -n "$used" ] && [ -n "$window_size" ]; then
  used_int=$(printf "%.0f" "$used")

  # Derive token count from percentage (most accurate cumulative value)
  tokens_int=$(echo "$used_int $window_size" | awk '{printf "%.0f", $1 * $2 / 100}')

  if [ "$used_int" -ge 80 ]; then
    color="\033[31m"
  elif [ "$used_int" -ge 50 ]; then
    color="\033[33m"
  else
    color="\033[32m"
  fi

  reset="\033[0m"

  # Format token count as human-readable
  if [ "$tokens_int" -ge 1000000 ]; then
    tokens_label="$(echo "$tokens_int" | awk '{printf "%.1fM", $1/1000000}')"
  elif [ "$tokens_int" -ge 1000 ]; then
    tokens_label="$(echo "$tokens_int" | awk '{printf "%.1fK", $1/1000}')"
  else
    tokens_label="${tokens_int}"
  fi

  # Context rot warning when over 200K tokens
  rot_warning=""
  if [ "$tokens_int" -ge 200000 ]; then
    rot_warning=" \033[31;1m[CONTEXT ROT]\033[0m"
  fi

  printf "${color}%d%% (%s)${reset}%b" "$used_int" "$tokens_label" "$rot_warning"

  if [ -n "$model" ]; then
    printf " | %s" "$model"
  fi

  if [ -n "$short_cwd" ]; then
    printf " | %s" "$short_cwd"
  fi

  printf " | +%s/-%s | %s" "$lines_added" "$lines_removed" "$duration_label"
else
  if [ -n "$model" ]; then
    printf "%s" "$model"
  fi

  if [ -n "$short_cwd" ]; then
    printf " | %s" "$short_cwd"
  fi
fi
