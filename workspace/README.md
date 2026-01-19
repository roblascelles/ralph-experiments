# OpenSearch Index Re-indexing Worker

An AWS serverless application that re-indexes OpenSearch indices sequentially based on JSON configuration files uploaded to S3.

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- AWS CLI installed (for awslocal alias)

### Setup Development Environment

1. **Start Docker containers:**
   ```bash
   ./setup-dev-env.sh
   ```
   
   Or manually:
   ```bash
   docker compose up -d
   sleep 40  # Wait for services to initialize
   ```

2. **Verify services are running:**
   ```bash
   # Check LocalStack
   docker exec opensearch-reindex-localstack curl -s http://localhost:4566/_localstack/health
   
   # Check OpenSearch
   docker exec opensearch-reindex-opensearch curl -s http://localhost:9200/_cluster/health?pretty
   ```

3. **Set up awslocal alias (optional but recommended):**
   ```bash
   echo 'alias awslocal="aws --endpoint-url=http://localhost:4566"' >> ~/.bashrc
   source ~/.bashrc
   ```

## Architecture

### Stack
- **AWS Services**: S3, EventBridge, Step Functions, Lambda (via LocalStack for local dev)
- **OpenSearch**: 2.11.0 (local Docker container)
- **Infrastructure**: Terraform
- **Lambda Runtime**: Python 3.11+
- **Testing**: pytest with TDD approach

### Workflow
1. User uploads JSON config to S3
2. EventBridge detects S3 object creation
3. Step Function orchestrates sequential re-indexing
4. For each index:
   - Create new index with updated version
   - Update aliases (new=write, old=read-only)
   - Start async reindex
   - Poll for completion
   - Remove old alias
   - Delete old index

## Development Status

✅ **Phase 0: Docker Environment** - Complete
- LocalStack running with S3, Lambda, Step Functions, EventBridge, IAM, Logs
- OpenSearch 2.11 running and healthy
- Services verified and documented

🔄 **Phase 1: Project Setup** - Next
- Directory structure
- Python dependencies
- Test configuration
- Example files

⏳ **Phase 2: Python Core Logic** - Pending

⏳ **Phase 3: Terraform Infrastructure** - Pending

⏳ **Phase 4: Integration & Testing** - Pending

⏳ **Phase 5: Documentation & Cleanup** - Pending

See [TODO.md](TODO.md) for detailed task list.

## Docker Services

### LocalStack
- **Endpoint**: http://localhost:4566 (from container)
- **Services**: S3, Lambda, Step Functions, EventBridge, IAM, CloudWatch Logs
- **Version**: Latest community edition
- **Data**: Persisted in Docker volume `localstack-data`

### OpenSearch
- **Endpoint**: http://localhost:9200 (from container)
- **Version**: 2.11.0
- **Security**: Disabled for local development
- **Data**: Persisted in Docker volume `opensearch-data`

## Useful Commands

### Docker Management
```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker logs opensearch-reindex-localstack
docker logs opensearch-reindex-opensearch

# Clean up everything (including volumes)
docker compose down -v
```

### LocalStack Testing
```bash
# Health check
docker exec opensearch-reindex-localstack curl http://localhost:4566/_localstack/health

# List S3 buckets (after deploying infrastructure)
aws --endpoint-url=http://localhost:4566 s3 ls

# Or with awslocal alias:
awslocal s3 ls
```

### OpenSearch Testing
```bash
# Cluster health
docker exec opensearch-reindex-opensearch curl http://localhost:9200/_cluster/health?pretty

# List indices
docker exec opensearch-reindex-opensearch curl http://localhost:9200/_cat/indices?v

# Create test index
docker exec opensearch-reindex-opensearch curl -X PUT http://localhost:9200/test_v1 \
  -H 'Content-Type: application/json' \
  -d '{"settings":{"number_of_shards":1},"mappings":{"properties":{"name":{"type":"text"}}}}'
```

## Project Structure

```
.
├── docker-compose.yml          # LocalStack + OpenSearch containers
├── setup-dev-env.sh           # Environment setup script
├── src/                       # Python Lambda code (TODO)
├── tests/                     # Unit and integration tests (TODO)
├── terraform/                 # Infrastructure as code (TODO)
├── examples/                  # Sample JSON configs (TODO)
├── SPECS.md                   # Technical specifications
├── TODO.md                    # Task tracking
├── AGENTS.md                  # Operational notes and gotchas
└── README.md                  # This file
```

## Troubleshooting

See [AGENTS.md](AGENTS.md) for known issues and solutions, including:
- Docker permission issues
- Volume mount problems
- Service startup timing
- Port access from host
- OpenSearch race conditions

## Next Steps

1. Complete Phase 1: Project Setup (directories, dependencies, configs)
2. Implement Phase 2: Python code using TDD
3. Build Phase 3: Terraform infrastructure
4. Execute Phase 4: Integration testing
5. Finalize Phase 5: Documentation

## License

MIT
