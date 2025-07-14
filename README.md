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
- For EKS builds, add `-var 'k8s_version=1.31'`.

### 3. Jenkins CI/CD Pipelines
- **Jenkinsfile**: Builds all standard distros/architectures (matrix), scheduled every Monday at 1:00 AM UTC.
- **Jenkinsfile-EKS**: Builds all EKS distros/architectures/Kubernetes versions (matrix), scheduled every Monday at 1:00 AM UTC.
- Both pipelines allow manual selection of distros, architectures, and (for EKS) Kubernetes versions via Jenkins UI parameters.
- Build history is limited to the 10 most recent builds.

### 4. Manifest Output
After each build, a `manifest.json` file is generated with metadata including distro name and architecture.

### 5. Adding Pipelines to Jenkins
Use the provided Python script to create Jenkins jobs:
```sh
pip install python-jenkins
python add_jenkins_pipelines.py --jenkins-url <URL> --username <USER> --api-token <TOKEN>
```

---

For more details, see the comments in each file.