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

###################
# SESSION MANAGER #
###################
data "aws_iam_policy_document" "session-manager-json" {
  statement {
    sid = "SSMstuff"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      values   = ["tor-service-server"]
      variable = "tag:Name"
    }
  }
}

resource "aws_iam_policy" "session-manager-policy" {
  count  = var.ec2_key_pair == " null " ? 1 : 0
  policy = data.aws_iam_policy_document.session-manager-json.json
  name   = "tor-server-ssm-policy"
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
  policy_arn = aws_iam_policy.session-manager-policy[0].arn
  role       = aws_iam_role.session-manager-role[0].arn
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
    content_type = "text/part-handler"
    content = file("./install-ssm-agent.sh")
  }

  part {
    filename = "install-tor.sh"
    content_type = "text/part-handler"
    content = file("../universal_scripts/install-tor-debian.sh")
  }
}

resource "aws_instance" "tor-instance" {
  ami           = var.ami_id == "ami-null" ? data.aws_ami.debian-official[0].image_id : var.ami_id
  instance_type = "t3.micro"

  subnet_id = var.launch_basic_networking ? aws_subnet.tor-subnet[0].id : var.subnet_id

  iam_instance_profile = var.ec2_key_pair == " null " ? aws_iam_instance_profile.session-manager-instance-profile[0].arn : null

  key_name = var.ec2_key_pair != " null " ? var.ec2_key_pair : null

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