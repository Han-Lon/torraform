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


######################
# BOOTSTRAPPING VARS #
######################

# Check out Onionshare at https://docs.onionshare.org/2.6/en/advanced.html#cli
variable "install_onionshare" {
  description = "Whether or not to install the Onionshare utility for quick and easy setup of a variety of Tor hidden services. Defaults to true (yes install)"
  type = bool
  default = true
}