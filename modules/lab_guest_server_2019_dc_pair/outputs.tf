output "dc_join_password" {
  value     = random_password.userpass.result
  sensitive = true
}