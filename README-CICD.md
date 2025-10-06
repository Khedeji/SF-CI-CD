# Salesforce CI/CD Pipeline with Selective Deployment

This repository contains an improved GitHub Actions workflow for selective Salesforce metadata deployment, which only deploys changed components instead of the entire `force-app` directory.

## 🚀 Key Improvements Made

### 1. **Robust File Detection**
The original issue was that the detection step wasn't finding changed files. The improved solution includes:

- **Multiple detection strategies** with fallback options
- **Better git diff commands** that work in various scenarios
- **Proper handling of empty results**
- **Debug output** to troubleshoot detection issues

### 2. **Fixed Detection Logic**
- Uses multiple strategies to detect changes:
  1. Compare with previous commit (`HEAD~1`)
  2. Compare with origin/main using merge-base
  3. Fallback to all files in force-app
- Handles edge cases like first commits and missing remote branches
- Provides detailed logging for troubleshooting

### 3. **Smart Component Grouping**
- **Apex**: Groups all Apex classes/triggers and deploys directories together
- **LWC**: Identifies individual components and deploys each component directory
- **Aura**: Identifies individual components and deploys each component directory  
- **Static Resources**: Handles both files and directories properly
- **Other Metadata**: Catches any other Salesforce metadata types

### 4. **Updated Salesforce CLI Commands**
- Updated from legacy `sfdx` commands to new `sf` CLI
- Proper authentication with `sf org login jwt`
- Better error handling and wait times

## 📁 Files Added/Modified

### Modified Files:
- `.github/workflows/deploy-to-salesforce.yml` - Main deployment workflow (improved)

### New Files:
- `.github/workflows/test-detection.yml` - Test workflow to verify detection logic
- `scripts/test-detection.sh` - Local testing script (Bash/Linux/Mac)
- `scripts/test-detection.ps1` - Local testing script (PowerShell/Windows)

## 🧪 Testing the Detection Logic

### Option 1: GitHub Actions Test Workflow
The `test-detection.yml` workflow runs on pushes and pull requests to test the detection logic without deploying:

```yaml
# Triggers on pushes to main, develop, feature branches and PRs
# Shows detailed detection output in GitHub Actions logs
```

### Option 2: Local Testing (Windows - PowerShell)
```powershell
# Navigate to your project directory
cd "c:\Users\Vikas.Khede\Desktop\SF training\SF CI CD"

# Run the PowerShell test script
.\scripts\test-detection.ps1
```

### Option 3: Local Testing (Linux/Mac - Bash)
```bash
# Navigate to your project directory
cd "/path/to/your/salesforce/project"

# Make script executable and run
chmod +x scripts/test-detection.sh
./scripts/test-detection.sh
```

## 🔧 How the Improved Detection Works

### Detection Strategies (in order):

1. **Strategy 1**: Compare with previous commit
   ```bash
   git diff --name-only HEAD~1 HEAD | grep "^force-app/"
   ```

2. **Strategy 2**: Compare with origin/main
   ```bash
   # With merge-base for better accuracy
   git diff --name-only $(git merge-base HEAD origin/main) HEAD | grep "^force-app/"
   ```

3. **Strategy 3**: Fallback to all force-app files
   ```bash
   git ls-tree -r --name-only HEAD | grep "^force-app/"
   ```

### Component Classification:

- **Apex Files**: `.cls` and `.trigger` files → Deploy by directory
- **LWC Components**: Files in `/lwc/componentName/` → Deploy each component
- **Aura Components**: Files in `/aura/componentName/` → Deploy each component  
- **Static Resources**: Files in `/staticresources/` → Deploy individual resources
- **Other Metadata**: Everything else → Deploy entire force-app

## 🚀 Deployment Logic

### Apex Classes & Triggers
```bash
# Groups all Apex directories and deploys together with tests
sf project deploy start --source-dir "force-app/main/default/classes" --target-org ci-org --test-level RunLocalTests --wait 10
```

### LWC Components
```bash
# Deploys each component individually
sf project deploy start --source-dir "force-app/main/default/lwc/myComponent" --target-org ci-org --test-level NoTestRun --wait 5
```

### Aura Components
```bash
# Deploys each component individually
sf project deploy start --source-dir "force-app/main/default/aura/myAuraComponent" --target-org ci-org --test-level NoTestRun --wait 5
```

### Static Resources
```bash
# Deploys individual static resources
sf project deploy start --source-dir "force-app/main/default/staticresources/myResource" --target-org ci-org --test-level NoTestRun --wait 5
```

## 🔒 Required GitHub Secrets

Make sure these secrets are configured in your GitHub repository:

- `SF_JWT_KEY` - Your Salesforce JWT private key
- `SF_CONSUMER_KEY` - Connected App Consumer Key
- `SF_USERNAME` - Salesforce username for the target org
- `SF_INSTANCE_URL` - Salesforce instance URL (e.g., https://login.salesforce.com)

## 🐛 Troubleshooting

### Issue: "No force-app files detected"

1. **Run the test script locally**:
   ```powershell
   .\scripts\test-detection.ps1
   ```

2. **Check the GitHub Actions logs** in the test workflow for detailed output

3. **Common causes**:
   - No actual changes in force-app directory
   - Git history issues (use Strategy 3 fallback)
   - Remote branch not properly set up

### Issue: "Deployment fails"

1. **Check Salesforce CLI version**:
   ```bash
   sf --version
   ```

2. **Verify authentication**:
   ```bash
   sf org list
   ```

3. **Test deployment manually**:
   ```bash
   sf project deploy start --source-dir "force-app/main/default/classes" --target-org your-org --dry-run
   ```

## 🎯 Benefits of This Approach

1. **Faster Deployments**: Only deploys what changed
2. **Reduced Risk**: Smaller deployment surface area
3. **Better Testing**: Targeted test execution
4. **Clear Logging**: Detailed output for troubleshooting
5. **Robust Detection**: Multiple fallback strategies
6. **Type-Aware**: Handles different metadata types appropriately

## 📈 Next Steps

1. **Test the detection** using the provided test scripts
2. **Verify the workflows** work with your actual changes
3. **Customize deployment strategies** if needed for your specific use case
4. **Add more metadata types** if you use additional Salesforce components

## 🤝 Contributing

Feel free to improve the detection logic or add support for additional metadata types by modifying the workflow files and test scripts.