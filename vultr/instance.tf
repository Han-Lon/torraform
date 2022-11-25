data "vultr_os" "debian-os" {
  filter {
    name   = "name"
    values = [var.vultr_os_name]
  }
}

# By default, get the cheapest plan
data "vultr_plan" "vultr-plan" {
  filter {
    name   = "id"
    values = [var.vultr_plan_name]
  }
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