##############
# NETWORKING #
##############
resource "aws_vpc" "tor-vpc" {
  count      = var.launch_basic_networking ? 1 : 0
  cidr_block = "10.180.0.0/16"

  tags = {
    Name = "tor-service-vpc"
  }
}

resource "aws_subnet" "tor-subnet" {
  count      = var.launch_basic_networking ? 1 : 0
  cidr_block = "10.180.0.0/24"
  vpc_id     = aws_vpc.tor-vpc[0].id
  map_public_ip_on_launch = true

  tags = {
    Name = "tor-service-public-subnet"
  }
}

resource "aws_internet_gateway" "tor-vpc-igw" {
  count  = var.launch_basic_networking ? 1 : 0
  vpc_id = aws_vpc.tor-vpc[0].id

  tags = {
    Name = "tor-internet-gateway"
  }
}

resource "aws_default_route_table" "tor-subnet-route-table" {
  count                  = var.launch_basic_networking ? 1 : 0
  default_route_table_id = aws_vpc.tor-vpc[0].default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tor-vpc-igw[0].id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.tor-vpc-igw[0].id
  }

  tags = {
    Name = "tor-default-rtb"
  }
}

# We need to retrieve info on the custom user subnet if launch_basic_networking is false
data "aws_subnet" "custom-user-subnet" {
  count = var.launch_basic_networking ? 0 : 1
  id = var.subnet_id
}

###################
# SESSION MANAGER #
###################
data "aws_iam_policy" "ssm-managed-instance-policy" {
  count = var.ec2_key_pair == " null " ? 1 : 0
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "session-manager-role" {
  count              = var.ec2_key_pair == " null " ? 1 : 0
  name               = "tor-server-ssm-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "session-manager-policy-attach" {
  count      = var.ec2_key_pair == " null " ? 1 : 0
  policy_arn = data.aws_iam_policy.ssm-managed-instance-policy[0].arn
  role       = aws_iam_role.session-manager-role[0].name
}

resource "aws_iam_instance_profile" "session-manager-instance-profile" {
  count = var.ec2_key_pair == " null " ? 1 : 0
  role  = aws_iam_role.session-manager-role[0].name
  name  = "session-manager-instance-profile"
}


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


##################
# SECURITY GROUP #
##################

resource "aws_security_group" "tor-instance-sg" {
  name = "tor-service-security-group"
  description = "For the tor EC2 instance. Keep inbound rules to an absolute minimum"
  vpc_id = var.launch_basic_networking ? aws_vpc.tor-vpc[0].id : data.aws_subnet.custom-user-subnet[0].vpc_id
}

# We'll need outbound access no matter what for things like software updates and Tor's outbound connection protocol
resource "aws_security_group_rule" "tor-instance-sg-outbound" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.tor-instance-sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}

# Only create the inbound SSH rule if we're setting a key pair, meaning SSH is required
resource "aws_security_group_rule" "tor-instance-sg-inbound" {
  count = var.ec2_key_pair == " null " ? 0 : 1
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.tor-instance-sg.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks = var.allowed_ssh_ip == "0.0.0.0" ? ["${var.allowed_ssh_ip}/0"] : ["${var.allowed_ssh_ip}/32"]

  lifecycle {
    precondition {
      condition     = var.ec2_key_pair != " null " && var.allowed_ssh_ip != "x.x.x.x"
      error_message = "If you specify an EC2 key pair, you must also specify an allowed_ssh_ip with a public IP address that will be allowed to SSH into this instance."
    }
  }
}