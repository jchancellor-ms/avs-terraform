output "cloud_init" {
  value = data.template_file.frr_config.rendered
}