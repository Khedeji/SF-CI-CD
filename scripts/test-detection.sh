#!/bin/bash

# Salesforce Metadata Detection Test Script
# This script helps you test the metadata detection logic locally

echo "🧪 Salesforce Metadata Detection Test"
echo "===================================="

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check if force-app directory exists
if [ ! -d "force-app" ]; then
    echo "❌ Error: force-app directory not found"
    exit 1
fi

echo ""
echo "📋 Repository Information:"
echo "Current branch: $(git branch --show-current)"
echo "Current commit: $(git rev-parse HEAD)"
echo "Total commits: $(git rev-list --count HEAD)"

# Show remote branches
echo ""
echo "Remote branches:"
git branch -r

echo ""
echo "🔍 Testing Detection Strategies:"
echo "================================"

# Strategy 1: Compare with previous commit
echo ""
echo "📋 Strategy 1: Comparing with previous commit (HEAD~1)..."
if [ $(git rev-list --count HEAD) -gt 1 ]; then
    STRATEGY1_FILES=$(git diff --name-only HEAD~1 HEAD | grep "^force-app/" || true)
    if [ -n "$STRATEGY1_FILES" ]; then
        echo "✅ Found $(echo "$STRATEGY1_FILES" | wc -l) files:"
        echo "$STRATEGY1_FILES"
    else
        echo "❌ No files found"
    fi
else
    echo "❌ Only one commit exists, cannot compare with previous"
fi

# Strategy 2: Compare with origin/main
echo ""
echo "📋 Strategy 2: Comparing with origin/main..."
if git rev-parse --verify origin/main >/dev/null 2>&1; then
    MERGE_BASE=$(git merge-base HEAD origin/main 2>/dev/null || echo "")
    if [ -n "$MERGE_BASE" ]; then
        echo "Using merge base: $MERGE_BASE"
        STRATEGY2_FILES=$(git diff --name-only $MERGE_BASE HEAD | grep "^force-app/" || true)
    else
        echo "No merge base found, using direct comparison"
        STRATEGY2_FILES=$(git diff --name-only origin/main HEAD | grep "^force-app/" || true)
    fi
    
    if [ -n "$STRATEGY2_FILES" ]; then
        echo "✅ Found $(echo "$STRATEGY2_FILES" | wc -l) files:"
        echo "$STRATEGY2_FILES"
    else
        echo "❌ No files found"
    fi
else
    echo "❌ origin/main not found"
fi

# Strategy 3: All files in force-app
echo ""
echo "📋 Strategy 3: All files in force-app (fallback)..."
STRATEGY3_FILES=$(git ls-tree -r --name-only HEAD | grep "^force-app/" || true)
if [ -n "$STRATEGY3_FILES" ]; then
    echo "✅ Found $(echo "$STRATEGY3_FILES" | wc -l) files in force-app"
    echo "First 10 files:"
    echo "$STRATEGY3_FILES" | head -10
    if [ $(echo "$STRATEGY3_FILES" | wc -l) -gt 10 ]; then
        echo "... and $(echo "$STRATEGY3_FILES" | wc -l | awk '{print $1-10}') more"
    fi
else
    echo "❌ No files found in force-app"
fi

# Choose the best strategy result
CHANGED_FILES=""
if [ -n "$STRATEGY1_FILES" ]; then
    CHANGED_FILES="$STRATEGY1_FILES"
    echo ""
    echo "🎯 Using Strategy 1 results ($(echo "$STRATEGY1_FILES" | wc -l) files)"
elif [ -n "$STRATEGY2_FILES" ]; then
    CHANGED_FILES="$STRATEGY2_FILES"
    echo ""
    echo "🎯 Using Strategy 2 results ($(echo "$STRATEGY2_FILES" | wc -l) files)"
elif [ -n "$STRATEGY3_FILES" ]; then
    CHANGED_FILES="$STRATEGY3_FILES"
    echo ""
    echo "🎯 Using Strategy 3 results ($(echo "$STRATEGY3_FILES" | wc -l) files)"
else
    echo ""
    echo "❌ No files detected by any strategy!"
    exit 1
fi

echo ""
echo "🔍 Analyzing Metadata Types:"
echo "============================"

# Apex classes and triggers
APEX_FILES=$(echo "$CHANGED_FILES" | grep -E "\.(cls|trigger)$" || true)
if [ -n "$APEX_FILES" ]; then
    echo ""
    echo "📋 Apex Classes/Triggers ($(echo "$APEX_FILES" | wc -l)):"
    echo "$APEX_FILES"
    
    # Get unique directories
    APEX_DIRS=$(echo "$APEX_FILES" | sed 's|/[^/]*$||' | sort -u || true)
    echo "📁 Apex Directories:"
    echo "$APEX_DIRS"
else
    echo ""
    echo "📋 No Apex files found"
fi

# LWC components
LWC_COMPONENTS=""
if echo "$CHANGED_FILES" | grep -q "/lwc/"; then
    LWC_COMPONENTS=$(echo "$CHANGED_FILES" | grep "/lwc/" | sed -n 's|.*force-app/main/default/lwc/\([^/]*\)/.*|\1|p' | sort -u || true)
    echo ""
    echo "⚡ LWC Components ($(echo "$LWC_COMPONENTS" | wc -l)):"
    echo "$LWC_COMPONENTS"
    
    echo "📂 LWC Files:"
    echo "$CHANGED_FILES" | grep "/lwc/"
else
    echo ""
    echo "⚡ No LWC components found"
fi

# Aura components
AURA_COMPONENTS=""
if echo "$CHANGED_FILES" | grep -q "/aura/"; then
    AURA_COMPONENTS=$(echo "$CHANGED_FILES" | grep "/aura/" | sed -n 's|.*force-app/main/default/aura/\([^/]*\)/.*|\1|p' | sort -u || true)
    echo ""
    echo "🔥 Aura Components ($(echo "$AURA_COMPONENTS" | wc -l)):"
    echo "$AURA_COMPONENTS"
    
    echo "📂 Aura Files:"
    echo "$CHANGED_FILES" | grep "/aura/"
else
    echo ""
    echo "🔥 No Aura components found"
fi

# Static Resources
STATIC_RESOURCES=""
if echo "$CHANGED_FILES" | grep -q "/staticresources/"; then
    STATIC_RESOURCES=$(echo "$CHANGED_FILES" | grep "/staticresources/" | sed -n 's|.*force-app/main/default/staticresources/\([^/]*\).*|\1|p' | sort -u || true)
    echo ""
    echo "📁 Static Resources ($(echo "$STATIC_RESOURCES" | wc -l)):"
    echo "$STATIC_RESOURCES"
    
    echo "📂 Static Resource Files:"
    echo "$CHANGED_FILES" | grep "/staticresources/"
else
    echo ""
    echo "📁 No Static Resources found"
fi

# Other metadata
OTHER_METADATA=$(echo "$CHANGED_FILES" | grep -v -E "/(classes|lwc|aura|staticresources)/" | grep "^force-app/" || true)
if [ -n "$OTHER_METADATA" ]; then
    echo ""
    echo "🔧 Other Metadata ($(echo "$OTHER_METADATA" | wc -l)):"
    echo "$OTHER_METADATA"
else
    echo ""
    echo "🔧 No other metadata found"
fi

echo ""
echo "📊 Final Summary:"
echo "================"
echo "- Total files detected: $(echo "$CHANGED_FILES" | wc -l)"
echo "- Apex files: $(echo "$APEX_FILES" | wc -l)"
echo "- LWC components: $(echo "$LWC_COMPONENTS" | wc -l)"
echo "- Aura components: $(echo "$AURA_COMPONENTS" | wc -l)"
echo "- Static resources: $(echo "$STATIC_RESOURCES" | wc -l)"
echo "- Other metadata: $(echo "$OTHER_METADATA" | wc -l)"

echo ""
echo "✅ Detection test complete!"

# Optional: Show what would be deployed
echo ""
echo "🚀 Deployment Commands that would be executed:"
echo "=============================================="

if [ -n "$APEX_DIRS" ]; then
    echo ""
    echo "📋 Apex deployment:"
    DEPLOY_DIRS=$(echo "$APEX_DIRS" | tr '\n' ' ')
    echo "sf project deploy start --source-dir $DEPLOY_DIRS --target-org ci-org --test-level RunLocalTests --wait 10"
fi

if [ -n "$LWC_COMPONENTS" ]; then
    echo ""
    echo "⚡ LWC deployments:"
    echo "$LWC_COMPONENTS" | while read -r component; do
        if [ -n "$component" ]; then
            echo "sf project deploy start --source-dir \"force-app/main/default/lwc/$component\" --target-org ci-org --test-level NoTestRun --wait 5"
        fi
    done
fi

if [ -n "$AURA_COMPONENTS" ]; then
    echo ""
    echo "🔥 Aura deployments:"
    echo "$AURA_COMPONENTS" | while read -r component; do
        if [ -n "$component" ]; then
            echo "sf project deploy start --source-dir \"force-app/main/default/aura/$component\" --target-org ci-org --test-level NoTestRun --wait 5"
        fi
    done
fi

if [ -n "$STATIC_RESOURCES" ]; then
    echo ""
    echo "📁 Static Resource deployments:"
    echo "$STATIC_RESOURCES" | while read -r resource; do
        if [ -n "$resource" ]; then
            echo "sf project deploy start --source-dir \"force-app/main/default/staticresources/$resource\" --target-org ci-org --test-level NoTestRun --wait 5"
        fi
    done
fi

if [ -n "$OTHER_METADATA" ]; then
    echo ""
    echo "🔧 Other metadata deployment:"
    echo "sf project deploy start --source-dir \"force-app/main/default\" --target-org ci-org --test-level RunLocalTests --wait 10"
fi