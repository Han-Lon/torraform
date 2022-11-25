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