variable "droplet_image" {
  description = "Specific droplet image to use. Defaults to Centos 8 if none specified."
  type = string
  default = ""
}

variable "droplet_size" {
  description = "Droplet size to use. Defaults to cheapest size in the specified var.droplet_region region. Please note DO sometimes does not have enough capacity in a specific region to fulfill specific size requests."
  type = string
  default = ""
}

variable "droplet_region" {
  description = "DO region to launch the droplet in. Defaults to nyc1 if none specified."
  type = string
  default = "nyc1"
}

variable "droplet_project" {
  description = "Whether to launch into a specific project or not. If left blank, a dedicated tor-service project will be created."
  default = ""
  type = string
}

variable "allowed_ssh_ip" {
  description = "Public IP address to allow SSH traffic from. Set to 0.0.0.0 to allow all traffic."
  type = string
  default = "x.x.x.x"
}

variable "PUBLIC_ssh_key" {
  description = "The PUBLIC key for the SSH keypair you want to use to access the instance."
  type = string

  validation {
    condition = can(regex("^ssh-rsa *", var.PUBLIC_ssh_key))
    error_message = "Supplied public SSH key value is either invalid format (should start with ssh-rsa) OR is the private key."
  }
}

# Check out Onionshare at https://docs.onionshare.org/2.6/en/advanced.html#cli
variable "install_onionshare" {
  description = "Whether or not to install the Onionshare utility for quick and easy setup of a variety of Tor hidden services. Defaults to true (yes install)"
  type = bool
  default = true
}