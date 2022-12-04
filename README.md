# torraform
A fast way to experiment with [Tor onion services.](https://tb-manual.torproject.org/onion-services/)

### DISCLAIMER
DON'T DO ANYTHING ILLEGAL WITH THIS PROJECT. While this project implements basic hardening and security principles, 
it's by no means secure enough for a high risk environment. You will most likely get caught if you engage in illegal activities with this. <br>
Please check your country's laws regarding Tor-- while running Tor itself is not illegal in nations such as the U.S., other countries with strong censorship laws may explicitly ban it.

### Table of Contents
- [Setup](#setup)
  - [Prerequisites](#prerequisites)
  - [AWS Deployment with Minimal Configuration](#aws-deployment-minimal-configuration)
  - [Digital Ocean Deployment with Minimal Configuration](#digital-ocean-deployment-minimal-configuration)
  - [Vultr Deployment with Minimal Configuration](#vultr-deployment-minimal-configuration)
- [Onionshare Use](#onionshare-use)
- [Tor Onion Service Direct Configuration (Advanced)](#manual-tor-onion-service-configuration-advanced)

### Important Files [IMPORTANT]
- Throughout using this project, you will generate several important files that **must** be kept safe and secure
- [Local] Your local **private** SSH key, if using the SSH connection method. Anyone with the private key will be able to access your Tor server's administrative shell
- [Local] Terraform state files-- these files are basically how Terraform "remembers" what resource it has built. These files end in `.tfstate` and `.tfstate.backup`
  - It's not the end of the world if this file is deleted-- the code for each cloud provider is set up to use minimal resources. Deleting the instance within the cloud provider's web console should remove the only cost-generating resource
  - [Advanced] It's a Terraform best-practice to store state in a remote backend to ensure safe and durable storage. Check out [this page](https://developer.hashicorp.com/terraform/language/settings/backends/configuration#available-backends) for how to implement this
    - Note that your state file contains information about your Tor server, such as its public IP address. Take this into account when picking a secure state backend
- [On Server] Tor onion service keys
  - These are really only a concern if you don't use [Onionshare](#onionshare-use) (which installs by default, so skip this if you don't plan on changing it)
  - These keys are located in your /var/lib/tor/<RANDOM_STRING> directory-- everything except the `hostname` file should be closely guarded and highly secure
    - If the private key files in this directory are leaked, anyone with the keys can impersonate your onion service

### Setup
#### Prerequisites
- Install [Terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) or set up [Terraform Cloud](https://cloud.hashicorp.com/products/terraform)
- Set up an account with [AWS](https://aws.amazon.com/), [Digital Ocean](https://www.digitalocean.com/), or [Vultr](https://www.vultr.com/), depending on where you want to deploy your Tor server
- (Windows only) Install and configure [WSL](https://learn.microsoft.com/en-us/windows/wsl/install#install-wsl-command) on your local system. You will need this for SSH operations
- Create a `tor.tfvars` file in the same folder as this README file.

#### AWS Deployment (Minimal Configuration)
- The AWS deployment does not require any variables to be defined-- you can run with the default (no variables defined), or check out `aws/variables.tf` for values that can be changed.
  - By default, AWS Session Manager is used to get an administrative shell into the instance. You can specify values for the `allowed_ssh_ip` and `PUBLIC_ssh_key` variables to instead use SSH access
- From a command line in this project directory, run `cd aws`
- [Follow these instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds) to set up AWS access locally without installing the AWS CLI (AWS CLI works too if you want to install that)
- Run `terraform init` to initialize Terraform
- Run `terraform apply` to start building the infrastructure
  - You'll be prompted to approve the build. Review the resources that are going to be created, and enter `yes` if acceptable
- Wait about 10 minutes for the entire build to succeed. Terraform will report success, but it'll take a few more minutes for the full bootstrapping process to complete
- From the AWS console, find your new instance under `EC2`
- Click `Connect` in the top right corner
- Select the `Session Manager` option from the tabs
- Click `Connect` to start a session right in your browser-- no SSH needed!
- If/when you want to destroy your Tor onion server, simply run `terraform destroy`


#### Digital Ocean Deployment (Minimal Configuration)
- From a command line in this project directory, run `cd digitalocean`
- The digitalocean/ code requires a minimum of two variables to be set:
  - `allowed_ssh_ip`: A public IPv4 address to allow SSH access to the instance. Although not recommended, you can specify `0.0.0.0` to allow all IPs
  - `PUBLIC_ssh_key`: The PUBLIC component of an SSH keypair. You can generate an SSH keypair using Linux or WSL with the `ssh-keygen` utility
- [Follow these instructions](https://docs.digitalocean.com/reference/api/create-personal-access-token/) to generate a personal access token within your DigitalOcean account
- Set the token as an environment variable named `DIGITALOCEAN_TOKEN`-- it must be named **exactly** this or Terraform won't automatically pick it up
  - Linux/Mac: `export DIGITALOCEAN_TOKEN=<YOUR_TOKEN>`
  - Windows: `$env:DIGITALOCEAN_TOKEN=<YOUR_TOKEN>`
- Run `terraform init` to initialize Terraform
- Run `terraform apply -var-file="../tor.tfvars"` to start building the infrastructure, using the values specified in your `tor.tfvars` file
  - You'll be prompted to approve the build. Review the resources that are going to be created, and enter `yes` if acceptable
- Wait about 10 minutes for the entire build to succeed. Terraform will report success, but it'll take a few more minutes for the full bootstrapping process to complete
- Use the DigitalOcean console to get the public IP address of your new Tor instance
- SSH into the instance using `ssh -i ~/.ssh/<PRIVATE_SSH_KEY> root@<INSTANCE_IP_ADDRESS>`
- From here, refer to the [Onionshare Use] section below for how to quickly set up a Tor site
- If/when you want to destroy your Tor onion server, simply run `terraform destroy -var-file="../tor.tfvars"`


#### Vultr Deployment (Minimal Configuration)
- From a command line in this project directory, run `cd vultr`
- The vultr/ code requires a minimum of two variables to be set:
  - `allowed_ssh_ip`: A public IPv4 address to allow SSH access to the instance. Although not recommended, you can specify `0.0.0.0` to allow all IPs
  - `PUBLIC_ssh_key`: The PUBLIC component of an SSH keypair. You can generate an SSH keypair using Linux or WSL with the `ssh-keygen` utility
- To get an API key from Vultr:
  - Log in to the Vultr console
  - From the left toolbar, select "Account"
  - On the "Account" page, select "API" from the middle-top toolbar
  - Click the blue "Enable API" button
  - Copy the value in the "API Key" textbox
  - Optionally, select which IPv4 and IPv6 addresses to allow API operations from
    - If your public IP address is NOT in this range, your Terraform operations will fail
      - If you don't want to specify your own IP address, click the "Allow All IPv4" and/or "Allow All IPv6" buttons
- Set the token as an environment variable named `VULTR_API_KEY`-- it must be named **exactly** this or Terraform won't automatically pick it up
  - Linux/Mac: `export VULTR_API_KEY=<YOUR_API_KEY>`
  - Windows: `$env:VULTR_API_KEY=<YOUR_API_KEY>`
- Run `terraform init` to initialize Terraform
- Run `terraform apply -var-file="../tor.tfvars"` to start building the infrastructure, using the values specified in your `tor.tfvars` file
  - You'll be prompted to approve the build. Review the resources that are going to be created, and enter `yes` if acceptable
- Wait about 10 minutes for the entire build to succeed. Terraform will report success, but it'll take a few more minutes for the full bootstrapping process to complete
- Use the Vultr console to get the public IP address of your new Tor instance
- SSH into the instance using `ssh -i ~/.ssh/<PRIVATE_SSH_KEY> root@<INSTANCE_IP_ADDRESS>`
- From here, refer to the [Onionshare Use](#onionshare-use) section below for how to quickly set up a Tor site
- If/when you want to destroy your Tor onion server, simply run `terraform destroy -var-file="../tor.tfvars"`


### Onionshare Use
- By default, a utility called [Onionshare](https://docs.onionshare.org/2.6/en/advanced.html#command-line-interface) is installed for quick setup and management of a Tor onion service. Type `onionshare` into the CLI to see all the options it can be run with
- You can just run `onionshare` commands directly on the instance, but they'll terminate once your session ends (foreground task)
  - To run them in the background, use `nohup`
    - e.g. with the chat server option -- `nohup onionshare --chat > onionshare-output.log 2>&1 &`
    - Onionshare will run in the background, and all output will be put into the `onionshare-output.log` file
    - To kill a background Onionshare service, type `pgrep onionshare` into the CLI, then copy the output number (e.g. `25510`). From there, type `pkill <copied_number>` to kill the background task
- By default, `onionshare` services will require a private key to connect (this key is generated when you launch the service-- check `onionshare-output.log`)
  - You can specify the `--public` option to make your onion service publicly available

### Manual Tor Onion Service Configuration (Advanced)
- By default, Onionshare is installed on your Tor server. This can be disabled by specifying `install_onionshare=false` in your `tor.tfvars` file
  - This will set up a basic manual configuration for a Tor onion service, directing Tor traffic to `localhost:80`
    - While you can configure this to instead use HTTPS for added security, this is not required since Tor is E2E encrypted anyway. There's also a very real possibility of de-anonymization due to how centralized certificate authorities work
    - While `locahost:80` is good enough for experimenting, TorProject recommends you use unix sockets for better security. Check out the "Tip" blurb under Step 2 of [this page](https://community.torproject.org/onion-services/setup/)
  - A random folder name will be generated for your Tor onion service configuration files. Check `/var/lib/tor/` for a folder that's a random assortment of letters and numbers
    - The `hostname` file will contain the v3 Onion address that can be used to reach your Tor onion service
    - **BE EXTREMELY CAREFUL WITH THE OTHER FILES IN THIS DIRECTORY, ESPECIALLY THE KEYS. IF THOSE KEYS ARE LEAKED/COMPROMISED, SOMEONE CAN IMPERSONATE YOUR TOR HIDDEN SERVICE**
- From here, the sky's the limit. You can set up any web server/service to listen on `localhost:80`, and it should be reachable via your Tor hidden service address
  - You can pretty quickly set up a proof-of-concept by installing nginx (`apt install nginx -y`) and search your onion address via the Tor browser. You should see the default nginx welcome page
- [HIGHLY RECOMMENDED] Additional Hidden Service Hardening And Security:
  - [TorProject's OpSec page](https://community.torproject.org/onion-services/advanced/opsec/)
  - [Riseup's Onion Service Best Practices page](https://riseup.net/en/security/network-security/tor/onionservices-best-practices)
  - [OnionScan](https://onionscan.org/) is a tool for scanning Onion sites to check for privacy/security leaks