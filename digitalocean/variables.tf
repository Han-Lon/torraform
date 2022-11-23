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

variable "lock_down_firewall" {
  description = "Whether or not to automatically lock down the droplet's firewall to only allow SSH from the local IP address (fetched automatically). Note you can set this yourself via the Digital Ocean console"
  default = true
  type = bool
}

variable "droplet_project" {
  description = "Whether to launch into a specific project or not. If left blank, a dedicated tor-service project will be created."
  default = ""
  type = string
}