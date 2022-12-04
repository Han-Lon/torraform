###################
# SESSION MANAGER #
###################
data "aws_iam_policy" "ssm-managed-instance-policy" {
   count = var.PUBLIC_ssh_key == "ssh-rsa null" ? 1 : 0
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "session-manager-role" {
   count = var.PUBLIC_ssh_key == "ssh-rsa null" ? 1 : 0
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
   count = var.PUBLIC_ssh_key == "ssh-rsa null" ? 1 : 0
  policy_arn = data.aws_iam_policy.ssm-managed-instance-policy[0].arn
  role       = aws_iam_role.session-manager-role[0].name
}

resource "aws_iam_instance_profile" "session-manager-instance-profile" {
   count = var.PUBLIC_ssh_key == "ssh-rsa null" ? 1 : 0
  role  = aws_iam_role.session-manager-role[0].name
  name  = "session-manager-instance-profile"
}