variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "centralindia"
}

variable "name_prefix" {
  description = "Lowercase, globally unique prefix used in resource names."
  type        = string
  default     = "axion"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.name_prefix))
    error_message = "name_prefix must be 2-20 characters and contain only lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment tag."
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Set to a currently supported Azure version."
  type        = string
  default     = null
  nullable    = true
}

variable "vnet_address_space" {
  description = "Address space for the AKS virtual network."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for the AKS subnet."
  type        = list(string)
  default     = ["10.20.0.0/22"]
}

variable "admin_allowed_ip_ranges" {
  description = "Optional CIDR ranges allowed to reach the public AKS API server. Empty means Azure default public access."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Retention period for Log Analytics data."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}