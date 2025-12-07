# Git Push Setup Guide

This guide explains how to enable automatic pushing of AI-generated tests to your remote repository.

## What You Need

To push AI tests to GitHub/GitLab automatically, you need a **Personal Access Token (PAT)**.

## Step 1: Create a Personal Access Token

### For GitHub:

1. **Go to GitHub Settings**:
   - Click your profile picture (top right) → Settings
   - Or visit: https://github.com/settings/tokens

2. **Generate Token**:
   - Scroll down to "Developer settings" (left sidebar)
   - Click "Personal access tokens" → "Tokens (classic)"
   - Click "Generate new token" → "Generate new token (classic)"

3. **Configure Token**:
   - **Note**: `AI Test Pipeline Token` (or any name you like)
   - **Expiration**: Choose your preferred expiration (e.g., 90 days, 1 year, or No expiration)
   - **Select scopes**: Check these permissions:
     - ✅ `repo` (Full control of private repositories)
       - This includes: `repo:status`, `repo_deployment`, `public_repo`, `repo:invite`

4. **Generate and Copy**:
   - Click "Generate token" at the bottom
   - **IMPORTANT**: Copy the token NOW! You won't see it again
   - Token looks like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### For GitLab:

1. **Go to GitLab Settings**:
   - Click your profile picture → Settings → Access Tokens
   - Or visit: https://gitlab.com/-/profile/personal_access_tokens

2. **Create Token**:
   - **Token name**: `AI Test Pipeline Token`
   - **Expiration date**: Choose your preferred date
   - **Select scopes**:
     - ✅ `write_repository`
     - ✅ `read_repository`

3. **Create and Copy**:
   - Click "Create personal access token"
   - Copy the token immediately

## Step 2: Use the Token in Your Pipeline

### Option 1: Set Environment Variable (Recommended for CI/CD)

Before running the pipeline, set the `GIT_PUSH_TOKEN` environment variable:

```bash
export GIT_PUSH_TOKEN="your_token_here"
```

Then run your pipeline:

```bash
./pipeline_runner.sh
```

### Option 2: Set in Pipeline Script

Add this at the top of your pipeline script:

```bash
export GIT_PUSH_TOKEN="your_token_here"
./pipeline_runner.sh
```

### Option 3: GitHub Actions / GitLab CI

#### GitHub Actions:

1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GIT_PUSH_TOKEN`
4. Value: Paste your token
5. Click "Add secret"

Then in your workflow file (`.github/workflows/pipeline.yml`):

```yaml
env:
  GIT_PUSH_TOKEN: ${{ secrets.GIT_PUSH_TOKEN }}
```

#### GitLab CI:

1. Go to your project → Settings → CI/CD → Variables
2. Click "Add variable"
3. Key: `GIT_PUSH_TOKEN`
4. Value: Paste your token
5. Check "Mask variable" and "Protect variable"
6. Click "Add variable"

The pipeline will automatically use `$GIT_PUSH_TOKEN` from environment.

## Step 3: Run the Pipeline

When you run the pipeline with `GIT_PUSH_TOKEN` set:

```bash
export GIT_PUSH_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
./pipeline_runner.sh
```

### What Happens:

1. ✅ AI tests are generated
2. ✅ Tests are copied to `target_repo/tests/generated/`
3. ✅ Tests are committed to local git
4. ✅ **Tests are pushed to remote repository** (GitHub/GitLab)

### Expected Output:

```bash
Committing AI-generated tests to target repository...
[main abc1234] chore: add AI-generated test cases
 3 files changed, 150 insertions(+)
AI-generated tests committed to target repository

Pushing changes to remote repository...
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 4 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 1.23 KiB | 1.23 MiB/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To https://github.com/YaswanthPalepu/your-repo.git
   abc1234..def5678  main -> main
Changes pushed to remote repository successfully
```

## Without Token (Local Commit Only)

If you don't set `GIT_PUSH_TOKEN`, the pipeline will:

1. ✅ Generate AI tests
2. ✅ Copy to `target_repo/tests/generated/`
3. ✅ Commit locally
4. ⚠️ Skip push (you'll see this message):

```bash
Skipping push: GIT_PUSH_TOKEN not provided (set GIT_PUSH_TOKEN environment variable to enable auto-push)
```

You can manually push later:

```bash
cd target_repo
git push origin main
```

## Security Best Practices

### ⚠️ IMPORTANT: Keep Your Token Safe!

1. **Never commit tokens to git**:
   ```bash
   # ❌ WRONG - Don't do this!
   export GIT_PUSH_TOKEN="ghp_xxxx"  # in a committed script

   # ✅ CORRECT - Use environment variables
   # Set in terminal or CI/CD secrets
   ```

2. **Use `.gitignore`** for files with tokens:
   ```
   .env
   secrets.sh
   *_token.txt
   ```

3. **Rotate tokens regularly**: Generate new tokens every 90 days

4. **Use minimal permissions**: Only grant `repo` scope, nothing more

5. **Revoke if compromised**: If token is leaked, revoke it immediately in GitHub/GitLab settings

## Troubleshooting

### Error: "Failed to push to remote repository"

**Possible causes**:

1. **Invalid token**: Generate a new token
2. **Token expired**: Check expiration date, generate new one
3. **Insufficient permissions**: Token needs `repo` or `write_repository` scope
4. **Branch protected**: You may need to push to a different branch
5. **Network issues**: Check your internet connection

### Error: "Authentication failed"

**Solution**:
- Verify your token is correct
- Make sure you copied the entire token (starts with `ghp_` for GitHub or `glpat-` for GitLab)
- Check token hasn't expired

### No push happening but no error

**Check**:
```bash
echo $GIT_PUSH_TOKEN
```

If empty, the token isn't set. Export it before running the pipeline.

## Example: Complete Pipeline Run

```bash
# Set your token
export GIT_PUSH_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Run the pipeline
./pipeline_runner.sh

# Output will show:
# 1. Test detection
# 2. Test copying
# 3. Test execution
# 4. AI generation
# 5. Commit to target repo
# 6. Push to remote ✅
```

## Summary

| Requirement | Value |
|-------------|-------|
| Token Type | Personal Access Token (PAT) |
| GitHub Scope | `repo` (full control) |
| GitLab Scope | `write_repository`, `read_repository` |
| Environment Variable | `GIT_PUSH_TOKEN` |
| Token Format (GitHub) | `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| Token Format (GitLab) | `glpat-xxxxxxxxxxxxxxxxxxxxxxxx` |

✅ **You're all set!** The pipeline will now automatically push AI tests to your repository.
