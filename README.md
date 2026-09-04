# NimbusGuard IaC Scanning — Demo

A deliberately **insecure** Infrastructure-as-Code repository that shows
NimbusGuard's *shift-left* scanning in action: every pull request (and every
push to `main`) is evaluated against NimbusGuard's **real control catalog** —
the same one it uses to scan running cloud accounts — **before any of this is
ever deployed**.

> ⚠️ **Nothing in this repo is applied to any cloud account.** These are
> Terraform / CloudFormation / Bicep *source files*, scanned as text. Every
> resource is misconfigured on purpose so the scanner has something to catch.

## What's in here

| Path | Format | What it demonstrates |
|------|--------|----------------------|
| [`terraform/aws.tf`](terraform/aws.tf) | Terraform (AWS) | Public S3 bucket, SSH open to `0.0.0.0/0`, public + unencrypted RDS, KMS without rotation, CloudTrail not logging, admin IAM role, weak password policy, unencrypted SNS/SQS/EFS/EBS, mutable ECR, … |
| [`terraform/azure.tf`](terraform/azure.tf) | Terraform (Azure) | Key Vault without purge protection, public Redis with TLS 1.0, ACR with anonymous pull, public Cosmos DB / PostgreSQL, … |
| [`cloudformation/app-stack.yaml`](cloudformation/app-stack.yaml) | CloudFormation | Public bucket, RDP open to the world, key without rotation, unencrypted RDS, admin role, … |
| [`bicep/main.bicep`](bicep/main.bicep) | Bicep | Public blob storage over HTTP, NSG allowing SSH from anywhere, weak Key Vault |

Each file also includes a few **hardened** resources that **pass** — NimbusGuard
blesses good IaC too, so a clean change isn't blocked, and the report shows what
"right" looks like.

## How the scan runs

[`.github/workflows/nimbus-iac-scan.yml`](.github/workflows/nimbus-iac-scan.yml)
runs the [`NimbusGuard/nimbus-iac-scanner`](https://github.com/NimbusGuard/nimbus-iac-scanner)
GitHub Action on every PR and push. The action:

1. Parses the Terraform / CloudFormation / Bicep source.
2. Sends each resource to NimbusGuard's `POST /iac/gate-check` endpoint,
   authenticated with a **service-account API key** (never a cloud credential).
3. Fails the check (exit `1`) on any real misconfiguration, and posts a comment
   on the PR listing exactly which controls failed — with the same
   `NG-AWS-*` / `NG-AZURE-*` control ID it would trip at runtime.
4. Records the run in the NimbusGuard platform, where every scan and finding is
   tracked over time with a full lifecycle (a finding **auto-resolves** when a
   later scan no longer reproduces it — e.g. the misconfiguration was fixed or
   the file deleted).

Two repository secrets drive it:

- `NIMBUS_API_URL` — the NimbusGuard API base URL (e.g. `https://api.nimbusguard.io/v1`).
- `NIMBUS_API_KEY` — a NimbusGuard service-account API key with `view_findings`.

## Try it

Open a pull request that adds a new misconfigured resource (say, another public
bucket). The check turns red and a comment appears listing the control it
tripped — before the resource could ever reach a cloud account. Fix it, and the
next scan passes and the finding auto-resolves in the platform.

## Not covered (yet)

The scanner maps a curated — not exhaustive — set of resource types per format.
A resource type it doesn't recognize is **silently skipped** (never guessed as
passing), and a field it can't determine statically is reported as
`NOT_EVALUATED`, not a fabricated verdict.
