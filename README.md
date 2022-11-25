# torraform
A fast way to experiment with Tor hidden services.

### DISCLAIMER
DON'T DO ANYTHING ILLEGAL WITH THIS PROJECT.

### Setup
#### Prerequisites
- Install [Terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) or set up [Terraform Cloud](https://cloud.hashicorp.com/products/terraform)
- Set up an account with [AWS](https://aws.amazon.com/), [Digital Ocean](https://www.digitalocean.com/), or [Vultr](https://www.vultr.com/), depending on where you want to deploy your Tor server
- (Windows only) Install and configure [WSL](https://learn.microsoft.com/en-us/windows/wsl/install#install-wsl-command) on your local system. You will need this for SSH operations
- Create a `tor.tfvars` file in the same folder as this README file.

#### AWS Deployment
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


#### Onionshare Use
- By default, a utility called [Onionshare](https://docs.onionshare.org/2.6/en/advanced.html#command-line-interface) is installed for quick setup and management of a Tor hidden service. Type `onionshare` into the CLI to see all the options it can be run with
- You can just run `onionshare` commands directly on the instance, but they'll terminate once your session ends (foreground task)
  - To run them in the background, use `nohup`
    - e.g. with the chat server option -- `nohup onionshare --chat > onionshare-output.log 2>&1 &`
    - Onionshare will run in the background, and all output will be put into the `onionshare-output.log` file
    - To kill a background Onionshare service, type `pgrep onionshare` into the CLI, then copy the output number. From there, type `pkill <copied_number>` to kill the background task