########################
# DigitalOcean Droplet #
########################

# Pick the cheapest droplet size in the desired DO region if droplet_size variable is not set
data "digitalocean_sizes" "droplet_size" {
  count = var.droplet_size == "" ? 1 : 0

  filter {
    key    = "regions"
    values = [var.droplet_region]
  }

  sort {
    key = "price_monthly"
    direction = "asc"
  }
}

data "digitalocean_image" "debian-image" {
  count = var.droplet_image == "" ? 1 : 0
  slug = "debian-11-x64"
}

resource "digitalocean_ssh_key" "tor-server-ssh-key" {
  name       = "tor-server-ssh-key"
  public_key = var.PUBLIC_ssh_key
}

resource "digitalocean_droplet" "tor-droplet" {
  image  = var.droplet_image == "" ? data.digitalocean_image.debian-image[0].slug : var.droplet_image
  name   = "tor-hidden-service-server"
  region = var.droplet_region
  size   = var.droplet_size == "" ? data.digitalocean_sizes.droplet_size[0].sizes[0].slug : var.droplet_size
  user_data = templatefile("../universal_scripts/install-tor-debian.sh", {
    INSTALL_ONIONSHARE=var.install_onionshare,
    SSH_HARDENING=true
  })
  ssh_keys = [digitalocean_ssh_key.tor-server-ssh-key.fingerprint]
}