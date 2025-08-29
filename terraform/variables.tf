variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "k8s-azure-project"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "node_count" {
  description = "Number of AKS nodes"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27.3"
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for AKS"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "Minimum number of nodes for auto scaling"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum number of nodes for auto scaling"
  type        = number
  default     = 10
}

variable "network_plugin" {
  description = "Network plugin for AKS"
  type        = string
  default     = "azure"
}

variable "enable_rbac" {
  description = "Enable RBAC for AKS"
  type        = bool
  default     = true
}

variable "admin_username" {
  description = "Admin username for AKS nodes"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for AKS nodes"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "k8s-azure-infrastructure"
    ManagedBy   = "terraform"
  }
}
