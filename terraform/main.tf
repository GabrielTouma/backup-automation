# main.tf - beskriver vad Terraform ska skapa

provider "local" {}

# Resource 1: skapar en testfil per namn i listan (mappen skapas automatiskt)

resource "local_file" "testfil" {
  for_each = toset(var.test_files)                          #for loop går igenom test_files, kolla variables.tf; list(string)
  filename = "${path.module}/../data/source/${each.value}"  # sökväg med variabel, path.module är mappen där main.tf ligger, projektroot
  content  = "Привет arseniy!\n"                            
}

# Resource 2: skapar config.json som PowerShell-skriptet läser

resource "local_file" "config" {
  filename = "${path.module}/../data/config.json"
  content  = jsonencode({ backup_name = var.backup_name })  # gör om till JSON
}