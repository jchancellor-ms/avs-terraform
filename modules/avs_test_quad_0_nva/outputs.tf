output "cloud_init" {
  value = data.template_file.bird_config.rendered
}