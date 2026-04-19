#!/usr/bin/env bash
set -e

# reqd — requirements-driven development lifecycle for Claude Code
# https://github.com/bountyC0d3r/reqd

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL=false
ASSISTANT="claude"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF

Usage: ./install.sh [assistant] [--local] [--help]

  assistant   Target AI assistant. One of: claude (default), opencode, cursor

  --local     Install into the current project directory only
              (default: install globally into the assistant's config home)

  --help, -h  Show this help text

Target directories resolved per assistant:

  claude
    global  CLAUDE_CONFIG_DIR  →  \${XDG_CONFIG_HOME}/claude  →  ~/.claude
    local   ./.claude

  opencode
    global  \${XDG_CONFIG_HOME}/opencode  →  ~/.config/opencode
    local   ./.opencode

  cursor
    global  ~/.cursor
    local   ./.cursor

Examples:
  ./install.sh                     # claude, global
  ./install.sh --local             # claude, local
  ./install.sh opencode            # opencode, global
  ./install.sh opencode --local    # opencode, local
  ./install.sh cursor --local      # cursor, local

EOF
}

# ---------------------------------------------------------------------------
# Parse args  (order-independent: assistant + --local can appear in any order)
# ---------------------------------------------------------------------------
for arg in "$@"; do
  case $arg in
    --local)      LOCAL=true ;;
    --help|-h)    usage; exit 0 ;;
    claude|opencode|cursor) ASSISTANT="$arg" ;;
    *)
      echo "Error: unknown argument '$arg'" >&2
      echo "Run ./install.sh --help for usage." >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve target directory
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
    cursor)
      echo "$HOME/.cursor"
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
# Install
# ---------------------------------------------------------------------------
echo ""
echo "reqd installer"
echo "────────────────────────────────────"
echo "  assistant: $ASSISTANT"
echo "  scope:     $SCOPE"
echo "  source:    $REPO_DIR"
echo ""

# Create target directories
mkdir -p "$TARGET_DIR/commands/reqd"
mkdir -p "$TARGET_DIR/skills"

# Install commands
echo "Installing commands..."
for cmd in "$REPO_DIR/.claude/commands/reqd/"*.md; do
  name="$(basename "$cmd")"
  cp "$cmd" "$TARGET_DIR/commands/reqd/$name"
  echo "  ✓ /reqd:${name%.md}"
done

# Install skills
echo ""
echo "Installing skills..."
for skill_dir in "$REPO_DIR/.claude/skills/reqd-"*/; do
  skill_name="$(basename "$skill_dir")"
  mkdir -p "$TARGET_DIR/skills/$skill_name"
  cp "$skill_dir/SKILL.md" "$TARGET_DIR/skills/$skill_name/SKILL.md"
  echo "  ✓ $skill_name"
done

echo ""
echo "────────────────────────────────────"
echo "reqd installed successfully."
echo ""
echo "Get started in any project:"
echo "  /reqd:new <change-name>"
echo ""
echo "First time in a project? reqd will scaffold reqd/config.yaml for you."
echo ""
