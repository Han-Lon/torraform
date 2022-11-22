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

# Nice trick to ensure we have a reliable "null" string for evaluating this -- EC2 key pairs cannot have leading or trailing spaces, so there could never be a legit keypair named " null "
variable "ec2_key_pair" {
  description = "The name of the EC2 SSH key pair to assign to the Tor server for shell access. If left as null, Systems Manager will be used instead for SSH-less access."
  type        = string
  default     = " null "
}