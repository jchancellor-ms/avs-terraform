variable "rg_name" {
  type        = string
  description = "Resource Group Name where the tf_vm is deployed"
}

variable "rg_location" {
  type        = string
  description = "Resource Group location"
  default     = "westus2"
}

variable "tf_vm_subnet_id" {
  type        = string
  description = "subnet where the tf_vm will be deployed"
}

variable "tf_vm_name" {
  type        = string
  description = "name for the tf_vm"
}

variable "key_vault_id" {
  type        = string
  description = "the resource id for the keyvault where the password will be stored"
}

variable "vmware_creds" {
  sensitive   = true
  description = "A map containing the credential details for the provider to authenticate to nsx and vsphere"
}

variable "vmware_state_storage" {
  description = "A map containing the storage account details to use for the vmware state file"
}

variable "vmware_deployment" {
  description = "A map containing the deployment values for the VMware terraform deployment"
}

variable "tf_template_github_source" {
  type        = string
  description = "the terraform module github source reference"
}