# Decision Log

This document records key architectural and design decisions made for this CI/CD pipeline, including the context, alternatives, and trade-offs for each choice.

---

## Decision 1: GitHub Actions vs GitLab CI vs Jenkins

**Decision:** Use GitHub Actions for CI/CD pipeline

**Context:**

For a portfolio project targeting AU/NZ DevOps roles, the CI/CD tool choice sends a signal about what you know and what environments you're ready for. GitHub Actions has become the de facto standard for GitHub-hosted projects and is widely used in modern tech companies, particularly in the AU/NZ market where cloud-native practices are prioritized.

**Alternatives Considered:**

1. **GitLab CI**
   - Strong built-in CI/CD with excellent Terraform integration
   - Popular in enterprise environments, especially in regulated industries
   - Would require mirroring to GitLab or hosting there natively

2. **Jenkins**
   - Most mature option with vast plugin ecosystem
   - Still common in large enterprises and banks
   - Requires self-hosting or a cloud Jenkins instance
   - More complex to set up and maintain

3. **CircleCI / Travis CI**
   - Solid hosted CI options
   - Less common in AU/NZ market compared to GitHub Actions
   - Additional service to manage and pay for

**Trade-offs:**

✅ **Pros of GitHub Actions:**
- Native integration with GitHub (no external service required)
- Free for public repos, generous free tier for private repos
- Built-in secrets management and environment protection
- GitHub-native features: PR comments, commit statuses, issue creation
- YAML-based configuration (similar to GitLab CI)
- Large marketplace of reusable actions
- Growing adoption in AU/NZ tech scene

❌ **Cons of GitHub Actions:**
- Less mature than Jenkins for complex enterprise workflows
- Workflow debugging can be challenging (limited local testing)
- Minute limits on free tier (though generous for most projects)
- Less flexible than self-hosted Jenkins for custom requirements

**Why This Matters:**

For a portfolio project, GitHub Actions demonstrates:
- Modern cloud-native practices
- Ability to work with SaaS CI/CD platforms
- Understanding of GitHub's ecosystem
- Skills directly transferable to many AU/NZ companies already using GitHub

For production use, the choice depends on existing tooling, compliance requirements, and team expertise.

---

## Decision 2: Plan Artifact vs Re-plan on Apply

**Decision:** Use plan artifacts with fallback to re-plan if artifact expires

**Context:**

A core principle of safe Terraform deployments is ensuring that what gets reviewed in a PR is exactly what gets applied to infrastructure. If a plan is regenerated between review and apply, the actual changes might differ from what was approved, especially if:
- Other PRs merged in the meantime
- AWS resources changed (drift)
- Time-based resources changed (timestamps, etc.)

**Alternatives Considered:**

1. **Always re-plan on apply**
   - Simpler workflow (no artifact handling)
   - Always reflects current state
   - But: Reviewed plan may not match applied plan

2. **Always require cached plan artifact**
   - Strict enforcement: if artifact expires, deployment fails
   - Maximum safety guarantee
   - But: Operational friction (need to re-do PR for artifact)

3. **Use Terraform Cloud/Sentinel**
   - Managed service handles plan artifacts automatically
   - Built-in policy enforcement
   - But: Additional cost and service dependency

**Trade-offs:**

✅ **Pros of artifact-with-fallback:**
- Best of both worlds: use cached plan when available, don't block deploys if expired
- Reviewers see accurate preview of changes in most cases
- Operational flexibility (stale artifacts don't block deploys)
- Clear logging of which strategy was used

❌ **Cons:**
- Slightly more complex workflow logic
- Edge case: if artifact expires, applied changes might differ from what was reviewed
- Need to handle artifact download failures gracefully
- 5-day artifact retention (GitHub limit) might expire for slow-moving PRs

**Implementation:**

```yaml
- name: Download Plan Artifact
  id: download-artifact
  uses: actions/download-artifact@v4
  continue-on-error: true

- name: Determine Apply Strategy
  id: strategy
  run: |
    if [ -f "tfplan" ]; then
      echo "using_artifact=true"
    else
      echo "using_artifact=false"
    fi
```

**Why This Matters:**

In production environments, teams need to balance safety with operational velocity. This approach demonstrates understanding that:
- Perfect safety (always use cached plan) can block deploys unnecessarily
- No safety (always re-plan) can lead to surprise changes
- Pragmatic safety (cached with fallback) handles real-world scenarios

For highly regulated environments (finance, healthcare), you'd enforce cached-only. For fast-moving startups, re-plan might be acceptable. This shows you can reason about the trade-offs.

---

## Decision 3: Drift Detection Approach (Scheduled vs Event-Driven)

**Decision:** Use scheduled weekly drift detection with manual trigger option

**Context:**

Infrastructure drift happens when the actual state of resources diverges from the Terraform-managed configuration. This can occur through:
- Manual changes via AWS Console
- Changes made by other automation (Lambda functions, auto-scaling, AWS services)
- Configuration drift over time
- Security patches or updates applied by AWS

Detecting drift is critical for maintaining infrastructure-as-code as the source of truth.

**Alternatives Considered:**

1. **Event-driven drift detection**
   - Use AWS CloudTrail + EventBridge to trigger drift checks on AWS API calls
   - Near real-time detection of changes
   - More complex setup (need CloudTrail, EventBridge rules, Lambda or webhook handler)
   - Higher AWS costs (CloudTrail events, Lambda invocations)
   - Can be noisy (many API calls don't cause meaningful drift)

2. **Continuous drift detection (every push)**
   - Run drift check on every commit to main
   - Immediate feedback loop
   - But: High CI/CD minute usage, potentially slow deploys
   - Drift likely hasn't occurred between consecutive commits

3. **No drift detection**
   - Simplest option (do nothing)
   - But: Manual changes go undetected until next deploy
   - Infrastructure-as-code becomes unreliable over time

4. **Terraform Cloud Drift Detection**
   - Managed service with built-in drift detection
   - Configurable schedules and notifications
   - But: Requires Terraform Cloud subscription
   - Adds external dependency

**Trade-offs:**

✅ **Pros of scheduled approach:**
- Predictable CI/CD minute usage (once per week)
- Simple to implement (just a cron schedule)
- Catches drift before it accumulates too much
- Manual trigger option for ad-hoc checks
- No external dependencies (AWS EventBridge, etc.)
- Low noise (only checks when you want to check)

❌ **Cons:**
- Not real-time (drift can exist for up to a week undetected)
- Weekly schedule might be too infrequent for fast-changing environments
- Doesn't prevent drift, only detects it after the fact
- Requires manual intervention to fix drift

**Implementation:**

```yaml
schedule:
  - cron: '0 23 * * 0'  # Weekly on Monday 9 AM AEST
workflow_dispatch:       # Manual trigger option
```

**Why This Matters:**

Drift detection is a differentiator few candidates demonstrate. This shows you understand:
- Infrastructure-as-code isn't "set and forget"
- Real-world operations require monitoring for configuration divergence
- Balance between detection frequency and operational overhead
- How to make drift visible (GitHub issues, Slack notifications)

For production:
- High-security environments: Daily or event-driven
- Standard production: Weekly (as implemented)
- Development environments: Monthly or ad-hoc only

---

## Decision 4: State Management Strategy (S3+DynamoDB vs Terraform Cloud)

**Decision:** Design for S3+DynamoDB remote state, but use local state for demo

**Context:**

Terraform state contains the mapping between your configuration and real-world resources. Managing state correctly is critical for:
- Preventing concurrent modifications (state locking)
- Sharing state across team members and CI/CD
- Protecting sensitive data (credentials, private IPs often in state)
- Enabling state versioning and rollback

**Alternatives Considered:**

1. **Local state (file-based)**
   - Simplest option (default behavior)
   - No setup required
   - But: Can't share between team members or CI/CD runs
   - No locking (corruption risk with concurrent access)
   - No versioning or backup

2. **S3 + DynamoDB (AWS native)**
   - S3 stores state files with versioning and encryption
   - DynamoDB provides state locking
   - Fully self-managed (no third-party service)
   - Works with any AWS account
   - But: Requires setting up S3 bucket and DynamoDB table
   - Need to manage permissions and lifecycle policies

3. **Terraform Cloud/Enterprise**
   - Managed state storage with built-in locking
   - Web UI for viewing state and history
   - Built-in RBAC and audit logging
   - Remote execution option
   - But: Requires Terraform Cloud account
   - Free tier limits (5 users, limited runs)
   - Additional service dependency
   - Data stored outside your AWS account

4. **Git-based state (not recommended)**
   - Store state in Git repository
   - But: State files can be large and change frequently
   - Sensitive data in Git history
   - Merge conflicts with concurrent changes
   - Generally considered an anti-pattern

**Trade-offs:**

✅ **Pros of S3+DynamoDB:**
- Fully self-contained in your AWS account
- No external dependencies or additional costs (beyond minimal S3/DynamoDB)
- Industry-standard approach for AWS-based Terraform
- Supports all Terraform features (state locking, versioning, encryption)
- Works in air-gapped or restricted environments
- No per-user licensing costs

❌ **Cons:**
- Requires upfront setup (S3 bucket, DynamoDB table, IAM permissions)
- No built-in UI for viewing state (need to download from S3)
- Need to manage backup/lifecycle policies yourself
- No built-in RBAC beyond AWS IAM
- Team needs to coordinate backend configuration

**Implementation:**

```hcl
# backend.tf (commented out for demo)
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "cicd-pipeline/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

**Why This Matters:**

For a portfolio demo:
- Local state is acceptable (each workflow run is isolated)
- Shows understanding that this isn't production-ready
- Provides clear instructions for production setup

For production:
- S3+DynamoDB is the standard choice for AWS-based teams
- Terraform Cloud makes sense for multi-cloud or teams wanting managed state
- The choice depends on budget, compliance, and operational preferences

This demonstrates:
- Understanding of state management requirements
- Ability to design for production while demoing pragmatically
- Knowledge of setup steps and operational considerations

**When to use Terraform Cloud instead:**
- Multi-cloud environments (AWS + GCP + Azure)
- Teams wanting web UI for state inspection
- Need for remote execution and Sentinel policies
- Budget for managed services ($20-70/user/month)

---

## Summary Table

| Decision | Chosen Approach | Key Trade-off |
|----------|----------------|---------------|
| CI/CD Platform | GitHub Actions | Native integration vs enterprise maturity |
| Plan Strategy | Artifact with fallback | Safety vs operational flexibility |
| Drift Detection | Scheduled weekly | Real-time detection vs simplicity |
| State Management | S3+DynamoDB (designed) | Self-managed vs managed service |

---

## Lessons for Production

These decisions reflect portfolio/demo priorities. In production, adjust based on:

- **Regulatory requirements**: May require stricter plan artifact enforcement, more frequent drift detection
- **Team size**: Larger teams benefit from Terraform Cloud's collaboration features
- **Budget**: Managed services vs self-managed infrastructure
- **Risk tolerance**: High-stakes environments need more safety gates
- **Change velocity**: Fast-moving teams may need different drift detection frequency

The key is being able to articulate why you chose what you chose, and under what circumstances you'd choose differently.
