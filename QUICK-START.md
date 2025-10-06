# Quick Start Guide - Salesforce CI/CD Fix

## 🚨 Problem Fixed
**Original Issue**: `sf: command not found` - The workflow was installing the wrong Salesforce CLI package.

## ✅ Solution Implemented
Updated the CLI installation from:
```yaml
npm install sfdx-cli@latest --global  # ❌ Old/deprecated
```
To:
```yaml
npm install @salesforce/cli --global   # ✅ Correct modern CLI
```

## 🎯 Quick Test Steps

### 1. Test Authentication (Recommended First Step)
```bash
# Go to GitHub Actions → Run workflow → "Test Salesforce Authentication"
```

### 2. Test Local Detection
```powershell
# In your project directory
.\scripts\test-detection-simple.ps1
```

### 3. Choose Your Deployment Strategy

#### Option A: Simple Deployment (Recommended for first test)
- Use: `.github/workflows/deploy-simple.yml`
- Deploys: Everything in force-app together
- Benefits: Less complex, easier to debug

#### Option B: Selective Deployment (Original goal)
- Use: `.github/workflows/deploy-to-salesforce.yml`
- Deploys: Only changed components individually
- Benefits: Faster, more targeted deployments

#### Option C: Robust Alternative (If issues persist)
- Use: `.github/workflows/deploy-to-salesforce-alt.yml`  
- Deploys: Selective with multiple CLI installation fallbacks
- Benefits: Most reliable installation method

## 🔑 Required GitHub Secrets
Make sure these are configured in your repository settings:

```
SF_JWT_KEY          - Your full JWT private key (including -----BEGIN/END-----)
SF_CONSUMER_KEY     - Connected App Consumer Key
SF_USERNAME         - Salesforce username (email)
SF_INSTANCE_URL     - https://login.salesforce.com (or your custom domain)
```

## 🧪 Testing Order
1. Run `Test Salesforce Authentication` workflow first
2. If authentication works, try `deploy-simple.yml`  
3. If simple deployment works, switch to selective deployment
4. Use detection test scripts to verify file detection locally

## 📊 Expected Results
Your test showed detection is working:
- ✅ 1 Apex class detected: `borrowerQualificationLogik.cls`
- ✅ 1 LWC component detected: `creditSenseDesitionPoint`

The deployment should now work with the fixed CLI installation!

## 🆘 If Still Having Issues
1. Check the authentication test workflow logs
2. Verify all GitHub secrets are properly set
3. Ensure your Connected App is configured for JWT Bearer Flow
4. Try the simple deployment workflow first

## 📝 Files Changed Summary
- **Fixed**: Original deployment workflow CLI installation
- **Added**: 4 new workflows for testing and alternatives
- **Added**: Local testing scripts for debugging
- **Added**: Comprehensive documentation