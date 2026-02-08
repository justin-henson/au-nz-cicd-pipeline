# Pipeline Failure Runbook

This runbook provides troubleshooting steps for common pipeline failures in the `au-nz-cicd-pipeline` project.

**Target audience:** DevOps engineers, SREs, on-call responders
**Related documentation:**
- [PIPELINE-ARCHITECTURE.md](./PIPELINE-ARCHITECTURE.md) - Pipeline design and flow
- [DECISION-LOG.md](./DECISION-LOG.md) - Architectural decisions
- [au-nz-ops-runbooks](https://github.com/justin-henson/au-nz-ops-runbooks) - General operational procedures

---

## Table of Contents

1. [Terraform Plan Failures](#terraform-plan-failures)
2. [Terraform Apply Failures](#terraform-apply-failures)
3. [Drift Detection Failures](#drift-detection-failures)
4. [Authentication and Permissions Errors](#authentication-and-permissions-errors)
5. [Workflow Trigger Issues](#workflow-trigger-issues)
6. [Artifact Handling Failures](#artifact-handling-failures)
7. [State Locking Issues](#state-locking-issues)
8. [Escalation and Support](#escalation-and-support)

---

## Terraform Plan Failures

### Symptom: `terraform fmt -check` fails

**Error message:**
```
Error: terraform fmt -check failed
Files not formatted correctly
```

**Root cause:** Code not formatted to Terraform standards

**Resolution:**
```bash
# Run locally before committing
terraform fmt -recursive

# Commit the formatting changes
git add .
git commit -m "Fix: Apply terraform formatting"
git push
```

**Prevention:**
- Set up pre-commit hook to run `terraform fmt` automatically
- Configure IDE (VS Code) with Terraform extension for auto-formatting

---

### Symptom: `terraform validate` fails

**Error message:**
```
Error: Invalid resource reference
Error: Missing required argument
```

**Root cause:** Syntax errors or invalid resource references in Terraform code

**Resolution:**
1. Review the error message for specific file and line number
2. Common issues:
   - Undefined variables referenced in code
   - Typos in resource names or attributes
   - Missing required arguments in resource blocks
   - Invalid HCL syntax

3. Fix locally and test:
   ```bash
   cd terraform/
   terraform init
   terraform validate
   ```

4. Commit and push the fix

**Prevention:**
- Use IDE with Terraform language server for real-time validation
- Run `terraform validate` locally before pushing

---

### Symptom: TFLint failures

**Error message:**
```
Error: TFLint found issues
- Warning: instance_type is not in the free tier
- Error: Security group allows 0.0.0.0/0 ingress
```

**Root cause:** Code violates Terraform best practices or security policies

**Resolution:**
1. Review TFLint output for specific warnings/errors
2. Address issues:
   - Security warnings: Restrict CIDR blocks, enable encryption
   - Best practice warnings: May be safe to ignore for demos
   - Deprecated syntax: Update to current Terraform patterns

3. To bypass TFLint for demos (not recommended for production):
   ```yaml
   # Comment out TFLint step in terraform-plan.yml
   # - name: Run TFLint
   #   ...
   ```

**Prevention:**
- Run `tflint` locally before committing
- Configure `.tflint.hcl` with project-specific rules

---

### Symptom: `terraform plan` fails with provider errors

**Error message:**
```
Error: error configuring Terraform AWS Provider: no valid credential sources
Error: NoCredentialProviders: no valid providers in chain
```

**Root cause:** AWS credentials not configured or invalid

**Resolution:** See [Authentication and Permissions Errors](#authentication-and-permissions-errors)

---

## Terraform Apply Failures

### Symptom: Apply fails with resource already exists

**Error message:**
```
Error: ResourceAlreadyExists: Instance i-xxxxx already exists
Error: Security group 'sg-xxxxx' already exists
```

**Root cause:** Resources exist in AWS but not in Terraform state

**Resolution:**

**Option 1: Import existing resources (if you want to manage them with Terraform)**
```bash
cd terraform/
terraform import module.app_stack.aws_instance.app i-xxxxx
terraform import module.app_stack.aws_security_group.app sg-xxxxx
```

**Option 2: Remove existing resources (if they're orphaned)**
```bash
# Via AWS Console or CLI
aws ec2 terminate-instances --instance-ids i-xxxxx
aws ec2 delete-security-group --group-id sg-xxxxx
```

**Option 3: Rename resources in Terraform to avoid conflict**
```hcl
# Change resource names or add environment prefix
name = "${var.project_name}-${var.environment}-v2-app"
```

**Prevention:**
- Always use unique resource names with environment prefixes
- Clean up resources before redeploying
- Use Terraform workspaces or separate state files per environment

---

### Symptom: Apply fails midway through execution

**Error message:**
```
Error: timeout while waiting for resource to be created
Error: failed to create resource after 10 retries
```

**Root cause:** AWS API rate limiting, resource dependencies, or transient failures

**Resolution:**

1. **Check workflow logs** for specific resource that failed
2. **Verify AWS service health**: https://status.aws.amazon.com/
3. **Re-run apply**:
   - Terraform will pick up where it left off using state
   - Resources already created won't be recreated
   - Failed resource will be retried

4. **If persistent**:
   ```bash
   # Run locally to troubleshoot
   cd terraform/
   terraform init
   terraform plan
   terraform apply
   ```

5. **Check for quota limits**:
   ```bash
   aws service-quotas get-service-quota \
     --service-code ec2 \
     --quota-code L-1216C47A  # On-Demand instances
   ```

**Prevention:**
- Implement exponential backoff in provider configuration
- Use AWS Service Quotas to monitor limits
- Add lifecycle rules for better resource dependency handling

---

### Symptom: Manual approval not triggered

**Error message:**
```
Job is stuck waiting for environment approval
```

**Root cause:** GitHub Environment not configured or reviewers not set

**Resolution:**

1. **Verify environment exists**:
   - Go to repository Settings → Environments
   - Check if "production" environment exists

2. **Configure required reviewers**:
   - Settings → Environments → production → Required reviewers
   - Add 1-6 reviewers who can approve deployments

3. **Check workflow reference**:
   ```yaml
   environment:
     name: production  # Must match environment name exactly
   ```

4. **Approve pending deployment**:
   - Go to Actions tab → Select workflow run
   - Click "Review deployments" button
   - Select environment and click "Approve and deploy"

**Prevention:**
- Document environment setup in repository README
- Use Terraform or scripts to configure GitHub settings via API

---

## Drift Detection Failures

### Symptom: Drift detection workflow fails with exit code 1

**Error message:**
```
Error: Error during drift detection
Exit code: 1
```

**Root cause:** Terraform plan encountered an error (not drift)

**Resolution:**

1. **Check workflow logs** for Terraform error messages
2. Common issues:
   - AWS credentials expired or invalid
   - Backend state unavailable
   - Provider version incompatibility
   - Resource no longer exists in AWS (manually deleted)

3. **Debug locally**:
   ```bash
   cd terraform/
   terraform init
   terraform plan -detailed-exitcode
   # Exit code 0 = no changes
   # Exit code 1 = error
   # Exit code 2 = changes/drift
   ```

4. **Fix underlying issue** (credentials, state, etc.)

**Prevention:**
- Monitor AWS credential expiration
- Set up alerts for drift detection failures

---

### Symptom: False positive drift detection

**Error message:**
```
Drift detected: 15 resources changed
But manual review shows no meaningful changes
```

**Root cause:** Terraform detecting expected or non-meaningful changes

**Common false positives:**
- AMI IDs change when AWS updates base images
- Timestamps or computed values that always differ
- AWS-managed fields (metadata, resource tags added by AWS)
- Formatting differences in JSON policies

**Resolution:**

1. **Review drift details** to identify affected attributes
2. **If changes are expected/harmless**, close the drift issue
3. **If changes are from AWS updates**:
   ```hcl
   lifecycle {
     ignore_changes = [
       ami,  # Ignore AMI updates
       user_data,  # Ignore user data changes
       tags["LastModified"],  # Ignore AWS-managed tags
     ]
   }
   ```

4. **Update Terraform config** to match AWS reality if that's the desired state

**Prevention:**
- Use `lifecycle.ignore_changes` for known drift sources
- Document expected drift patterns in code comments

---

## Authentication and Permissions Errors

### Symptom: AWS credential errors

**Error message:**
```
Error: NoCredentialProviders: no valid providers in chain
Error: InvalidClientTokenId: The security token is invalid
Error: ExpiredToken: The security token expired
```

**Root cause:** AWS credentials not configured, invalid, or expired

**Resolution:**

1. **Verify secrets are configured**:
   - Settings → Secrets and variables → Actions → Secrets
   - Check for `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

2. **Test credentials locally**:
   ```bash
   export AWS_ACCESS_KEY_ID="your-key"
   export AWS_SECRET_ACCESS_KEY="your-secret"
   aws sts get-caller-identity
   ```

3. **If expired**, rotate credentials:
   - Create new AWS IAM access key
   - Update GitHub secrets
   - Delete old access key

4. **For OIDC (recommended)**:
   - Configure GitHub OIDC provider in AWS IAM
   - Update workflow to use OIDC authentication
   - Remove long-lived credentials

**Prevention:**
- Use OIDC instead of long-lived credentials
- Set up credential rotation reminders
- Use AWS IAM roles with temporary credentials

---

### Symptom: Insufficient permissions

**Error message:**
```
Error: UnauthorizedOperation: You are not authorized to perform this operation
Error: AccessDenied: User is not authorized to perform: ec2:RunInstances
```

**Root cause:** AWS IAM user/role lacks required permissions

**Resolution:**

1. **Identify required permission** from error message
2. **Update IAM policy**:
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "ec2:RunInstances",
       "ec2:CreateSecurityGroup",
       "ec2:AuthorizeSecurityGroupIngress",
       "ec2:DescribeInstances",
       "ec2:DescribeSecurityGroups"
     ],
     "Resource": "*"
   }
   ```

3. **Apply policy** to IAM user/role used by GitHub Actions

4. **Test permissions**:
   ```bash
   aws ec2 describe-instances  # Should succeed
   ```

**Prevention:**
- Use Terraform to manage IAM policies for CI/CD users
- Start with broad permissions, then restrict based on actual usage
- Document required permissions in README

---

## Workflow Trigger Issues

### Symptom: Workflow not triggering on PR

**Resolution:**

1. **Check trigger configuration**:
   ```yaml
   on:
     pull_request:
       branches:
         - main
       paths:  # Workflow only triggers if these paths change
         - 'terraform/**'
   ```

2. **Verify paths changed**:
   - If PR only changes documentation, workflow won't trigger
   - Remove `paths` filter to trigger on all changes

3. **Check GitHub Actions enabled**:
   - Settings → Actions → General → Allow all actions

**Prevention:**
- Use `workflow_dispatch` for manual testing
- Document path filters in workflow comments

---

### Symptom: Scheduled drift detection not running

**Resolution:**

1. **Verify cron syntax**:
   ```yaml
   schedule:
     - cron: '0 23 * * 0'  # Sunday 11 PM UTC = Monday 9 AM AEST
   ```

2. **Check last run**:
   - Actions tab → drift-detection.yml → View all workflow runs
   - GitHub may delay scheduled runs by several minutes

3. **Manually trigger**:
   - Actions → drift-detection.yml → Run workflow

**Prevention:**
- Use external monitoring (AWS EventBridge) to ensure scheduled jobs run
- Set up alerts for missed scheduled runs

---

## Artifact Handling Failures

### Symptom: Plan artifact download fails

**Error message:**
```
Error: Artifact not found: tfplan-123
Error: Artifact has expired (retention: 5 days)
```

**Root cause:** Plan artifact expired or PR number mismatch

**Resolution:**

1. **Check artifact age**: Artifacts expire after 5 days
2. **Workflow will auto-fallback** to generating fresh plan
3. **Verify fallback logic works**:
   ```yaml
   - name: Download Plan Artifact
     continue-on-error: true  # Must be set
   ```

4. **If fallback isn't working**, check logs for plan generation errors

**Prevention:**
- Merge PRs within 5 days of last plan
- Consider increasing retention days (costs more)
- Document artifact expiration policy

---

## State Locking Issues

### Symptom: State locked error

**Error message:**
```
Error: Error acquiring the state lock
Lock Info:
  ID:        abc123-def456
  Operation: OperationTypeApply
  Who:       user@hostname
  Created:   2025-02-08 10:30:00 UTC
```

**Root cause:** Another Terraform operation is in progress, or previous operation didn't release lock

**Resolution:**

1. **Check for running workflows**:
   - Actions tab → Look for "in progress" runs
   - If found, wait for completion or cancel

2. **If no running workflows**, lock is stale:
   ```bash
   # For S3+DynamoDB backend
   terraform force-unlock abc123-def456

   # Confirm when prompted
   ```

3. **Verify lock is released**:
   ```bash
   terraform init
   terraform plan  # Should succeed
   ```

**Prevention:**
- Use concurrency controls in workflows
- Implement lock timeout in backend configuration
- Monitor for orphaned locks

---

## Escalation and Support

### When to Escalate

Escalate to senior DevOps/SRE team when:
- Multiple consecutive pipeline failures
- Data loss or corruption suspected
- AWS outage affecting deployments
- Security incidents (credential leaks, unauthorized changes)
- Manual intervention required in production

### Escalation Contacts

- **DevOps Lead**: [Contact info]
- **SRE On-Call**: [PagerDuty/Opsgenie link]
- **AWS Support**: [Support case URL if Enterprise support]

### Gathering Information for Escalation

When escalating, provide:
1. **Workflow run URL**: Link to failed workflow
2. **Error messages**: Copy/paste from logs
3. **Recent changes**: PRs merged in last 24 hours
4. **Impact**: What's broken, who's affected
5. **Troubleshooting steps taken**: What you've already tried

### Related Runbooks

- [AWS IAM Troubleshooting](https://github.com/justin-henson/au-nz-ops-runbooks) - IAM and credential issues
- [Terraform State Recovery](https://github.com/justin-henson/au-nz-ops-runbooks) - State corruption or loss
- [Incident Response](https://github.com/justin-henson/au-nz-ops-runbooks) - General incident management

---

## Useful Commands

### Quick Diagnostics

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify Terraform installation
terraform version

# Check Terraform configuration
cd terraform/
terraform fmt -check -recursive
terraform validate

# Test Terraform plan locally
terraform init
terraform plan

# Check GitHub Actions status
gh workflow list
gh run list --workflow=terraform-plan.yml
gh run view <run-id> --log
```

### Force Refresh State

```bash
cd terraform/
terraform init
terraform refresh  # Update state from AWS
terraform plan     # Should show any drift
```

### Clean and Reinitialize

```bash
cd terraform/
rm -rf .terraform/ .terraform.lock.hcl
terraform init
```

---

## Post-Incident Actions

After resolving a pipeline failure:

1. **Document root cause** in this runbook (if new failure mode)
2. **Update workflow** to prevent recurrence
3. **Review related PRs** for similar issues
4. **Update team documentation** if process changes needed
5. **Consider adding automated checks** to catch issue earlier

---

## Feedback and Improvements

This runbook should be a living document. If you:
- Encounter a failure scenario not covered here
- Find outdated or incorrect information
- Have suggestions for better troubleshooting steps

Please open an issue or PR to update this document.
