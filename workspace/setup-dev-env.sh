#!/bin/bash

# Setup script for OpenSearch Reindex Worker development environment
# This script helps configure awslocal alias and verify the environment

set -e

echo "=== OpenSearch Reindex Worker - Environment Setup ==="
echo ""

# Check if running with sudo
if [ "$EUID" -eq 0 ]; then 
    echo "WARNING: Running as root. Consider running as regular user instead."
fi

# Check Docker availability
echo "1. Checking Docker..."
if command -v docker &> /dev/null; then
    echo "   ✓ Docker found: $(docker --version)"
else
    echo "   ✗ Docker not found. Please install Docker first."
    exit 1
fi

# Setup awslocal alias
echo ""
echo "2. Setting up awslocal alias..."
SHELL_RC=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "alias awslocal=" "$SHELL_RC" 2>/dev/null; then
        echo 'alias awslocal="aws --endpoint-url=http://localhost:4566"' >> "$SHELL_RC"
        echo "   ✓ awslocal alias added to $SHELL_RC"
        echo "   Run: source $SHELL_RC (or restart terminal)"
    else
        echo "   ✓ awslocal alias already exists in $SHELL_RC"
    fi
else
    echo "   ! Could not detect shell config file"
    echo "   Manually add this to your shell config:"
    echo '   alias awslocal="aws --endpoint-url=http://localhost:4566"'
fi

# Create temporary alias for this session
shopt -s expand_aliases
alias awslocal="aws --endpoint-url=http://localhost:4566"

echo ""
echo "3. Checking Docker Compose file..."
if [ -f "docker-compose.yml" ]; then
    echo "   ✓ docker-compose.yml found"
else
    echo "   ✗ docker-compose.yml not found in current directory"
    exit 1
fi

echo ""
echo "4. Starting Docker containers..."
if docker compose ps | grep -q "opensearch-reindex"; then
    echo "   ! Containers already running"
else
    docker compose up -d
    echo "   ✓ Containers starting..."
    echo "   Waiting 40 seconds for services to initialize..."
    sleep 40
fi

echo ""
echo "5. Verifying LocalStack..."
if docker exec opensearch-reindex-localstack curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
    echo "   ✓ LocalStack is healthy"
    echo "   Available services:"
    docker exec opensearch-reindex-localstack curl -s http://localhost:4566/_localstack/health | \
        python3 -c "import sys, json; data=json.load(sys.stdin); [print(f'     - {k}: {v}') for k,v in data['services'].items() if v=='available']" 2>/dev/null || \
        echo "     (Run 'docker exec opensearch-reindex-localstack curl -s http://localhost:4566/_localstack/health' to check manually)"
else
    echo "   ✗ LocalStack not responding"
    echo "   Check logs: docker logs opensearch-reindex-localstack"
fi

echo ""
echo "6. Verifying OpenSearch..."
if docker exec opensearch-reindex-opensearch curl -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    HEALTH_STATUS=$(docker exec opensearch-reindex-opensearch curl -s http://localhost:9200/_cluster/health | python3 -c "import sys, json; print(json.load(sys.stdin)['status'])" 2>/dev/null || echo "unknown")
    echo "   ✓ OpenSearch is running (status: $HEALTH_STATUS)"
else
    echo "   ✗ OpenSearch not responding"
    echo "   Check logs: docker logs opensearch-reindex-opensearch"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Run 'source $SHELL_RC' to activate awslocal alias (or restart terminal)"
echo "  2. Test LocalStack: aws --endpoint-url=http://localhost:4566 s3 ls"
echo "  3. Test OpenSearch: docker exec opensearch-reindex-opensearch curl http://localhost:9200"
echo "  4. Continue with project setup (see TODO.md)"
echo ""
