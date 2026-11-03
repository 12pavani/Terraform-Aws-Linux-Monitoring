# Terraform AWS Linux Server with Monitoring

Infrastructure as Code project that provisions a small, monitored Linux web server on AWS.

## What it builds

- VPC, public subnet, internet gateway and route table
- Security group that allows HTTP only (no SSH)
- Amazon Linux 2023 EC2 instance (t3.micro) with IMDSv2 required and an encrypted gp3 root volume
- IAM instance profile so you can open a shell with SSM Session Manager (no SSH keys)
- `user_data.sh` (Bash): installs Nginx, publishes a status page, adds a cron health check that restarts Nginx if it stops answering
- CloudWatch alarms for high CPU and failed status checks, sending email through SNS
- Terraform state stored in S3 with versioning, encryption and native state locking
- GitHub Actions workflow: `terraform fmt -check`, `init`, `validate` on every pull request, plus an optional `plan`

```
Internet --> IGW --> Public subnet --> EC2 (Amazon Linux 2023 + Nginx)
                                          |
                          CloudWatch alarms --> SNS --> your email
```

## Prerequisites

- AWS account and an AWS CLI profile with permissions to create the resources above
- Terraform 1.10 or newer (needed for `use_lockfile` S3 locking)
- AWS CLI v2, and the Session Manager plugin if you want `aws ssm start-session`

## Deploy

```bash
# 1. Format the code once so the CI format check passes
terraform fmt -recursive

# 2. Create the remote state bucket (name must be globally unique)
./bootstrap/create_state_bucket.sh my-unique-tf-state-bucket ap-south-1

# 3. Configure the backend and variables
cp backend.hcl.example backend.hcl            # set bucket = "my-unique-tf-state-bucket"
cp terraform.tfvars.example terraform.tfvars  # set alert_email to your address

# 4. Initialise, review, apply
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Confirm the SNS subscription email that AWS sends you, otherwise alarm emails will not arrive.
Commit the generated `.terraform.lock.hcl` file.

## Verify

```bash
terraform output website_url          # open in a browser, you should see the status page
terraform output ssm_session_command  # run it to get a shell on the instance
```

On the instance:

```bash
systemctl status nginx
cat /etc/cron.d/healthcheck
sudo systemctl stop nginx    # within 5 minutes the cron health check restarts it
tail /var/log/healthcheck.log
```

## Test the alarm

```bash
# inside the SSM session
sudo dnf install -y stress-ng
stress-ng --cpu 2 --timeout 900
```

After about 10 minutes the `cpu-high` alarm goes to ALARM and you get an email.

## Optional: plan in GitHub Actions

The `validate` job needs no AWS access. To enable the `plan` job, create an IAM role that GitHub can assume through OIDC, then set these repository variables (Settings, Secrets and variables, Actions, Variables):

| Variable | Example |
|---|---|
| `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/github-terraform-plan` |
| `AWS_REGION` | `ap-south-1` |
| `TF_STATE_BUCKET` | `my-unique-tf-state-bucket` |
| `ALERT_EMAIL` | `you@example.com` |

## Clean up (avoid charges)

```bash
terraform destroy
aws s3 rb s3://my-unique-tf-state-bucket --force   # only if you no longer need the state bucket
```

## Cost

Within the AWS free tier a t3.micro and this setup cost close to nothing for a short test, but always run `terraform destroy` when you finish.

## Design choices

- **SSM instead of SSH:** no open port 22 and no key pairs to manage.
- **IMDSv2 required:** blocks the common metadata-credential theft path.
- **Remote state with locking:** safe for more than one person or CI job.
- **Alarms on CPU and status checks:** covers load problems and instance or host failures.
