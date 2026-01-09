#!/usr/bin/env bash

set -e

echo "🔍 Checking prerequisites..."

# Check required tools
declare -A tools=(
    ["terraform"]="https://www.terraform.io/downloads.html"
    ["kubectl"]="https://kubernetes.io/docs/tasks/tools/"
    ["aws"]="https://aws.amazon.com/cli/"
    ["helm"]="https://helm.sh/docs/intro/install/"
)

missing=0
for tool in "${!tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        version=$("$tool" version 2>&1 | head -n1)
        echo "✅ $tool: $version"
    else
        echo "❌ $tool not found. Install from: ${tools[$tool]}"
        missing=$((missing + 1))
    fi
done

# Check AWS credentials
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS credentials configured"
else
    echo "❌ AWS credentials not configured. Run 'aws configure'"
    missing=$((missing + 1))
fi

if [ $missing -eq 0 ]; then
    echo ""
    echo "🎉 All prerequisites met!"
    exit 0
else
    echo ""
    echo "❌ Missing $missing prerequisite(s)"
    exit 1
fi
