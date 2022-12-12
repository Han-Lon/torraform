################
# EC2 INSTANCE #
################

# Pull the most recent Debian 11 AMI if none supplied by the user
data "aws_ami" "debian-official" {
  count       = var.ami_id == "ami-null" ? 1 : 0
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-11-amd64-*"]
  }

  owners = ["amazon"]
}

data "template_cloudinit_config" "ssm-agent-and-tor-userdata" {
  gzip = true
  base64_encode = true

  part {
    filename = "install-ssm-agent.sh"
    content_type = "text/x-shellscript"
    content = file("./install-ssm-agent.sh")
  }

  part {
    filename = "install-tor.sh"
    content_type = "text/x-shellscript"
    content = templatefile("../universal_scripts/install-tor-debian.sh", {
      INSTALL_ONIONSHARE=var.install_onionshare ? "true" : "false"
      SSH_HARDENING="true"
    })
  }
}

data "template_cloudinit_config" "tor-userdata-only" {
  gzip = true
  base64_encode = true

  part {
    filename = "install-tor.sh"
    content_type = "text/x-shellscript"
    content = templatefile("../universal_scripts/install-tor-debian.sh", {
      INSTALL_ONIONSHARE=var.install_onionshare ? "true" : "false"
      SSH_HARDENING="true"
    })
  }
}

resource "aws_key_pair" "torraform-key-pair" {
  count = var.PUBLIC_ssh_key == "ssh-rsa null" ? 0 : 1
  public_key = var.PUBLIC_ssh_key
  key_name = "torraform-ssh-key"
}

resource "aws_instance" "tor-instance" {
  ami           = var.ami_id == "ami-null" ? data.aws_ami.debian-official[0].image_id : var.ami_id
  instance_type = var.instance_type

  subnet_id = var.launch_basic_networking ? aws_subnet.tor-subnet[0].id : var.subnet_id

  vpc_security_group_ids = [aws_security_group.tor-instance-sg.id]

  iam_instance_profile = var.PUBLIC_ssh_key == "ssh-rsa null" ? aws_iam_instance_profile.session-manager-instance-profile[0].name : null

  key_name = var.PUBLIC_ssh_key == "ssh-rsa null" ? null : aws_key_pair.torraform-key-pair[0].key_name

  user_data_base64 = var.PUBLIC_ssh_key == "ssh-rsa null" ? data.template_cloudinit_config.ssm-agent-and-tor-userdata.rendered : data.template_cloudinit_config.tor-userdata-only.rendered

  tags = {
    Name = "tor-service-server"
  }


  # Best way to validate states of dependent variables per https://github.com/hashicorp/terraform/issues/25609#issuecomment-1136340278
  lifecycle {
    precondition {
      condition     = (var.launch_basic_networking && var.subnet_id == "null") || !var.launch_basic_networking
      error_message = "You set launch_basic_networking but also supplied custom subnet_id. Please either remove the subnet_id or set launch_basic_networking to false."
    }

    precondition {
      condition     = (!var.launch_basic_networking && var.subnet_id != "null") || var.launch_basic_networking
      error_message = "You set launch_basic_networking to false but didn't supply subnet_id. Please either set launch_basic_networking to true or supply pre-existing subnet IDs."
    }
  }

  depends_on = [aws_internet_gateway.tor-vpc-igw] # TF docs recommend explicit depends-on for IGWs https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
}

locals {
  output_message = var.PUBLIC_ssh_key == "ssh-rsa null" ? "Your EC2 instance will soon be reachable via AWS Session Manager (in the AWS console). Give it 5-10 minutes for the bootstrapping process to fully complete." : "Your EC2 instance will be reachable at IP address ${aws_instance.tor-instance.public_ip}. Give it 5-10 minutes for the bootstrapping process to fully complete."
}

output "instance-notification" {
  value = local.output_message
}