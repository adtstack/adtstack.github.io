#!/usr/bin/env bash
set -euo pipefail

# 1. Verify Git Repository
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "❌ Error: Not a git repository." >&2
  exit 1
}
cd "$REPO_ROOT"

# Target branch to reset
TARGET_BRANCH="main"

# Check current branch
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]; then
  echo "⚠️ Current branch is '$CURRENT_BRANCH'. Switching to '$TARGET_BRANCH'..."
  git checkout "$TARGET_BRANCH"
fi

# 2. Stage and commit uncommitted changes so nothing is lost
if [ -n "$(git status --porcelain)" ]; then
  echo "💾 Staging and committing working directory changes before archiving..."
  git add -A
  git commit -m "chore: save working state before history reset [$(date +'%Y-%m-%d %H:%M:%S')]"
fi

# 3. Create local-only archive branch
TODAY="$(date +'%Y-%m-%d')"
ARCHIVE_BRANCH="archive/${TODAY}"

if git show-ref --verify --quiet "refs/heads/${ARCHIVE_BRANCH}"; then
  ARCHIVE_BRANCH="archive/${TODAY}_$(date +'%H%M%S')"
fi

echo "📦 Creating local-only archive branch: ${ARCHIVE_BRANCH}..."
git branch "${ARCHIVE_BRANCH}"

# 4. Create an orphan branch with no history
echo "🌱 Initializing clean orphan branch..."
git checkout --orphan temp-clean-reset

# 5. Add all files to the clean initial commit
git add -A
COMMIT_MSG="Initial commit"
git commit -m "${COMMIT_MSG}"

# 6. Replace main branch locally
git branch -M "${TARGET_BRANCH}"

# 7. Force push to remote origin
echo "🚀 Force pushing clean ${TARGET_BRANCH} branch to remote origin..."
git push -f origin "${TARGET_BRANCH}"

echo ""
echo "=========================================================="
echo "✅ History Reset Push Completed Successfully!"
echo "----------------------------------------------------------"
echo "  • Local Archive Branch: ${ARCHIVE_BRANCH} (Kept locally only)"
echo "  • Remote Branch:        origin/${TARGET_BRANCH} (Single initial commit)"
echo "=========================================================="
