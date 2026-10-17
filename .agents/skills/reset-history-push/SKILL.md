---
name: reset-history-push
description: >-
  Use this skill when the user asks to reset or initialize git history, perform a '초기화 푸시' (clean reset push),
  or reset remote history while archiving the previous commits to a local-only branch.
---

# Reset History Push (이력 초기화 푸시)

This skill safely archives the current Git commit history into a **local-only branch** (`archive/YYYY-MM-DD`) and resets the remote repository (`origin/main`) to a clean state containing a single initial commit.

## When to Run

- User asks: `"초기화 푸시 해줘"`, `"이력 초기화 푸시해줘"`, `"리모트 초기화 푸시"`, or `"git reset push"`.

## Safety Guarantees

1. **No Data Loss**: Any uncommitted or modified files in the working directory are staged and committed before creating the archive branch.
2. **Local Preservation**: The archive branch is strictly kept in the local repository and **never** pushed to the remote (`origin`).
3. **Clean Slate**: A new orphan branch is created, replacing `main`, and force-pushed to the remote as a single clean initial commit.

## Execution Procedure

Run the helper script directly:

```bash
bash .agents/skills/reset-history-push/scripts/reset-history.sh
```

### Manual Steps (Reference)

If the script cannot be run directly:

1. Switch to `main` branch.
2. If working directory has changes, commit them:
   ```bash
   git add -A && git commit -m "chore: save working state before history reset [$(date +'%Y-%m-%d %H:%M:%S')]"
   ```
3. Create local-only archive branch:
   ```bash
   git branch "archive/$(date +'%Y-%m-%d')"
   ```
4. Create an orphan branch:
   ```bash
   git checkout --orphan temp-clean-reset
   git add -A
   git commit -m "Initial commit"
   ```
5. Rename orphan branch to `main`:
   ```bash
   git branch -M main
   ```
6. Force push to remote:
   ```bash
   git push -f origin main
   ```
7. Verify:
   ```bash
   git branch
   git log --oneline -n 2
   git branch -r
   ```
