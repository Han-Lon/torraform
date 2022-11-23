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

# Pick latest Centos 8 image if droplet_image variable is not set
data "digitalocean_image" "centos-image" {
  count = var.droplet_image == "" ? 1 : 0
  slug = "centos-stream-8-x64"
}

# Fetch local IP address for adding to firewall SSH rules only if lock_down_firewall is set to true
data "http" "local-ip" {
  count = var.lock_down_firewall ? 1 : 0
  url = "https://ipv4.rawrify.com/ip"
}

resource "digitalocean_droplet" "tor-droplet" {
  image  = var.droplet_image == "" ? data.digitalocean_image.centos-image[0].slug : var.droplet_image
  name   = "tor-hidden-service-server"
  region = var.droplet_region
  size   = var.droplet_size == "" ? data.digitalocean_sizes.droplet_size[0].sizes[0].slug : var.droplet_size
  user_data = file("../universal_scripts/install-tor-centos.sh")
}

# Firewall to apply to the tor droplet
resource "digitalocean_firewall" "tor-droplet-firewall" {
  name = "tor-droplet-only-22"

  droplet_ids = [digitalocean_droplet.tor-droplet.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.lock_down_firewall ? ["${data.http.local-ip[0].body}/32"] : ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_project" "tor-project" {
  count = var.droplet_project == "" ? 1 : 0
  name = "tor-hidden-service-project"
  description = "Contains the droplets and associated resources for a functional Tor hidden service"
  purpose = "Tor Hidden Service"
  resources = [digitalocean_droplet.tor-droplet.urn]
}

data "digitalocean_project" "existing-project" {
  count = var.droplet_project != "" ? 1 : 0
  name = var.droplet_project
}

resource "digitalocean_project_resources" "add-resources-to-existing-project" {
  count = var.droplet_project != "" ? 1 : 0
  project   = data.digitalocean_project.existing-project[0].id
  resources = [digitalocean_droplet.tor-droplet.urn]
}