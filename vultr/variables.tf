############################
# ACCESS RELATED VARIABLES #
############################
# You only really have to set allowed_ssh_ip and PUBLIC_ssh_key
variable "allowed_ssh_ip" {
  description = "Public IP address to allow SSH traffic from. Set to 0.0.0.0 to allow all traffic."
  type = string
}

variable "PUBLIC_ssh_key" {
  description = "The PUBLIC key for the SSH keypair you want to use to access the instance."
  type = string

  validation {
    condition = can(regex("^ssh-rsa *", var.PUBLIC_ssh_key))
    error_message = "Supplied public SSH key value is either invalid format (should start with ssh-rsa) OR is the private key."
  }
}


############################
# VULTR INSTANCE VARIABLES #
############################
variable "vultr_os_name" {
  description = "The name of the specific OS to use on Vultr instead of the default Debian 11."
  type = string
  default = "Debian 11 x64 (bullseye)"
}

variable "vultr_plan_name" {
  description = "The name of the specific plan type to use for the instance. Defaults to 'vc2-1c-1gb', the smallest."
  type = string
  default = "vc2-1c-1gb"
}

variable "vultr_region" {
  description = "Region within Vultr to install the Tor server to. Defaults to 'ewr' (New Jersey)"
  type = string
  default = "ewr"
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