terraform {
  required_providers {
    vultr = {
      source = "vultr/vultr"
      version = "~>2.11.4"
    }
  }
}

# Set api_key as an environment variable (VULTR_API_KEY)-- NEVER set statically within the code
provider "vultr" {
  rate_limit = 700
  retry_limit = 3
}