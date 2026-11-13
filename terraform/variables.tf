# variables.tf - värden som kan ändras utan att röra main.tf
# Exempel: terraform apply -var="backup_name=veckobackup"

# Namn på backupjobbet, används i backupmappens namn
variable "backup_name" {
  type    = string          
  default = "dagligbackup"  # används om inget annat anges
}

# Namn på testfilen som skapas i källmappen
variable "test_files" {
  type    = list(string)
  default = ["rapport.txt", "testfil.txt", "arseniy.txt"]
}