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
  count = var.ec2_key_pair == " null " ? 1 : 0
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
      INSTALL_ONIONSHARE=var.install_onionshare
    })
  }
}

data "template_cloudinit_config" "tor-userdata-only" {
  count = var.ec2_key_pair == " null " ? 0 : 1
  gzip = true
  base64_encode = true

  part {
    filename = "install-tor.sh"
    content_type = "text/x-shellscript"
    content = templatefile("../universal_scripts/install-tor-debian.sh", {
      INSTALL_ONIONSHARE=var.install_onionshare
    })
  }
}

resource "aws_instance" "tor-instance" {
  ami           = var.ami_id == "ami-null" ? data.aws_ami.debian-official[0].image_id : var.ami_id
  instance_type = "t3.micro"

  subnet_id = var.launch_basic_networking ? aws_subnet.tor-subnet[0].id : var.subnet_id

  security_groups = [aws_security_group.tor-instance-sg.id]

  iam_instance_profile = var.ec2_key_pair == " null " ? aws_iam_instance_profile.session-manager-instance-profile[0].name : null

  key_name = var.ec2_key_pair != " null " ? var.ec2_key_pair : null

  user_data_base64 = var.ec2_key_pair == " null " ? data.template_cloudinit_config.ssm-agent-and-tor-userdata[0].rendered : data.template_cloudinit_config.tor-userdata-only[0].rendered

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