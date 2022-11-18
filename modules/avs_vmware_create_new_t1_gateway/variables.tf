variable "nsxt_root" {
  type        = string
  description = "AVS root value used in t0, edge, and transport overlay naming"
}

variable "t1_gateway_display_name" {
  type        = string
  description = "Display name for the new T1 gateway"
}

variable "dhcp_profile" {
  description = "map of strings used to create the dhcp profile"
}

variable "nsx_ip" {
  type        = string
  description = "NSX-T manager IP address"
}

variable "nsx_user" {
  description = "NSX-T administrator username"
  type        = string
  sensitive   = true
}

variable "nsx_password" {
  description = "NSX-T administrator password"
  type        = string
  sensitive   = true
}