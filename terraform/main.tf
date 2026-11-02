terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "local" {}

locals {
  data_dir = abspath("${path.module}/../data")
}

# Resource 1: testfiler i källmappen (skapar även mappen source/)
resource "local_file" "test_files" {
  for_each = toset(var.test_files)
  filename = "${local.data_dir}/source/${each.value}"
  content  = "Testfil: ${each.value}\nSkapad av Terraform\n"
}

# Resource 2: tom fil som skapar backupmappen
resource "local_file" "backup_dir" {
  filename = "${local.data_dir}/backup/.keep"
  content  = ""
}

# Resource 3: konfigurationsfil som PowerShell läser
resource "local_file" "config" {
  filename = "${local.data_dir}/config.json"
  content = jsonencode({
    backup_name = var.backup_name
    max_backups = var.max_backups
    source_dir  = "${local.data_dir}/source"
    backup_dir  = "${local.data_dir}/backup"
    log_file    = "${local.data_dir}/backup.log"
  })
}