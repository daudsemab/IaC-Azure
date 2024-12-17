variable resource_group_name {
  type        = string
  default     = "1-9ddb1d1d-playground-sandbox"
  description = "Resource Group"
}

variable resource_group_location {
  type        = string
  default     = "East US"
  description = "Resource Group Location"
}

variable storage_account_name {
  type        = string
  default     = "tfstatebackendstorage23"
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

variable vm_admin_username {
  type        = string
  default     = "daudadmin"
  description = "VM Admin Username"
}

variable CLIENT_ACCESS {
}