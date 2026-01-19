# OpenSearch Index Re-indexing Worker

## Overview
An AWS serverless application that re-indexes OpenSearch indices sequentially based on JSON configuration files uploaded to S3. When triggered, it orchestrates the workflow using Step Functions and Lambda to process indices with proper alias management and async re-indexing.

**Stack**: S3, EventBridge, Step Functions, Lambda, Python 3.11+, Terraform, TDD with pytest 

## How It Works

### Trigger Flow
1. User uploads JSON file to S3 bucket
2. EventBridge detects S3 object creation
3. EventBridge triggers Step Function execution
4. Step Function processes each index sequentially

### Per-Index Workflow (Sequential)
1. **Create New Index** - Generate new index based on regex pattern/replacement from config
2. **Update Aliases** - Add alias to new index (write=true), update old index alias (write=false)
3. **Start Reindex** - Call OpenSearch `_reindex` API in async mode
4. **Poll for Completion** - Wait 30s + check task status (loop until done)
5. **Remove Old Alias** - Remove alias from old index
6. **Delete Old Index** - Delete the old index
7. **Next Index** - Continue to next index in list

**Error Handling**: Fail fast - if any index fails, stop execution and log detailed errors to CloudWatch

## Input JSON Format
```json
{
  "opensearch_endpoint": "https://my-domain.us-east-1.es.amazonaws.com",
  "index_pattern": "^(.+)_v(\\d+)$",
  "index_replacement": "\\1_v{{next_version}}",
  "alias_name": "{{index_base}}_current",
  "indices": [
    "products_v1",
    "orders_v2",
    "customers_v1"
  ]
}
```

## Lambda Functions
Use a **single Python codebase** packaged as a zip file, with different handler configurations:
- `create_index` - Creates new index with mappings from old index
- `update_aliases` - Manages alias write flags
- `start_reindex` - Initiates async reindex task
- `check_reindex_status` - Polls task completion
- `remove_alias` - Removes alias from old index
- `delete_index` - Deletes old index

## Testing Requirements
- Unit tests for all Lambda handlers (pytest)
- Mock AWS services (boto3, opensearch-py) using moto/pytest-mock
- Minimum 80% code coverage
- Test error conditions and edge cases

## Deliverables
1. `/terraform/` - All infrastructure as code
2. `/src/` - Python Lambda code
3. `/tests/` - Unit tests
4. `/examples/` - Sample JSON trigger files
5. `README.md` - Setup and usage instructions

## Success Criteria
- [ ] All Terraform applies cleanly
- [ ] All tests pass
- [ ] Can trigger re-indexing by uploading JSON to S3
- [ ] Step Function completes successfully for valid input
- [ ] Step Function fails appropriately for invalid input
- [ ] Code is well-documented and follows Python best practices



# Technical Specifications

## AWS Infrastructure

### S3 Bucket
- **Name**: `opensearch-reindex-triggers-${aws_account_id}`
- **Versioning**: Enabled
- **Encryption**: AES256
- **Lifecycle**: Delete JSON files after 30 days
- **Event Notification**: EventBridge enabled

### EventBridge Rule
- **Pattern**: S3 object created with `.json` suffix
- **Target**: Step Function execution
- **IAM**: Role to invoke Step Functions

### Step Functions State Machine
- **Type**: Standard (not Express)
- **Definition**: Sequential Map state iterating over indices with error catching
- **Timeout**: 2 hours
- **Logging**: CloudWatch Logs (ALL events)
- **Flow**: GetTriggerFile → Map (per-index workflow from above) → Success

### Lambda Functions

#### Runtime & Configuration
- **Runtime**: Python 3.11
- **Architecture**: x86_64
- **Memory**: 512 MB
- **Timeout**: 5 minutes
- **Environment Variables**:
  - `LOG_LEVEL`: INFO

#### Single Code Package
- **Source**: `/src/handlers.py`
- **Deployment**: ZIP file created by Terraform
- **Dependencies**: 
  - `boto3` (provided by AWS)
  - `opensearch-py`
  - `requests`
  - `requests-aws4auth` (for IAM auth, future enhancement)

#### Handler Functions
All in `handlers.py`:
- `get_trigger_file_handler` - Read JSON from S3
- `create_index_handler` - Create new index
- `update_aliases_handler` - Manage aliases
- `start_reindex_handler` - Start async reindex
- `check_reindex_status_handler` - Poll task status
- `remove_alias_handler` - Remove alias
- `delete_index_handler` - Delete index

#### IAM Role Permissions
- **S3**: `s3:GetObject` on trigger bucket
- **CloudWatch Logs**: Create and write logs
- **VPC** (optional): ENI management if VPC-attached

## OpenSearch Integration

### Connection
- **Endpoint**: From JSON config (e.g., `https://domain.us-east-1.es.amazonaws.com`)
- **Port**: 443 (HTTPS)
- **Auth**: sig4 - signed IAM
- **Client**: opensearch-py library

### API Calls

#### Create Index
```python
PUT /{new_index_name}
{
  "settings": { ... },  # Copy from source
  "mappings": { ... }   # Copy from source
}
```

#### Update Aliases
```python
POST /_aliases
{
  "actions": [
    {"add": {"index": "new_index", "alias": "alias_name", "is_write_index": true}},
    {"add": {"index": "old_index", "alias": "alias_name", "is_write_index": false}}
  ]
}
```

#### Start Async Reindex
```python
POST /_reindex?wait_for_completion=false
{
  "source": {"index": "old_index"},
  "dest": {"index": "new_index"}
}
# Returns: {"task": "oTUltX4IQMOUUVeiohTt8A:12345"}
```

#### Check Task Status
```python
GET /_tasks/{task_id}
# Returns: {"completed": true/false, "response": {...}}
```

#### Remove Alias
```python
POST /_aliases
{
  "actions": [
    {"remove": {"index": "old_index", "alias": "alias_name"}}
  ]
}
```

#### Delete Index
```python
DELETE /{old_index_name}
```

## Python Code Structure

### Directory Layout
```
src/
  handlers.py          # All Lambda handlers
  opensearch_client.py # OpenSearch connection & operations
  utils.py            # Helpers (pattern matching, etc.)
  requirements.txt     # Dependencies

tests/
  test_handlers.py
  test_opensearch_client.py
  test_utils.py
  conftest.py         # pytest fixtures
  
terraform/
  main.tf
  variables.tf
  outputs.tf
  s3.tf
  lambda.tf
  stepfunctions.tf
  eventbridge.tf
  iam.tf
```

### Error Handling
- Use custom exceptions: `ReindexError`, `IndexCreationError`, etc.
- All Lambda handlers catch and log errors
- Return structured error responses for Step Functions
- Include retry logic for transient failures

### Logging
- Use Python `logging` module
- Structured JSON logs
- Include correlation ID (Step Function execution ID)
- Log levels: DEBUG for development, INFO for production

## Testing Strategy

### Unit Tests (pytest)
- **Fixtures**: Mock OpenSearch client, S3 client, boto3
- **Coverage**: All handlers, utilities, error paths
- **Mocking**: Use `pytest-mock` and `moto` for AWS services
- **Assertions**: Test return values, exceptions, side effects

### Test Cases
- Valid index creation
- Alias management (add/remove)
- Async reindex start and polling
- Error handling (index doesn't exist, auth failure, etc.)
- Pattern matching for index names
- JSON parsing and validation

## Configuration Management

### Terraform Variables
- `aws_region` (default: us-east-1)
- `project_name` (default: opensearch-reindex)
- `environment` (default: dev)
- `lambda_timeout` (default: 300)
- `lambda_memory` (default: 512)

### Outputs
- S3 bucket name
- Step Function ARN
- Lambda function ARNs
- EventBridge rule ARN

## Security Considerations
- S3 bucket not public
- Lambda functions have minimal IAM permissions
- CloudWatch logs for audit trail

## Performance & Limits
- Sequential processing (not parallel)
- Max ~1000 indices per execution (Step Function payload limits)
- Poll interval: 30 seconds
- Lambda timeout: 5 minutes (should complete much faster)
- Step Function timeout: 2 hours

## Monitoring
- CloudWatch Logs for all Lambda executions
- Step Function execution history
- CloudWatch Metrics (auto-generated)
- Future: SNS notifications for failures
