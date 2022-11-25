data "vultr_os" "debian-os" {
  filter {
    name   = "name"
    values = ["Debian 11 x64 (bullseye)"]
  }
}

# By default, get the cheapest plan
data "vultr_plan" "vultr-plan" {
  filter {
    name   = "id"
    values = ["vc2-1c-1gb"]
  }
}

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

resource "vultr_startup_script" "install-tor-script" {
  name   = "install-tor-script"
  script = base64encode(templatefile("../universal_scripts/install-tor-debian.sh", {
      INSTALL_ONIONSHARE=var.install_onionshare,
      SSH_HARDENING=true
      }
    )
  )
}

resource "vultr_ssh_key" "tor-ssh-key" {
  name    = "tor-server-ssh-key"
  ssh_key = var.PUBLIC_ssh_key
}

resource "vultr_instance" "tor-server" {
  plan = data.vultr_plan.vultr-plan.id
  region = var.vultr_region
  os_id = data.vultr_os.debian-os.id
  label = "tor-hidden-service"
  tags = ["tor-hidden-service-server"]
  hostname = "tor-hidden-service-server"
  enable_ipv6 = false
  backups = "disabled"
  activation_email = false
  ddos_protection = false
  script_id = vultr_startup_script.install-tor-script.id
  ssh_key_ids = [vultr_ssh_key.tor-ssh-key.id]
  firewall_group_id = vultr_firewall_group.tor-firewall.id
}