#!/usr/bin/env bash
set -euo pipefail
SKILL_DIR="$HOME/.claude/skills/fynd-swap"
REPO="tanayjain14/fynd-skills"
BRANCH="main"
BASE="https://raw.githubusercontent.com/$REPO/$BRANCH/skills/fynd-swap"
mkdir -p "$SKILL_DIR/references" "$SKILL_DIR/scripts"
for file in SKILL.md LEARNINGS.md; do
  curl -fsSL "$BASE/$file" -o "$SKILL_DIR/$file"
done
for file in setup.md troubleshooting.md tokens.md; do
  curl -fsSL "$BASE/references/$file" -o "$SKILL_DIR/references/$file"
done
curl -fsSL "$BASE/scripts/fynd-run.sh" -o "$SKILL_DIR/scripts/fynd-run.sh"
chmod +x "$SKILL_DIR/scripts/fynd-run.sh"
echo "fynd-swap installed to $SKILL_DIR"
echo "Open Claude Code and type /fynd-swap to get started."
