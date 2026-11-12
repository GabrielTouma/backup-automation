

# Visar sökvägen till testfilerna efter terraform apply
output "testfiler" {
  value = [for f in local_file.testfil : f.filename]
}


# Visar sökvägen till config.json efter terraform apply
output "config_file" {
  value = local_file.config.filename
}