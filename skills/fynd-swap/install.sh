#!/usr/bin/env bash
set -euo pipefail

REPO="tanayjain14/fynd-skills"
BRANCH="main"
BASE="skills/fynd-swap"
DEST="$HOME/.claude/skills/fynd-swap"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}/${BASE}"

FILES=(
  "SKILL.md"
  "docs/LEARNINGS.md"
  "docs/setup.md"
  "docs/tokens.md"
  "docs/troubleshooting.md"
  "docs/v1_learning.md"
  "scripts/fynd-run.sh"
)

echo "Installing fynd-swap skill into ${DEST}..."

mkdir -p "${DEST}/docs" "${DEST}/scripts"

for file in "${FILES[@]}"; do
  echo "  Downloading ${file}..."
  curl -fsSL "${RAW}/${file}" -o "${DEST}/${file}"
done

chmod +x "${DEST}/scripts/fynd-run.sh"

echo ""
echo "fynd-swap skill installed."
echo "Run it with: claude /fynd-swap"
