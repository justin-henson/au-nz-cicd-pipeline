# Sample PR Output

This is an example of what a PR comment looks like after the `terraform-plan.yml` workflow runs.

---

### Terraform Plan Results 🏗️

#### Terraform Format and Style 🖌️
`success`

#### Terraform Initialization ⚙️
`success`

#### Terraform Validation 🤖
`success`

<details><summary>Validation Output</summary>

```
Success! The configuration is valid.
```

</details>

#### TFLint 🔍
`success`

#### Terraform Plan 📖
`success`

<details><summary>Show Plan Summary</summary>

**Changes:**
- ➕ Create: 2
- 🔄 Update: 0
- ❌ Destroy: 0

</details>

<details><summary>Show Full Plan</summary>

```terraform
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.app_stack.aws_instance.app will be created
  + resource "aws_instance" "app" {
      + ami                                  = "ami-0c55b159cbfafe1f0"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + cpu_core_count                       = (known after apply)
      + cpu_threads_per_core                 = (known after apply)
      + disable_api_stop                     = (known after apply)
      + disable_api_termination              = (known after apply)
      + ebs_optimized                        = (known after apply)
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + host_resource_group_arn              = (known after apply)
      + iam_instance_profile                 = (known after apply)
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_lifecycle                   = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = "t3.micro"
      + ipv6_address_count                   = (known after apply)
      + ipv6_addresses                       = (known after apply)
      + key_name                             = (known after apply)
      + monitoring                           = false
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + placement_partition_number           = (known after apply)
      + primary_network_interface_id         = (known after apply)
      + private_dns                          = (known after apply)
      + private_ip                           = (known after apply)
      + public_dns                           = (known after apply)
      + public_ip                            = (known after apply)
      + secondary_private_ips                = (known after apply)
      + security_groups                      = (known after apply)
      + source_dest_check                    = true
      + spot_instance_request_id             = (known after apply)
      + subnet_id                            = (known after apply)
      + tags                                 = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Module"      = "app-stack"
          + "Name"        = "cicd-demo-dev-app"
          + "Project"     = "cicd-pipeline"
        }
      + tags_all                             = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Module"      = "app-stack"
          + "Name"        = "cicd-demo-dev-app"
          + "Project"     = "cicd-pipeline"
          + "Repository"  = "github.com/justin-henson/cicd-pipeline"
        }
      + tenancy                              = (known after apply)
      + user_data                            = "c2eab2e4f3d3a4c4eb3a9c2b4f5e6d7c8b9a0b1c"
      + user_data_base64                     = (known after apply)
      + user_data_replace_on_change          = false
      + vpc_security_group_ids               = (known after apply)
    }

  # module.app_stack.aws_security_group.app will be created
  + resource "aws_security_group" "app" {
      + arn                    = (known after apply)
      + description            = "Security group for cicd-demo application in dev"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = "Allow all outbound traffic"
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = "HTTP access"
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = "SSH access"
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
            },
        ]
      + name                   = (known after apply)
      + name_prefix            = "cicd-demo-dev-app-"
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Module"      = "app-stack"
          + "Name"        = "cicd-demo-dev-app-sg"
          + "Project"     = "cicd-pipeline"
        }
      + tags_all               = {
          + "Environment" = "dev"
          + "ManagedBy"   = "Terraform"
          + "Module"      = "app-stack"
          + "Name"        = "cicd-demo-dev-app-sg"
          + "Project"     = "cicd-pipeline"
          + "Repository"  = "github.com/justin-henson/cicd-pipeline"
        }
      + vpc_id                 = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + app_stack_instance_id        = (known after apply)
  + app_stack_instance_public_ip = (known after apply)
  + app_stack_security_group_id  = (known after apply)
  + deployment_region            = "ap-southeast-2"
  + deployment_timestamp         = (known after apply)
  + environment                  = "dev"
```

</details>

*Pusher: @justin-henson, Action: `pull_request`, Workflow: `Terraform Plan`*

---

## What This Shows

This PR comment demonstrates:

1. **All validation checks passed** - Format, validation, linting all successful
2. **Clear change summary** - 2 resources to create, 0 to update, 0 to destroy
3. **Full plan details** - Reviewers can expand to see exactly what will change
4. **Automated posting** - No manual copy/paste required
5. **Audit trail** - Shows who triggered the workflow and what event

## Reviewer Actions

After seeing this comment, a reviewer would:

1. ✅ **Review the change summary** - Understand the scope (2 creates, 0 changes, 0 destroys)
2. ✅ **Expand full plan** - Verify the security group rules, instance configuration, tags
3. ✅ **Check for security issues** - Note the 0.0.0.0/0 CIDR (acceptable for demo, restrict in production)
4. ✅ **Approve or request changes** - Based on the plan details
5. ✅ **Merge when ready** - Triggers the apply workflow with manual approval gate

## Real-World Variations

In production, you might see:

- **🔄 Updates** - Existing resources being modified (instance type change, tag updates)
- **❌ Destroys** - Resources being removed (would trigger warnings in PR comment)
- **⚠️ Replaces** - Resources requiring recreation (would be highlighted with warnings)
- **Format failures** - If code isn't formatted, the workflow would post the failure and block merge
- **Validation errors** - Syntax errors or missing required arguments would be shown inline

## Why This Matters

Automated PR comments:
- Save time (no manual plan sharing)
- Create audit trail (plan is preserved in PR history)
- Enable asynchronous review (reviewers can review when ready)
- Improve quality (all changes reviewed before merge)
- Reduce errors (what's reviewed is what gets applied via artifacts)
