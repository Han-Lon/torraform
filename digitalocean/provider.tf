terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~>2.24.0"
    }
  }
}

provider "digitalocean" {}