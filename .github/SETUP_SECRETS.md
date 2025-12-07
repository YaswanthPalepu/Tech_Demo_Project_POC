# How to Add GitHub Secret for Pipeline

This guide shows you how to add `GIT_PUSH_TOKEN` to GitHub Secrets.

## Step 1: Create GitHub Token

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Settings:
   - **Note**: `AI Test Pipeline Token`
   - **Expiration**: 90 days (recommended)
   - **Scopes**: ✅ Check `repo` (Full control of repositories)
4. Click **"Generate token"**
5. **COPY THE TOKEN** (starts with `ghp_...`) - You won't see it again!

## Step 2: Add Secret to Repository

1. Go to your repository: 
   ```
   https://github.com/YaswanthPalepu/Tech_Demo_Project_POC
   ```

2. Click **Settings** → **Secrets and variables** → **Actions**

3. Click **"New repository secret"**

4. Enter:
   - **Name**: `GIT_PUSH_TOKEN` (exactly this!)
   - **Secret**: Paste your token
   
5. Click **"Add secret"**

## Step 3: Run Pipeline Manually

1. Go to **Actions** tab in your repository
2. Click **"AI Test Generation Pipeline"** (left sidebar)
3. Click **"Run workflow"** button (right side)
4. Select branch (usually `main`)
5. Click **"Run workflow"** button

## That's It!

The workflow will:
- ✅ Use your `GIT_PUSH_TOKEN` from secrets
- ✅ Run the pipeline
- ✅ Commit and push AI tests automatically

## How It Works

The workflow file uses your secret like this:

```yaml
env:
  GIT_PUSH_TOKEN: ${{ secrets.GIT_PUSH_TOKEN }}
```

The `pipeline_runner.sh` automatically detects and uses this token to push AI tests.

## Security

- ✅ Token is encrypted in GitHub
- ✅ Never visible in logs (masked automatically)
- ✅ Only you can add/edit secrets
- ✅ Rotate token every 90 days for security
