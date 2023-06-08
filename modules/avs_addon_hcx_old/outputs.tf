output "keys" {
  value = {
    for key, value in azapi_resource.hcx_keys : key => jsondecode(value.output).properties.activationKey
  }
  /*
  value = [
    for keyname, activation in zipmap(
        sort(var.hcx_key_names),
        sort(values(jsondecode(azapi_resource.hcx_keys[*].output).properties.activationKey))) : 
        map("keyname", keyname, "activation", activation)    
  ]*/
}