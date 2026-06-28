# Infrastructure

Terraform configuration that provisions the AWS infrastructure for the GroceryMate
app. It builds a load-balanced, auto-scaling deployment of the backend container,
backed by a PostgreSQL database, an ECR image registry, and an S3 bucket for user
avatars.

## Architecture

```
                Internet
                   │  HTTP :80
                   ▼
          ┌─────────────────┐
          │  ALB (public)   │
          └────────┬────────┘
                   │  forward :80
                   ▼
          ┌─────────────────┐        pull image     ┌──────────┐
          │  Auto Scaling   │ ◄──────────────────── │   ECR    │
          │  Group (EC2)    │                        └──────────┘
          │  Docker backend │
          └────────┬────────┘
        :5432      │            avatars
     ┌─────────────┴───────────────┐
     ▼                             ▼
┌──────────┐                 ┌──────────┐
│   RDS    │                 │    S3    │
│ Postgres │                 │ (private)│
└──────────┘                 └──────────┘
```

- **ALB** receives all public HTTP traffic on port 80 and forwards it to the EC2
  instances.
- **Auto Scaling Group** runs the backend Docker container on Amazon Linux 2023
  instances. On first boot each instance installs Docker, pulls the image from
  ECR (using its IAM role — no stored credentials), and runs the container.
- **RDS** hosts the PostgreSQL database, reachable only from the EC2 instances.
- **ECR** stores the backend Docker image you push from your machine.
- **S3** stores user avatar uploads in a private, encrypted, versioned bucket.

Everything is deployed into the account's **default VPC** and its subnets.

## Layout

```
Infrastructure/
├── main.tf          # Shared data sources, SSH key, and module wiring
├── providers.tf     # AWS provider + default tags
├── terraform.tf     # Terraform & provider version constraints
├── variables.tf     # Root input variables
├── outputs.tf       # Outputs (app URL, DB endpoint, bucket, ECR URL)
└── modules/
    ├── security_groups/  # Firewalls for ALB, EC2, and RDS
    ├── alb/              # Load balancer, target group, listener
    ├── ecr/              # Container registry + image lifecycle policy
    ├── compute/          # IAM role, launch template, Auto Scaling Group
    ├── rds/              # PostgreSQL instance + subnet group
    └── s3/               # Private avatars bucket
```

The root `main.tf` reads shared AWS info (default VPC, subnets, latest AL2023 AMI,
account ID) once and passes it into the modules as plain values.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.2
- AWS CLI configured with credentials (`aws configure`)
- Docker (to build and push the backend image)
- An SSH key pair for the EC2 instances

## Configuration

### 1. Generate an SSH key pair

The launch template expects a public key at the path set by `public_key_path`
(default `./terraform-key.pem.pub`):

```bash
ssh-keygen -t rsa -b 4096 -f terraform-key.pem
# creates terraform-key.pem (private) and terraform-key.pem.pub (public)
```

### 2. Create `terraform.tfvars`

A few variables have no default and must be supplied. Create
`Infrastructure/terraform.tfvars`:

```hcl
my_ip       = "203.0.113.10/32"   # your public IP in CIDR — restricts SSH access
db_password = "change-me-strong"  # RDS master password
jwt_secret  = "change-me-secret"  # secret the app uses to sign JWTs
```

> `terraform.tfvars`, `*.pem`, and `*.pem.pub` contain secrets — keep them out of
> version control.

### Variables

| Variable | Description | Default |
|---|---|---|
| `aws_region` | Region to deploy into | `eu-central-1` |
| `ec2_instance_type` | EC2 instance type for the ASG | `t2.micro` |
| `public_key_path` | Path to your SSH public key | `./terraform-key.pem.pub` |
| `my_ip` | Your public IP in CIDR (SSH allowlist) | — (required) |
| `db_instance_class` | RDS instance class | `db.t3.micro` |
| `db_name` | Initial database name | `AWSgrocery` |
| `db_username` | RDS master username | `dbadmin` |
| `db_password` | RDS master password (sensitive) | — (required) |
| `jwt_secret` | JWT signing secret (sensitive) | — (required) |
| `asg_min_size` | Min instances in the ASG | `1` |
| `asg_max_size` | Max instances in the ASG | `3` |
| `asg_desired_capacity` | Desired instances in the ASG | `2` |

## Usage

### 1. Provision the infrastructure

```bash
cd Infrastructure
terraform init
terraform plan
terraform apply
```

This creates everything **including the empty ECR repository**. Note the
`ecr_repository_url` output.

### 2. Build and push the backend image

The EC2 instances pull `:latest` from ECR on boot, so the image must exist there:

```bash
# Log in to ECR (replace region/account from the ecr_repository_url output)
aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin <account_id>.dkr.ecr.eu-central-1.amazonaws.com

# Build, tag, and push (run from the repo root where the backend Dockerfile lives)
docker build -t grocery-backend ./backend
docker tag grocery-backend:latest <ecr_repository_url>:latest
docker push <ecr_repository_url>:latest
```

If you apply before the image exists, the instances will fail to start the
container — push the image, then let the ASG cycle the instances (or terminate
them so the ASG replaces them).

### 3. Open the app

```bash
terraform output alb_dns_name
```

Paste the URL into your browser.

## Outputs

| Output | Description |
|---|---|
| `alb_dns_name` | Public URL of the app (via the load balancer) |
| `rds_endpoint` | PostgreSQL connection endpoint (`host:port`) |
| `s3_bucket_name` | Name of the avatars bucket |
| `ecr_repository_url` | Where to push the backend Docker image |

## How the container gets its config

The compute module's launch template injects these environment variables into the
container at boot:

- `POSTGRES_URI` — built from the RDS endpoint, DB name, username, and password
- `JWT_SECRET_KEY` — from `jwt_secret`
- `DEPLOYMENT_ENV` — set to `aws`

The container runs with `--restart always` and maps host port 80 to container
port 80.

## Security notes

- **SSH** to the EC2 instances is restricted to `my_ip` only.
- **HTTP** to the instances is allowed only from the ALB's security group.
- **PostgreSQL** is reachable only from the EC2 security group; the database is
  not publicly accessible.
- **S3** blocks all public access and encrypts objects at rest (AES256).
- EC2 instances pull from ECR via an **IAM role** (`AmazonEC2ContainerRegistryReadOnly`),
  so no registry credentials are stored on the host.

## Teardown

```bash
terraform destroy
```

This config is tuned for development convenience: RDS uses `skip_final_snapshot`
and has deletion protection off, so `destroy` removes the database without a final
snapshot. S3 versioning is enabled — empty the bucket if `destroy` reports it is
not empty.
