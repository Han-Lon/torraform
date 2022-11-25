variable "allowed_ssh_ip" {
  description = "Public IP address to allow SSH traffic from. Set to 0.0.0.0 to allow all traffic."
  type = string
  default = "x.x.x.x"
}

# Check out Onionshare at https://docs.onionshare.org/2.6/en/advanced.html#cli
variable "install_onionshare" {
  description = "Whether or not to install the Onionshare utility for quick and easy setup of a variety of Tor hidden services. Defaults to true (yes install)"
  type = bool
  default = true
}

variable "PUBLIC_ssh_key" {
  description = "The PUBLIC key for the SSH keypair you want to use to access the instance."
  type = string

  validation {
    condition = can(regex("^ssh-rsa *", var.PUBLIC_ssh_key))
    error_message = "Supplied public SSH key value is either invalid format (should start with ssh-rsa) OR is the private key."
  }
}

variable "vultr_region" {
  description = "Region within Vultr to install the Tor server to. Defaults to 'ewr' (New Jersey)"
  type = string
  default = "ewr"
}