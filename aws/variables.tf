############################
# ACCESS RELATED VARIABLES #
############################
variable "allowed_ssh_ip" {
  description = "Public IP address to allow SSH traffic from. Only needed if ec2_key_pair is set to a non-null value"
  type = string
  default = "x.x.x.x"
}

variable "PUBLIC_ssh_key" {
  description = "The PUBLIC key for the SSH keypair you want to use to access the instance."
  type = string
  default = "ssh-rsa null"

  validation {
    condition = can(regex("^ssh-rsa *", var.PUBLIC_ssh_key))
    error_message = "Supplied public SSH key value is either invalid format (should start with ssh-rsa) OR is the private key."
  }
}


#######################################
# AWS CUSTOM INFRASTRUCTURE VARIABLES #
#######################################
variable "ami_id" {
  description = "The ID of the AMI to use when launching the Tor server. Can be left empty for default debian-11"
  type        = string
  default     = "ami-null"

  validation {
    condition     = can(regex("^ami-[0-9a-z]+$", var.ami_id))
    error_message = "For ami_id, please ensure the supplied ID conforms to the ami-asdf123 pattern."
  }
}

variable "instance_type" {
  description = "The EC2 instance type (compute+memory resources) to allocate for the Tor server. Defaults to t3.micro, which is pretty cheap but effective for small to medium workloads."
  type = string
  default = "t3.micro"
}

variable "launch_basic_networking" {
  description = "Whether or not to launch a basic network setup within this module. If false, you will have to supply a subnet_id value."
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "If launch_basic_networking is false, supply subnet IDs of the pre-existing subnets the Tor EC2 instance should be launched into"
  type        = string
  default     = "null"
}


#####################
# EC2 INSTANCE VARS #
#####################

# Looking for more info on how this can be set? https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_alias
variable "kms_key_identifier" {
  description = "The valid identifier (ARN, alias, or ID) of the KMS key that should be used to encrypt the EBS volume associated with the Tor server. Defaults to alias/aws/kms"
  type = string
  default = "alias/aws/ebs"
}


######################
# BOOTSTRAPPING VARS #
######################

# Check out Onionshare at https://docs.onionshare.org/2.6/en/advanced.html#cli
variable "install_onionshare" {
  description = "Whether or not to install the Onionshare utility for quick and easy setup of a variety of Tor hidden services. Defaults to true (yes install)"
  type = bool
  default = true
}