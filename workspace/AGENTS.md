# Operational Guide

---
*This file gets updated when Ralph discovers better ways to build/test/run the project.*

## Known Issues & Gotchas

### Docker Permission Issues
- **Issue**: On some systems, Docker requires sudo to run
- **Solution**: Commands in this guide may need `sudo` prefix (e.g., `sudo docker compose up -d`)
- **Better Fix**: Add your user to the docker group and restart your session

### LocalStack Volume Mount Issues
- **Issue**: Bind mounts (e.g., `./localstack:/var/lib/localstack`) can fail on Docker Desktop
- **Error**: "mounts denied: The path /home/user/workspace/localstack is not shared from the host"
- **Solution**: Use named volumes instead: `localstack-data:/var/lib/localstack`
- **Applied**: docker-compose.yml uses named volumes for both LocalStack and OpenSearch

### Service Startup Timing
- **Issue**: Services need time to fully initialize
- **LocalStack**: Takes ~20-30 seconds to become "Ready"
- **OpenSearch**: Takes ~30-40 seconds to reach GREEN status
- **Solution**: Add `sleep 30-40` after `docker compose up -d` before testing

### Port Access from Host
- **Issue**: Ports (4566, 9200) may not be immediately accessible from host machine
- **Workaround**: Use `docker exec` to run commands inside containers
- **Example**: `sudo docker exec opensearch-reindex-localstack curl http://localhost:4566/_localstack/health`

### OpenSearch Index Creation Race Condition
- **Issue**: Newly created index may return 404 immediately after creation
- **Reason**: Eventual consistency - index needs a moment to be fully available
- **Solution**: Add small delay (1-2 seconds) after index creation before querying

## Development Strategy

### LocalStack-First Development
Develop and test the entire infrastructure locally before deploying to AWS:

1. **LocalStack in Docker** - Run AWS services locally (S3, Lambda, Step Functions, EventBridge)
2. **Terraform Configuration** - Use same Terraform code for both local and production
3. **Provider Switching** - Toggle between LocalStack and AWS with environment variables
4. **OpenSearch Local** - Run OpenSearch 2.x in Docker for end-to-end testing

### TDD Workflow
```
Create failing integration test → Develop → Passing integration test
```

## LocalStack Setup

### Services Required
- **S3** - Trigger bucket
- **Lambda** - Handler functions
- **Step Functions** - Workflow orchestration
- **EventBridge** - S3 event detection
- **CloudWatch Logs** - Function logging
- **IAM** - Roles and policies

### Endpoints
All services accessible at: `http://localhost:4566`

### Docker Compose Configuration
```yaml
services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,lambda,stepfunctions,events,iam,logs
      - DEBUG=1
    volumes:
      - "./localstack:/var/lib/localstack"
      - "/var/run/docker.sock:/var/run/docker.sock"

  opensearch:
    image: opensearchproject/opensearch:2.11.0
    environment:
      - discovery.type=single-node
      - plugins.security.disabled=true
    ports:
      - "9200:9200"
```

## Terraform Provider Configuration

### Local Development
```hcl
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3             = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    eventbridge    = "http://localhost:4566"
    iam            = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
  }
}
```

### Production
Remove `endpoints` block and credential skip flags. Use AWS credentials from environment or profile.

### Environment Detection
```hcl
locals {
  is_local = var.environment == "local"
  
  # Conditional endpoint configuration
  s3_endpoint = local.is_local ? "http://localhost:4566" : null
}
```

## Local Development Workflow

### 1. Start Environment
```bash
docker compose up -d
```

Verify services:
```bash
# LocalStack health check
curl http://localhost:4566/_localstack/health

# OpenSearch health check
curl http://localhost:9200/_cluster/health
```

### 2. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan -var-file=environments/local.tfvars
terraform apply -var-file=environments/local.tfvars
```

### 3. Run Tests
```bash
# Unit tests
pytest tests/ -v --cov=src --cov-report=html

# Integration tests (requires LocalStack)
pytest tests/integration/ -v
```

### 4. Test End-to-End
```bash
# Create test indices in local OpenSearch
curl -X PUT "http://localhost:9200/products_v1" -H 'Content-Type: application/json' -d'
{
  "settings": {"number_of_shards": 1},
  "mappings": {"properties": {"name": {"type": "text"}}}
}'

# Upload trigger JSON to LocalStack S3
awslocal s3 cp examples/reindex-config.json s3://opensearch-reindex-triggers/test-config.json

# Monitor Step Function execution
awslocal stepfunctions list-executions --state-machine-arn <arn-from-terraform-output>

# Check execution details
awslocal stepfunctions describe-execution --execution-arn <execution-arn>

# View Lambda logs
awslocal logs tail /aws/lambda/reindex-create-index --follow
```

### 5. Teardown
```bash
# Destroy infrastructure
cd terraform
terraform destroy -var-file=environments/local.tfvars

# Stop Docker
docker compose down
```

## AWS CLI for LocalStack

### Setup awslocal Alias
```bash
# Add to ~/.bashrc or ~/.zshrc
alias awslocal="aws --endpoint-url=http://localhost:4566"
```

### Common Commands
```bash
# List S3 buckets
awslocal s3 ls

# List Lambda functions
awslocal lambda list-functions

# List Step Functions
awslocal stepfunctions list-state-machines

# View logs
awslocal logs tail /aws/lambda/function-name --follow
```

## Testing Strategy

### Unit Tests (pytest + moto)
- **Location**: `tests/test_*.py`
- **Mocking**: Use `moto` for AWS services, `pytest-mock` for OpenSearch
- **Coverage**: Target 80%+ code coverage
- **Run**: `pytest tests/ -v --cov=src`

#### Example Test Structure
```python
import pytest
from moto import mock_s3
from src.handlers import get_trigger_file_handler

@mock_s3
def test_get_trigger_file_handler():
    # Setup mock S3
    # Call handler
    # Assert result
```

### Integration Tests (LocalStack)
- **Location**: `tests/integration/`
- **Prerequisites**: LocalStack running
- **Scope**: Test Lambda-AWS service interactions
- **Run**: `pytest tests/integration/ -v`

### End-to-End Tests
1. Deploy infrastructure to LocalStack
2. Create test indices in local OpenSearch
3. Upload JSON trigger file
4. Verify Step Function execution
5. Validate OpenSearch state changes

## Makefile Targets

```makefile
.PHONY: setup-local deploy-local test test-integration deploy-prod clean

setup-local:
	docker compose up -d
	sleep 5  # Wait for services

deploy-local:
	cd terraform && terraform apply -var-file=environments/local.tfvars -auto-approve

test:
	pytest tests/ -v --cov=src --cov-report=html

test-integration:
	pytest tests/integration/ -v

deploy-prod:
	cd terraform && terraform apply -var-file=environments/prod.tfvars

clean:
	docker compose down -v
	rm -rf localstack/
	cd terraform && terraform destroy -var-file=environments/local.tfvars -auto-approve
```

## Debugging Tips

### Lambda Issues
```bash
# Check function exists
awslocal lambda list-functions | grep reindex

# Test invoke
awslocal lambda invoke --function-name reindex-create-index \
  --payload '{"index_name": "test"}' \
  output.json

# View logs
awslocal logs tail /aws/lambda/reindex-create-index --follow
```

### Step Functions Issues
```bash
# List executions
awslocal stepfunctions list-executions --state-machine-arn <arn>

# Get execution details (includes error messages)
awslocal stepfunctions describe-execution --execution-arn <arn>

# Get execution history
awslocal stepfunctions get-execution-history --execution-arn <arn>
```

### OpenSearch Issues
```bash
# Check cluster health
curl http://localhost:9200/_cluster/health?pretty

# List indices
curl http://localhost:9200/_cat/indices?v

# Check aliases
curl http://localhost:9200/_cat/aliases?v

# Check task status
curl http://localhost:9200/_tasks/<task_id>
```

### S3 Event Issues
```bash
# Check EventBridge rules
awslocal events list-rules

# Check S3 notification configuration
awslocal s3api get-bucket-notification-configuration --bucket opensearch-reindex-triggers
```

## Production Deployment

### Prerequisites
- AWS credentials configured
- S3 backend for Terraform state (recommended)
- OpenSearch domain endpoint available

### Steps
```bash
# Review plan
cd terraform
terraform plan -var-file=environments/prod.tfvars

# Apply
terraform apply -var-file=environments/prod.tfvars

# Test with sample config
aws s3 cp examples/reindex-config.json s3://<bucket-name>/test-config.json

# Monitor
aws stepfunctions list-executions --state-machine-arn <arn>
```

## Troubleshooting

### LocalStack Not Starting
- Check Docker is running
- Check port 4566 is not in use: `lsof -i :4566`
- Check logs: `docker compose logs localstack`

### Terraform Apply Fails (LocalStack)
- Verify LocalStack is healthy
- Check endpoint configuration in provider
- Ensure skip flags are set correctly

### Lambda Deployment Issues
- Verify ZIP file created: `ls -lh terraform/lambda_package.zip`
- Check Lambda exists: `awslocal lambda list-functions`
- Test invoke directly before Step Functions

### No S3 Events Triggering
- Verify EventBridge enabled on bucket
- Check EventBridge rule created
- Manually test Step Function execution first
