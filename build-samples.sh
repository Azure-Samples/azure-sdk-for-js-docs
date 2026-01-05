#!/bin/bash

# Build All Samples Script
# This script mimics the GitHub Action locally for testing

set -e

echo "🔍 Discovering samples..."

# Find all sample directories with package.json, excluding node_modules
mapfile -t samples < <(find samples -name "package.json" -not -path "*/node_modules/*" -type f | sed 's|/package.json||')

if [ ${#samples[@]} -eq 0 ]; then
    echo "❌ No samples found!"
    exit 1
fi

echo "📋 Found ${#samples[@]} samples:"
printf '  - %s\n' "${samples[@]}"
echo ""

# Install root dependencies
echo "📦 Installing root dependencies..."
npm ci

# Track results
declare -A results
total_samples=${#samples[@]}
successful=0
failed=0

echo "🔨 Building samples..."
echo ""

# Build each sample
for sample in "${samples[@]}"; do
    echo "🚀 Building: $sample"
    echo "----------------------------------------"
    
    pushd "$sample" > /dev/null
    
    # Build the sample
    if npm ci && {
        if npm run | grep -q "build"; then
            echo "  📝 Running npm run build"
            npm run build
        elif [ -f "tsconfig.json" ]; then
            echo "  🔧 Running TypeScript compiler"
            npx tsc --noEmit
        else
            echo "  🔍 Checking TypeScript syntax"
            if find . -name "*.ts" -not -path "./node_modules/*" | head -1 | grep -q .; then
                find . -name "*.ts" -not -path "./node_modules/*" -print0 | xargs -0 npx tsc --noEmit --skipLibCheck
            else
                echo "  ℹ️ No TypeScript files found"
            fi
        fi
    }; then
        echo "  ✅ SUCCESS"
        results["$sample"]="success"
        ((successful++))
    else
        echo "  ❌ FAILED"
        results["$sample"]="failed"
        ((failed++))
    fi
    
    popd > /dev/null
    echo ""
done

# Print summary
echo "========================================"
echo "📊 BUILD SUMMARY"
echo "========================================"
echo "Total samples: $total_samples"
echo "Successful: ✅ $successful"
echo "Failed: ❌ $failed"
echo ""

echo "📝 Detailed Results:"
for sample in "${samples[@]}"; do
    status="${results[$sample]}"
    if [ "$status" = "success" ]; then
        echo "  ✅ $sample"
    else
        echo "  ❌ $sample"
    fi
done

echo ""
if [ $failed -gt 0 ]; then
    echo "⚠️ Some builds failed!"
    exit 1
else
    echo "🎉 All builds successful!"
    exit 0
fi