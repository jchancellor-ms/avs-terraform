variable "firewall_policy_id" {
  type        = string
  description = "The Azure resource id for the azure firewall policy that this rule will be applied to"
  default     = ""
}


variable "azure_firewall_name" {
  type        = string
  description = "The Azure resource name of the azure firewall when deploying with a classic rule collection group"
  default     = ""
}

variable "azure_firewall_rg_name" {
  type        = string
  description = "The Azure resource group name where the azure firewall is deployed when using a classic rule collection group"
  default     = ""
}

variable "avs_ip_ranges" {
  type        = list(string)
  description = "The set of IP ranges assigned to AVS for management and workloads"
}

variable "has_firewall_policy" {
  type        = bool
  description = "A flag variable for setting when to create test rules for azure policy or create classic rule collection"
  default     = false
}
