# TODO List

## Phase 0: Docker Environment Setup
- [x] Create `docker-compose.yml` with LocalStack service
- [x] Configure LocalStack with required services (S3, Lambda, StepFunctions, EventBridge, IAM, CloudWatch)
- [x] Add local OpenSearch 2.x container to `docker-compose.yml`
- [x] Add `awslocal` CLI alias for LocalStack interactions
- [x] Document LocalStack endpoints and access in AGENTS.md
- [x] Test environment is running (`docker compose up -d`)
- [x] Verify OpenSearch connectivity (index a test document)

## Phase 1: Project Setup
- [ ] Create directory structure (src, tests, terraform, examples, terraform/environments)
- [ ] Create `src/requirements.txt` with Python dependencies
- [ ] Set up pytest configuration (pytest.ini, conftest.py)
- [ ] Create example JSON trigger file in `examples/reindex-config.json`
- [ ] Create `terraform/environments/local.tfvars` for LocalStack
- [ ] Create Makefile with commands (setup-local, deploy-local, deploy-prod, test)
- [ ] Create project README.md with setup instructions

## Phase 2: Python Core Logic (TDD Approach)

### Utils Module
- [ ] Create `tests/test_utils.py`
- [ ] Write test for index pattern matching (regex)
- [ ] Write test for index name generation
- [ ] Write test for alias name generation
- [ ] Implement `src/utils.py` to pass tests

### OpenSearch Client Module
- [ ] Create `tests/test_opensearch_client.py`
- [ ] Write test for OpenSearch connection
- [ ] Write test for get index settings/mappings
- [ ] Write test for create index
- [ ] Write test for update aliases
- [ ] Write test for start reindex (async)
- [ ] Write test for check task status
- [ ] Write test for delete index
- [ ] Implement `src/opensearch_client.py` to pass tests

### Lambda Handlers
- [ ] Create `tests/test_handlers.py`
- [ ] Write test for `get_trigger_file_handler` (read JSON from S3)
- [ ] Write test for `create_index_handler`
- [ ] Write test for `update_aliases_handler`
- [ ] Write test for `start_reindex_handler`
- [ ] Write test for `check_reindex_status_handler`
- [ ] Write test for `remove_alias_handler`
- [ ] Write test for `delete_index_handler`
- [ ] Implement `src/handlers.py` to pass all tests

### Test Coverage & Quality
- [ ] Run pytest with coverage report (target 80%+)
- [ ] Add missing test cases for error conditions
- [ ] Add docstrings to all functions
- [ ] Run pylint/flake8 for code quality

## Phase 3: Terraform Infrastructure (LocalStack First)

### Base Infrastructure
- [ ] Create `terraform/main.tf` with provider configuration (LocalStack endpoints)
- [ ] Create `terraform/variables.tf` with all variables (endpoint overrides, skip_validation flags)
- [ ] Create `terraform/outputs.tf` with outputs
- [ ] Create `terraform/locals.tf` for environment detection logic
- [ ] Add conditional logic for LocalStack vs AWS endpoint configuration

### S3 Bucket
- [ ] Create `terraform/s3.tf` with bucket configuration
- [ ] Enable versioning and encryption
- [ ] Configure lifecycle rules
- [ ] Enable EventBridge notifications

### IAM Roles & Policies
- [ ] Create `terraform/iam.tf`
- [ ] Lambda execution role with CloudWatch Logs permissions
- [ ] Lambda policy for S3 GetObject
- [ ] EventBridge role to invoke Step Functions
- [ ] Step Functions role to invoke Lambda

### Lambda Functions
- [ ] Create `terraform/lambda.tf`
- [ ] Package Python code as ZIP (data source or null_resource)
- [ ] Create all Lambda function resources (7 functions, same code)
- [ ] Configure environment variables
- [ ] Set up CloudWatch Log Groups

### Step Functions
- [ ] Create `terraform/stepfunctions.tf`
- [ ] Define state machine JSON with Map state for sequential processing
- [ ] Include Wait states for polling
- [ ] Add Choice states for status checking
- [ ] Configure error handling (Catch, Retry)
- [ ] Enable CloudWatch Logs

### EventBridge
- [ ] Create `terraform/eventbridge.tf`
- [ ] Create rule for S3 object creation events
- [ ] Filter for .json files
- [ ] Configure Step Functions as target

### Validation
- [ ] Run `terraform init`
- [ ] Run `terraform validate`
- [ ] Run `terraform plan`

## Phase 4: Integration & Testing

### Local Unit Testing
- [ ] Test Python code with pytest (mocked AWS services)
- [ ] Verify all tests pass
- [ ] Check code coverage (target 80%+)

### LocalStack Infrastructure Testing
- [ ] Run `terraform init` (LocalStack config)
- [ ] Run `terraform plan -var-file=environments/local.tfvars`
- [ ] Run `terraform apply -var-file=environments/local.tfvars`
- [ ] Verify resources created in LocalStack (`awslocal s3 ls`, `awslocal lambda list-functions`)
- [ ] Check S3 bucket exists in LocalStack
- [ ] Check Lambda functions deployed to LocalStack
- [ ] Check Step Function definition created in LocalStack
- [ ] Verify EventBridge rule created in LocalStack

### LocalStack End-to-End Testing
- [ ] Set up local OpenSearch container or use mock
- [ ] Create test indices in local OpenSearch
- [ ] Upload example JSON to LocalStack S3 (`awslocal s3 cp`)
- [ ] Verify EventBridge triggers Step Function in LocalStack
- [ ] Monitor Step Function execution (`awslocal stepfunctions describe-execution`)
- [ ] Check Lambda invocations in LocalStack logs
- [ ] Verify workflow completes successfully
- [ ] Test error scenarios (invalid JSON, missing index, etc.)
- [ ] Validate error handling and retries

## Phase 5: Documentation & Cleanup

### Documentation
- [ ] Write comprehensive README.md
- [ ] Add setup instructions
- [ ] Add usage examples
- [ ] Document JSON format
- [ ] Add troubleshooting section
- [ ] Document cleanup/teardown

### Code Quality
- [ ] Add type hints to Python code
- [ ] Add comprehensive docstrings
- [ ] Format code with black
- [ ] Sort imports with isort
- [ ] Final linting check

### Terraform Documentation
- [ ] Add comments to Terraform files
- [ ] Document variables with descriptions
- [ ] Add examples for terraform.tfvars

### Final Review
- [ ] Review all code for best practices
- [ ] Verify all tests still pass
- [ ] Run final terraform plan
- [ ] Update SIGNS.md with any lessons learned