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

variable "aws_regions" {
  type    = list(string)
  default = ["us-east-1", "us-west-2"]
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
  description = "Kubernetes version for EKS builds"
}

variable "instance_type_override" {
  type        = string
  default     = ""
  description = "Override instance type"
}

variable "enforce_imdsv2" {
  type        = bool
  default     = true
  description = "Enforce IMDSv2 for enhanced security"
}

variable "source_distros" {
  type = list(object({
    name = string
    source_ami_name = string
    source_ami_owners = list(string)
    ssh_username = string
  }))
  default = [
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
      name                = "rhel-8-ws"
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
      name                = "rhel-9-ws"
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
      name                = "rocky-8-ws"
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
      name                = "rocky-9-ws"
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
}
locals {

  # Filter by distro if specified
  filtered_distros = [for d in var.source_distros : d if var.distro == "" || d.name == var.distro]
  filtered_eks     = [for d in local.filtered_distros : d if lookup(d, "eks", false) && var.k8s_version != ""]
  distros          = [for d in local.filtered_eks : {
    name              = d.name
    source_ami_name   = d.source_ami_name
    source_ami_owners = d.source_ami_owners
    ssh_username      = d.ssh_username
    arch              = var.arch
    eks               = lookup(d, "eks", false)
    k8s_version       = var.k8s_version
  }]

  # Speed optimization: Use larger, faster instances
  optimized_instance_type = var.instance_type_override != "" ? var.instance_type_override : (
    var.arch == "arm64" ? "c6g.xlarge" : "c5.xlarge"
  )
}

source "amazon-ebs" "linux" {
  region        = var.aws_region
  instance_type = local.optimized_instance_type
  spot_price    = "auto"
  spot_price_auto_product = "Linux/UNIX"
  ssh_handshake_attempts = 100
  ssh_timeout = "10m"
  ebs_optimized = true
  volume_type = "gp3"
  volume_size = 30
  iops = 3000
  throughput = 125
  shutdown_behavior = "terminate"
  
  tags = {
    Name        = "${var.prefix}-${source.name}-${source.arch}"
    Environment = "production" # TODO: Make this a variable
    Project     = "ami-builder" # TODO: Make this a variable
    Distro      = source.name
    Architecture = source.arch
    BuildDate   = formatdate("YYYY-MM-DD", timestamp())
    PackerBuild = "true"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = var.enforce_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 1
    instance_metadata_tags = "enabled"
  }
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
        owners      = source.value.source_ami_owners
        most_recent = true
        filters = {
          name                = source.value.source_ami_name
          root-device-type    = "ebs"
          virtualization-type = "hvm"
          architecture        = source.value.arch
          creation-date       = "*"
        }
      }
    }
  }

  provisioner "shell" {
    script = "scripts/prerequisites.sh"
  }

  provisioner "ansible" {
    playbook_file = "ansible/playbook.yml"
    extra_arguments = [
      "-e", "enable_fips=${var.enable_fips}",
      # Speed optimization: Use more forks for parallel execution
      "--forks=4",
      # Speed optimization: Use pipelining
      "--pipelining",
      # Speed optimization: Reduce gathering
      "--gathering=smart"
    ]
    groups = [source.name]
    # Speed optimization: Use SSH pipelining
    use_proxy = false
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_SSH_PIPELINING=True",
      "ANSIBLE_STDOUT_CALLBACK=yaml"
    ]
  }

  provisioner "shell" {
    only   = ["rhel-8-ws", "rhel-9-ws", "rocky-8-ws", "rocky-9-ws"]
    script = "scripts/workspace-rhel-setup.sh"
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
      ami_name = "${source.ami_name}"
      build_timestamp = "${formatdate("YYYY-MM-DD HH:mm:ss", timestamp())}"
      build_duration = "${formatdate("s", timestamp())}"
      distro = "${source.name}"
      architecture = "${source.arch}"
      fips_enabled = "${var.enable_fips}"
      imdsv2_enforced = "${var.enforce_imdsv2}"
    }
  }
}