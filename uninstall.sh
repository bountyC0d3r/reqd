#!/usr/bin/env bash
set -e

# reqd uninstaller

LOCAL=false

for arg in "$@"; do
  case $arg in
    --local) LOCAL=true ;;
  esac
done

if [ "$LOCAL" = true ]; then
  TARGET_DIR="$(pwd)/.claude"
  SCOPE="local ($(pwd))"
else
  TARGET_DIR="$HOME/.claude"
  SCOPE="global (~/.claude)"
fi

echo ""
echo "reqd uninstaller"
echo "────────────────────────────────────"
echo "  scope: $SCOPE"
echo ""

# Remove commands
if [ -d "$TARGET_DIR/commands/reqd" ]; then
  rm -rf "$TARGET_DIR/commands/reqd"
  echo "  ✓ Removed commands/reqd/"
fi

# Remove skills
for skill_dir in "$TARGET_DIR/skills/reqd-"*/; do
  if [ -d "$skill_dir" ]; then
    skill_name="$(basename "$skill_dir")"
    rm -rf "$skill_dir"
    echo "  ✓ Removed skills/$skill_name/"
  fi
done

echo ""
echo "reqd uninstalled."
echo "Note: Project data in reqd/changes/ was not removed."
echo ""
