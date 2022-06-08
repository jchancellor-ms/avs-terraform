variable "prefix" {
  type        = string
  description = "Simple prefix used for naming convention prepending"
}

variable "rg_name_on_prem" {
  type        = string
  description = "The azure resource name for the resource group"
}

variable "rg_location_on_prem" {
  description = "Resource Group region location"
  default     = "westus2"
}

variable "rg_name_avs" {
  type        = string
  description = "The azure resource name for the resource group"
}

variable "rg_location_avs" {
  description = "Resource Group region location"
  default     = "westus2"
}

variable "on_prem_gateway_id" {
  type = string
}

variable "avs_gateway_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}