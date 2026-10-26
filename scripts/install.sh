#!/usr/bin/env bash
# Pull this repo, then copy the skills into ~/.agents/skills.
# Re-running is safe: each destination is replaced wholesale.
set -euo pipefail

SKILLS=(ship grilling tdd diagnosing-bugs)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${HOME}/.agents/skills"

if [ -d "${REPO_DIR}/.git" ]; then
  # Only pull when a remote is configured; a fresh local repo has none, and
  # `git pull` would fail with no tracking branch.
  if [ -n "$(git -C "${REPO_DIR}" remote)" ]; then
    echo "Pulling ${REPO_DIR}..."
    git -C "${REPO_DIR}" pull --ff-only
  else
    echo "No remote configured; installing from the working tree."
  fi
fi

mkdir -p "${DEST}"
for name in "${SKILLS[@]}"; do
  if [ ! -d "${REPO_DIR}/${name}" ]; then
    echo "skip ${name}: not in this repo" >&2
    continue
  fi
  rm -rf "${DEST:?}/${name}"
  cp -R "${REPO_DIR}/${name}" "${DEST}/${name}"
  echo "installed ${name}"
done

echo "Done. Skills are re-read on the next session."
