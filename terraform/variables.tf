variable resource_group_name {
  type        = string
  default     = "1-811d974d-playground-sandbox"
  description = "Resource Group"
}

variable resource_group_location {
  type        = string
  default     = "West US"
  description = "Resource Group Location"
}

variable storage_account_name {
  type        = string
  default     = "tfstatebackendstorage11"
  description = "Backend Storage Account"
}

variable storage_container_name {
  type        = string
  default     = "tfstate-container"
  description = "Terraform State File Blob Storage"
}

variable vnet_address_space {
  type        = list
  default     = ["10.0.0.0/16"]
  description = "Virtual Network Address Space"
}

variable subnet_address_prefixes {
  type        = list
  default     = ["10.0.2.0/24"]
  description = "Subnet Address Prefixes"
}

variable CLIENT_ACCESS {
}