# Setting Up GitHub Secrets for AI Test Pipeline

This guide shows you how to add the `GIT_PUSH_TOKEN` secret to your GitHub repository so the pipeline can automatically push AI-generated tests.

## Step-by-Step Instructions

### 1. Create a Personal Access Token (if you haven't already)

1. Go to GitHub Settings: https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Configure:
   - **Note**: `AI Test Pipeline Token`
   - **Expiration**: 90 days (or your preference)
   - **Scopes**: ✅ Check `repo` (Full control of repositories)
4. Click **"Generate token"**
5. **COPY THE TOKEN** (starts with `ghp_...`) - you won't see it again!

### 2. Add Secret to Your Repository

#### Option A: Via GitHub Web UI

1. **Go to your repository on GitHub**:
   ```
   https://github.com/YaswanthPalepu/Tech_Demo_Project_POC
   ```

2. **Navigate to Settings**:
   - Click the **"Settings"** tab (top menu)
   - In the left sidebar, click **"Secrets and variables"** → **"Actions"**

3. **Add the secret**:
   - Click **"New repository secret"** button
   - **Name**: `GIT_PUSH_TOKEN`
   - **Value**: Paste your token (the one starting with `ghp_...`)
   - Click **"Add secret"**

#### Option B: Via GitHub CLI (if installed)

```bash
gh secret set GIT_PUSH_TOKEN --body "ghp_your_token_here"
```

### 3. Verify the Secret

1. Go to your repository → Settings → Secrets and variables → Actions
2. You should see `GIT_PUSH_TOKEN` listed
3. It will show when it was created/updated (value is hidden for security)

### 4. How the Workflow Uses the Secret

In the workflow file `.github/workflows/ai-test-pipeline.yml`:

```yaml
- name: Run AI Test Generation Pipeline
  env:
    # This line makes the secret available as environment variable
    GIT_PUSH_TOKEN: ${{ secrets.GIT_PUSH_TOKEN }}
  run: |
    ./pipeline_runner.sh
```

The `pipeline_runner.sh` script will automatically detect the `GIT_PUSH_TOKEN` environment variable and use it to push changes.

### 5. Test the Setup

#### Manual Test (GitHub UI):

1. Go to your repository on GitHub
2. Click **"Actions"** tab
3. Select **"AI Test Generation Pipeline"** from the left sidebar
4. Click **"Run workflow"** button (top right)
5. Select branch and click **"Run workflow"**
6. Watch the workflow run - it should push AI tests automatically!

#### Automatic Test (Push to Branch):

Simply push code to `main` or `develop` branch:

```bash
git push origin main
```

The workflow will trigger automatically.

## What Happens When Pipeline Runs

### With Secret Set ✅:
```
1. Workflow starts
2. Checks out code
3. Sets up Python
4. Runs pipeline_runner.sh
5. GIT_PUSH_TOKEN is available as environment variable
6. Pipeline generates AI tests
7. Commits tests to target repo
8. Pushes to remote using the token ✅
9. Workflow completes
```

### Without Secret ⚠️:
```
1. Workflow starts
2. Checks out code
3. Sets up Python
4. Runs pipeline_runner.sh
5. GIT_PUSH_TOKEN is empty
6. Pipeline generates AI tests
7. Commits tests to target repo
8. Skips push (warning message shown)
9. Workflow completes (but changes not pushed)
```

## Viewing Workflow Output

1. Go to **Actions** tab in your repository
2. Click on the workflow run
3. Click on the job name: `run-ai-test-pipeline`
4. Expand the step: **"Run AI Test Generation Pipeline"**
5. You'll see output like:

```
Committing AI-generated tests to target repository...
[main abc1234] chore: add AI-generated test cases
 3 files changed, 150 insertions(+)
AI-generated tests committed to target repository

Pushing changes to remote repository...
Enumerating objects: 5, done.
To https://github.com/YaswanthPalepu/your-repo.git
   abc1234..def5678  main -> main
Changes pushed to remote repository successfully ✅
```

## Security Notes

### ✅ Secrets are Secure:
- **Never visible** in logs or workflow output
- **Masked** automatically by GitHub Actions
- Only available to **your repository's workflows**
- Can only be used by workflows from **your repository**

### ✅ Best Practices:
1. Use **short expiration** for tokens (90 days recommended)
2. **Rotate tokens** regularly
3. Use **minimal permissions** (only `repo` scope)
4. **Revoke immediately** if compromised
5. **Never commit** secrets to code

## Troubleshooting

### Secret not working?

**Check 1**: Verify secret name is exactly `GIT_PUSH_TOKEN` (case-sensitive)

```bash
# In repository Settings → Secrets → Actions
# Should show: GIT_PUSH_TOKEN
```

**Check 2**: Verify workflow has access to secrets

```yaml
# Make sure this line is in your workflow:
GIT_PUSH_TOKEN: ${{ secrets.GIT_PUSH_TOKEN }}
```

**Check 3**: Check workflow logs for errors

```
Actions tab → Select workflow run → View logs
```

### Token expired?

1. Generate new token (same steps as above)
2. Go to repository Settings → Secrets → Actions
3. Click `GIT_PUSH_TOKEN` → **"Update"**
4. Paste new token and save

### Still having issues?

Check these common problems:
- Token has correct scope (`repo`)
- Token not expired
- Secret name matches exactly: `GIT_PUSH_TOKEN`
- Workflow file syntax is correct
- Repository has Actions enabled

## Summary

| Step | Action | Location |
|------|--------|----------|
| 1 | Create Token | https://github.com/settings/tokens |
| 2 | Add Secret | Repository → Settings → Secrets → Actions |
| 3 | Name Secret | `GIT_PUSH_TOKEN` |
| 4 | Verify | Check in Secrets list |
| 5 | Test | Actions → Run workflow |

**You're all set!** The pipeline will now automatically push AI-generated tests to your repository. 🚀
