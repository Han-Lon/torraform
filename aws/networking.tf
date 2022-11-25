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