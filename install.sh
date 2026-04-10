#!/usr/bin/env bash
set -e

# reqd — requirements-driven development lifecycle for Claude Code
# https://github.com/your-org/reqd

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL=false

# Parse flags
for arg in "$@"; do
  case $arg in
    --local) LOCAL=true ;;
    --help|-h)
      echo "Usage: ./install.sh [--local]"
      echo ""
      echo "  (default)  Install globally to ~/.claude/ — available in all projects"
      echo "  --local    Install to ./.claude/ in current directory only"
      exit 0
      ;;
  esac
done

# Determine target
if [ "$LOCAL" = true ]; then
  TARGET_DIR="$(pwd)/.claude"
  SCOPE="local ($(pwd))"
else
  TARGET_DIR="$HOME/.claude"
  SCOPE="global (~/.claude)"
fi

echo ""
echo "reqd installer"
echo "────────────────────────────────────"
echo "  scope:  $SCOPE"
echo "  source: $REPO_DIR"
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
