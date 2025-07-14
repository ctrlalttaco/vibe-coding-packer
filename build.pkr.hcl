packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "prefix" {
  type    = string
  default = "test"
}

variable "enable_fips" {
  type    = bool
  default = false
}

variable "distro" {
  type        = string
  default     = ""
  description = "If set, only build the specified distro (name from locals.source_distros). Otherwise, build all."
}

variable "arch" {
  type        = string
  default     = "x86_64"
  description = "CPU architecture: x86_64 or arm64"
}

variable "k8s_version" {
  type        = string
  default     = ""
  description = "Kubernetes version for EKS builds (e.g., 1.29, 1.30, ...). Ignored for non-EKS builds."
}

locals {
  source_distros = [
    {
      name                = "ubuntu-22"
      source_ami_name     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*-server-*"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ubuntu"
    },
    {
      name                = "ubuntu-24"
      source_ami_name     = "ubuntu/images/hvm-ssd/ubuntu-noble-24.04-*-server-*"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ubuntu"
    },
    {
      name                = "rhel-8"
      source_ami_name     = "RHEL-8*_HVM-*"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ec2-user"
    },
    {
      name                = "rhel-9"
      source_ami_name     = "RHEL-9*_HVM-*"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ec2-user"
    },
    {
      name                = "amazon-linux-2"
      source_ami_name     = "amzn2-ami-hvm-2.*-*-gp2"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ec2-user"
    },
    {
      name                = "amazon-linux-2023"
      source_ami_name     = "al2023-ami-*-*"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ec2-user"
    },
    {
      name                = "rocky-8"
      source_ami_name     = "Rocky-8-EC2-*-*"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ec2-user"
    },
    {
      name                = "rocky-9"
      source_ami_name     = "Rocky-9-EC2-*-*"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ec2-user"
    },
    {
      name                = "amazon-linux-2-eks"
      source_ami_name     = "amazon-eks-node-2*-*"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ec2-user"
      eks                 = true
    },
    {
      name                = "amazon-linux-2023-eks"
      source_ami_name     = "amazon-eks-node-2023*-*"
      source_ami_owners   = ["amazon"]
      ssh_username        = "ec2-user"
      eks                 = true
    }
  ]

  # Filter by distro if specified
  filtered_distros = [for d in local.source_distros : d if var.distro == "" || d.name == var.distro]
  filtered_eks     = [for d in local.filtered_distros : d if !lookup(d, "eks", false) && var.k8s_version != ""]
  distros          = [for d in local.filtered_eks : {
    name              = d.name
    source_ami_name   = d.source_ami_name
    source_ami_owners = d.source_ami_owners
    ssh_username      = d.ssh_username
    arch              = var.arch
    eks               = lookup(d, "eks", false)
    k8s_version       = var.k8s_version
  }]
}

source "amazon-ebs" "linux" {
  region        = var.aws_region
  instance_type = var.arch == "arm64" ? "t4g.large" : "t3.large"
}

build {
  dynamic "source" {
    for_each = { for d in local.distros : d.eks ? "${d.name}-${d.arch}-${d.k8s_version}" : "${d.name}-${d.arch}" => d }
    labels   = ["amazon-ebs.linux"]
    
    content {
      name          = source.value.name
      ssh_username  = source.value.ssh_username
      ami_name      = source.value.eks ? "${var.prefix}-${source.value.name}-${source.value.arch}-${source.value.k8s_version}-{{timestamp}}" : "${var.prefix}-${source.value.name}-${source.value.arch}-{{timestamp}}"
    
      source_ami_filter {
        filters = {
          name                = source.value.source_ami_name
          root-device-type    = "ebs"
          virtualization-type = "hvm"
          architecture        = source.value.arch
        }
        owners      = source.value.source_ami_owners
        most_recent = true
      }
    }
  }

  provisioner "shell" {
    script = "scripts/prerequisites.sh"
  }

  provisioner "ansible" {
    playbook_file = "playbooks/playbook.yml"
    extra_arguments = [
      "-e", "enable_fips=${var.enable_fips}"
    ]
    groups = [source.name]
  }

  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      version_fingerprint = "${packer.versionFingerprint}"
      iteration = "${packer.iterationID}"
      ami_name = "{source.ami_name}"
    }
  }
}
