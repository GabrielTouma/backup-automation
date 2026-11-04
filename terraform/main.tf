provider "local" {}

# Resource 1: testfil i källmappen
resource "local_file" "testfil" {
  filename = "${path.module}/../data/source/${var.test_file}"
  content  = "Testfil skapad av Terraform\n"
}

# Resource 2: konfigurationsfil som PowerShell läser
resource "local_file" "config" {
  filename = "${path.module}/../data/config.json"
  content  = jsonencode({ backup_name = var.backup_name })
}