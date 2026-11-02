output "config_file" {
  description = "Sökväg till config.json"
  value       = local_file.config.filename
}

output "source_dir" {
  value = "${local.data_dir}/source"
}

output "backup_dir" {
  value = "${local.data_dir}/backup"
}

output "files_created" {
  value = [for f in local_file.test_files : f.filename]
}