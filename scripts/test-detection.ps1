# Salesforce Metadata Detection Test Script (PowerShell)
# This script helps you test the metadata detection logic locally on Windows

Write-Host "TEST: Salesforce Metadata Detection Test" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check if we're in a git repository
try {
    git rev-parse --git-dir 2>$null | Out-Null
} catch {
    Write-Host "❌ Error: Not in a git repository" -ForegroundColor Red
    exit 1
}

# Check if force-app directory exists
if (!(Test-Path "force-app")) {
    Write-Host "❌ Error: force-app directory not found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "INFO: Repository Information:" -ForegroundColor Yellow
Write-Host "Current branch: $(git branch --show-current)"
Write-Host "Current commit: $(git rev-parse HEAD)"
Write-Host "Total commits: $(git rev-list --count HEAD)"

# Show remote branches
Write-Host ""
Write-Host "Remote branches:"
git branch -r

Write-Host ""
Write-Host "🔍 Testing Detection Strategies:" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow

# Strategy 1: Compare with previous commit
Write-Host ""
Write-Host "📋 Strategy 1: Comparing with previous commit (HEAD~1)..." -ForegroundColor Cyan
$commitCount = git rev-list --count HEAD
if ([int]$commitCount -gt 1) {
    $strategy1Files = git diff --name-only HEAD~1 HEAD | Where-Object { $_ -match "^force-app/" }
    if ($strategy1Files) {
        Write-Host "✅ Found $($strategy1Files.Count) files:" -ForegroundColor Green
        $strategy1Files | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "❌ No files found" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Only one commit exists, cannot compare with previous" -ForegroundColor Red
}

# Strategy 2: Compare with origin/main
Write-Host ""
Write-Host "📋 Strategy 2: Comparing with origin/main..." -ForegroundColor Cyan
try {
    git rev-parse --verify origin/main 2>$null | Out-Null
    $originMainExists = $true
} catch {
    $originMainExists = $false
}

if ($originMainExists) {
    try {
        $mergeBase = git merge-base HEAD origin/main 2>$null
        if ($mergeBase) {
            Write-Host "Using merge base: $mergeBase"
            $strategy2Files = git diff --name-only $mergeBase HEAD | Where-Object { $_ -match "^force-app/" }
        } else {
            Write-Host "No merge base found, using direct comparison"
            $strategy2Files = git diff --name-only origin/main HEAD | Where-Object { $_ -match "^force-app/" }
        }
    } catch {
        $strategy2Files = git diff --name-only origin/main HEAD | Where-Object { $_ -match "^force-app/" }
    }
    
    if ($strategy2Files) {
        Write-Host "✅ Found $($strategy2Files.Count) files:" -ForegroundColor Green
        $strategy2Files | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "❌ No files found" -ForegroundColor Red
    }
} else {
    Write-Host "❌ origin/main not found" -ForegroundColor Red
}

# Strategy 3: All files in force-app
Write-Host ""
Write-Host "📋 Strategy 3: All files in force-app (fallback)..." -ForegroundColor Cyan
$strategy3Files = git ls-tree -r --name-only HEAD | Where-Object { $_ -match "^force-app/" }
if ($strategy3Files) {
    Write-Host "✅ Found $($strategy3Files.Count) files in force-app" -ForegroundColor Green
    Write-Host "First 10 files:"
    $strategy3Files | Select-Object -First 10 | ForEach-Object { Write-Host $_ }
    if ($strategy3Files.Count -gt 10) {
        Write-Host "... and $($strategy3Files.Count - 10) more"
    }
} else {
    Write-Host "❌ No files found in force-app" -ForegroundColor Red
}

# Choose the best strategy result
$changedFiles = @()
if ($strategy1Files) {
    $changedFiles = $strategy1Files
    Write-Host ""
    Write-Host "Target: Using Strategy 1 results ($($strategy1Files.Count) files)" -ForegroundColor Green
} elseif ($strategy2Files) {
    $changedFiles = $strategy2Files
    Write-Host ""
    Write-Host "Target: Using Strategy 2 results ($($strategy2Files.Count) files)" -ForegroundColor Green
} elseif ($strategy3Files) {
    $changedFiles = $strategy3Files
    Write-Host ""
    Write-Host "Target: Using Strategy 3 results ($($strategy3Files.Count) files)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "ERROR: No files detected by any strategy!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔍 Analyzing Metadata Types:" -ForegroundColor Yellow
Write-Host "============================" -ForegroundColor Yellow

# Apex classes and triggers
$apexFiles = $changedFiles | Where-Object { $_ -match "\.(cls|trigger)$" }
if ($apexFiles) {
    Write-Host ""
    Write-Host "📋 Apex Classes/Triggers ($($apexFiles.Count)):" -ForegroundColor Cyan
    $apexFiles | ForEach-Object { Write-Host $_ }
    
    # Get unique directories
    $apexDirs = $apexFiles | ForEach-Object { Split-Path $_ -Parent } | Sort-Object -Unique
    Write-Host "📁 Apex Directories:"
    $apexDirs | ForEach-Object { Write-Host $_ }
} else {
    Write-Host ""
    Write-Host "📋 No Apex files found" -ForegroundColor Gray
}

# LWC components
$lwcFiles = $changedFiles | Where-Object { $_ -match "/lwc/" }
if ($lwcFiles) {
    $lwcComponents = $lwcFiles | ForEach-Object { 
        if ($_ -match "force-app/main/default/lwc/([^/]+)/") {
            $matches[1]
        }
    } | Sort-Object -Unique
    
    Write-Host ""
    Write-Host "⚡ LWC Components ($($lwcComponents.Count)):" -ForegroundColor Cyan
    $lwcComponents | ForEach-Object { Write-Host $_ }
    
    Write-Host "📂 LWC Files:"
    $lwcFiles | ForEach-Object { Write-Host $_ }
} else {
    Write-Host ""
    Write-Host "⚡ No LWC components found" -ForegroundColor Gray
}

# Aura components
$auraFiles = $changedFiles | Where-Object { $_ -match "/aura/" }
if ($auraFiles) {
    $auraComponents = $auraFiles | ForEach-Object { 
        if ($_ -match "force-app/main/default/aura/([^/]+)/") {
            $matches[1]
        }
    } | Sort-Object -Unique
    
    Write-Host ""
    Write-Host "🔥 Aura Components ($($auraComponents.Count)):" -ForegroundColor Cyan
    $auraComponents | ForEach-Object { Write-Host $_ }
    
    Write-Host "📂 Aura Files:"
    $auraFiles | ForEach-Object { Write-Host $_ }
} else {
    Write-Host ""
    Write-Host "🔥 No Aura components found" -ForegroundColor Gray
}

# Static Resources
$staticFiles = $changedFiles | Where-Object { $_ -match "/staticresources/" }
if ($staticFiles) {
    $staticResources = $staticFiles | ForEach-Object { 
        if ($_ -match "force-app/main/default/staticresources/([^/]+)") {
            $matches[1]
        }
    } | Sort-Object -Unique
    
    Write-Host ""
    Write-Host "📁 Static Resources ($($staticResources.Count)):" -ForegroundColor Cyan
    $staticResources | ForEach-Object { Write-Host $_ }
    
    Write-Host "📂 Static Resource Files:"
    $staticFiles | ForEach-Object { Write-Host $_ }
} else {
    Write-Host ""
    Write-Host "📁 No Static Resources found" -ForegroundColor Gray
}

# Other metadata
$otherMetadata = $changedFiles | Where-Object { $_ -notmatch "/(classes|lwc|aura|staticresources)/" -and $_ -match "^force-app/" }
if ($otherMetadata) {
    Write-Host ""
    Write-Host "🔧 Other Metadata ($($otherMetadata.Count)):" -ForegroundColor Cyan
    $otherMetadata | ForEach-Object { Write-Host $_ }
} else {
    Write-Host ""
    Write-Host "🔧 No other metadata found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📊 Final Summary:" -ForegroundColor Yellow
Write-Host "=================" -ForegroundColor Yellow
Write-Host "- Total files detected: $($changedFiles.Count)"
Write-Host "- Apex files: $($apexFiles.Count)"
Write-Host "- LWC components: $(if($lwcComponents) { $lwcComponents.Count } else { 0 })"
Write-Host "- Aura components: $(if($auraComponents) { $auraComponents.Count } else { 0 })"
Write-Host "- Static resources: $(if($staticResources) { $staticResources.Count } else { 0 })"
Write-Host "- Other metadata: $($otherMetadata.Count)"

Write-Host ""
Write-Host "✅ Detection test complete!" -ForegroundColor Green

# Optional: Show what would be deployed
Write-Host ""
Write-Host "🚀 Deployment Commands that would be executed:" -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor Yellow

if ($apexDirs) {
    Write-Host ""
    Write-Host "📋 Apex deployment:" -ForegroundColor Cyan
    $deployDirs = $apexDirs -join " "
    Write-Host "sf project deploy start --source-dir $deployDirs --target-org ci-org --test-level RunLocalTests --wait 10"
}

if ($lwcComponents) {
    Write-Host ""
    Write-Host "⚡ LWC deployments:" -ForegroundColor Cyan
    $lwcComponents | ForEach-Object {
        Write-Host "sf project deploy start --source-dir `"force-app/main/default/lwc/$_`" --target-org ci-org --test-level NoTestRun --wait 5"
    }
}

if ($auraComponents) {
    Write-Host ""
    Write-Host "🔥 Aura deployments:" -ForegroundColor Cyan
    $auraComponents | ForEach-Object {
        Write-Host "sf project deploy start --source-dir `"force-app/main/default/aura/$_`" --target-org ci-org --test-level NoTestRun --wait 5"
    }
}

if ($staticResources) {
    Write-Host ""
    Write-Host "📁 Static Resource deployments:" -ForegroundColor Cyan
    $staticResources | ForEach-Object {
        Write-Host "sf project deploy start --source-dir `"force-app/main/default/staticresources/$_`" --target-org ci-org --test-level NoTestRun --wait 5"
    }
}

if ($otherMetadata) {
    Write-Host ""
    Write-Host "🔧 Other metadata deployment:" -ForegroundColor Cyan
    Write-Host "sf project deploy start --source-dir `"force-app/main/default`" --target-org ci-org --test-level RunLocalTests --wait 10"
}