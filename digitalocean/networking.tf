##############
# NETWORKING #
##############

# Firewall to apply to the tor droplet
resource "digitalocean_firewall" "tor-droplet-firewall" {
  name = "tor-droplet-only-22"

  droplet_ids = [digitalocean_droplet.tor-droplet.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_ip == "0.0.0.0" ? ["0.0.0.0/0"] : ["${var.allowed_ssh_ip}/32"]
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