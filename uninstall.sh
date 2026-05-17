#!/usr/bin/env bash
set -e

# reqd uninstaller
# https://github.com/bountyC0d3r/reqd

LOCAL=false
ASSISTANT="claude"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF

Usage: ./uninstall.sh [assistant] [--local] [--help]

  assistant   Target AI assistant. One of: claude (default), opencode

  --local     Uninstall from the current project directory only
              (default: uninstall from the assistant's global config home)

  --help, -h  Show this help text

Target directories resolved per assistant:

  claude
    global  CLAUDE_CONFIG_DIR  →  \${XDG_CONFIG_HOME}/claude  →  ~/.claude
    local   ./.claude

  opencode
    global  \${XDG_CONFIG_HOME}/opencode  →  ~/.config/opencode
    local   ./.opencode

Examples:
  ./uninstall.sh                     # claude, global
  ./uninstall.sh --local             # claude, local
  ./uninstall.sh opencode            # opencode, global
  ./uninstall.sh opencode --local    # opencode, local

EOF
}

# ---------------------------------------------------------------------------
# Parse args  (order-independent: assistant + --local can appear in any order)
# ---------------------------------------------------------------------------
for arg in "$@"; do
  case $arg in
    --local)           LOCAL=true ;;
    --help|-h)         usage; exit 0 ;;
    claude|opencode)   ASSISTANT="$arg" ;;
    *)
      echo "Error: unknown argument '$arg'" >&2
      echo "Run ./uninstall.sh --help for usage." >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve target directory  (mirrors install.sh exactly)
# ---------------------------------------------------------------------------
resolve_global_dir() {
  case "$ASSISTANT" in
    claude)
      if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
        echo "$CLAUDE_CONFIG_DIR"
      elif [ -n "${XDG_CONFIG_HOME:-}" ]; then
        echo "$XDG_CONFIG_HOME/claude"
      else
        echo "$HOME/.claude"
      fi
      ;;
    opencode)
      if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        echo "$XDG_CONFIG_HOME/opencode"
      else
        echo "$HOME/.config/opencode"
      fi
      ;;
  esac
}

if [ "$LOCAL" = true ]; then
  TARGET_DIR="$(pwd)/.$ASSISTANT"
  SCOPE="local ($(pwd)/.$ASSISTANT)"
else
  TARGET_DIR="$(resolve_global_dir)"
  SCOPE="global ($TARGET_DIR)"
fi

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------
echo ""
echo "reqd uninstaller"
echo "────────────────────────────────────"
echo "  assistant: $ASSISTANT"
echo "  scope:     $SCOPE"
echo ""

# Remove commands
if [ -d "$TARGET_DIR/commands/reqd" ]; then
  rm -rf "$TARGET_DIR/commands/reqd"
  echo "  ✓ Removed commands/reqd/"
else
  echo "  — commands/reqd/ not found, skipping"
fi

# Remove skills
REMOVED_SKILLS=0
for skill_dir in "$TARGET_DIR/skills/reqd-"*/; do
  if [ -d "$skill_dir" ]; then
    skill_name="$(basename "$skill_dir")"
    rm -rf "$skill_dir"
    echo "  ✓ Removed skills/$skill_name/"
    REMOVED_SKILLS=$((REMOVED_SKILLS + 1))
  fi
done
if [ "$REMOVED_SKILLS" -eq 0 ]; then
  echo "  — no reqd skills found, skipping"
fi

echo ""
echo "reqd uninstalled."
echo "Note: Project data in reqd/changes/ was not removed."
echo ""
