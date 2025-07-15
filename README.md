# AMI Builder

This project automates the creation of multi-distro Linux AMIs for AWS using Packer, with support for both standard and EKS (Kubernetes) builds. It includes pre-requisite and cleanup scripts, Ansible provisioning, and Jenkins CI/CD pipelines for scheduled and on-demand builds.

## Supported Distributions
- Amazon Linux 2: `amazon-linux-2`
- Amazon Linux 2023: `amazon-linux-2023`
- Red Hat Enterprise Linux 8: `rhel-8`
- Red Hat Enterprise Linux 9: `rhel-9`
- Rocky Linux 8: `rocky-8`
- Rocky Linux 9: `rocky-9`
- Ubuntu 22.04: `ubuntu-22`
- Ubuntu 24.04: `ubuntu-24`
- Amazon Linux 2 EKS: `amazon-linux-2-eks`
- Amazon Linux 2023 EKS: `amazon-linux-2023-eks`

## Supported Architectures
- x86_64
- arm64

## Supported Kubernetes Versions (EKS builds)

### Amazon Linux 2
- 1.29
- 1.30
- 1.31
- 1.32

### Amazon Linux 2023
- 1.29
- 1.30
- 1.31
- 1.32
- 1.33

## System Requirements
- **Packer** (>= 1.12)
- **Ansible**
- **AWS CLI**

## Usage Instructions

### 1. Configure AWS Credentials
Ensure your AWS credentials are available to Packer (via environment variables or instance profile).

### 2. Build AMIs Manually with Packer
```sh
packer init .
packer validate build.pkr.hcl
packer build -var 'distro=ubuntu-22' -var 'arch=x86_64' build.pkr.hcl
```
- Use `-var 'distro=...'` and `-var 'arch=...'` to select a specific build.
- For EKS builds, add `-var 'k8s_version=1.31'` (supports 1.27-1.34).
- Optional: `-var 'instance_type_override=...'` to use a custom instance type for faster builds.
- Optional: `-var 'enforce_imdsv2=true|false'` to control IMDSv2 enforcement (default: true).
- Optional: `-var 'enable_fips=true'` to enable FIPS mode for security compliance.

### 3. Jenkins CI/CD Pipelines
- **Jenkinsfile**: Builds all distros/architectures (matrix), scheduled every Monday at 1:00 AM UTC.
- Both pipelines allow manual selection of distros, architectures, and (for EKS) Kubernetes versions via Jenkins UI parameters.
- **Pipeline Parameters:**
  - `DISTRO`: Linux distribution to build
  - `ARCH`: CPU architecture
  - `K8S_VERSION`: Kubernetes version (EKS only)
  - `ENABLE_FIPS`: Enable FIPS mode for security compliance
  - `ENFORCE_IMDSV2`: Enforce IMDSv2 for enhanced security
  - `INSTANCE_TYPE_OVERRIDE`: Override instance type for performance
  - `PARALLEL_BUILDS`: Enable parallel builds for faster execution
- Build history is limited to the 10 most recent builds.

### 4. Manifest Output
After each build, a `manifest.json` file is generated with metadata including distro name and architecture.

### 5. Adding Pipelines to Jenkins
Use the provided Python script to create Jenkins jobs:
```sh
pip install python-jenkins
python add_jenkins_pipelines.py --jenkins-url <URL> --username <USER> --api-token <TOKEN> [--repo-url <REPO_URL>]
```
- The script supports CLI options and environment variables for Jenkins URL, username, API token, and repository URL.

### 6. Enhanced Security & Speed Features
- **IMDSv2 enforcement**: Enabled by default for all builds for improved instance metadata security.
- **FIPS mode**: Optional, for compliance builds.
- **Instance type override**: Use larger/faster instances for speed.
- **Enhanced cleanup**: `scripts/cleanup.sh` performs deep log, cache, and temp file cleanup for security.
- **Pre-requisite script**: `scripts/prerequisites.sh` handles distro-specific setup.
- **Workspace RHEL setup**: `scripts/workspace-rhel-setup.sh` installs Amazon Workspaces requirements for RHEL 8/9.

---

For more details, see the comments in each file.