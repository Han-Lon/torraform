terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~>2.24.0"
    }
  }
}

# Set credential as an environment variable DIGITALOCEAN_TOKEN
provider "digitalocean" {}