##############
# NETWORKING #
##############

resource "vultr_firewall_group" "tor-firewall" {
  description = "Lock down ingress traffic as much as possible"
}

resource "vultr_firewall_rule" "tor-firewall-ssh-rule" {
  firewall_group_id = vultr_firewall_group.tor-firewall.id
  protocol = "tcp"
  ip_type = "v4"
  subnet = var.allowed_ssh_ip
  subnet_size = var.allowed_ssh_ip == "0.0.0.0" ? "0" : "32"
  port = "22"
  notes = "Allow SSH from predefined IP"
}