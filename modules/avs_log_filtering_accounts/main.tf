########################################################################################
#Create an AD application registration service principal and password
########################################################################################
data "azuread_client_config" "current" {}

resource "azuread_application" "log_processing_principal" {
  display_name = var.avs_log_processing_service_principal_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "log_procesing_principal" {
  application_id               = azuread_application.log_processing_principal.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "log_procesing_principal" {
  service_principal_id = azuread_service_principal.log_procesing_principal.object_id
}

resource "azuread_application_password" "log_processing_principal" {
  application_object_id = azuread_application.log_processing_principal.object_id
}