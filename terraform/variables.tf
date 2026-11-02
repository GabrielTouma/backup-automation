variable "backup_name" {
  description = "Namn på backupjobbet"
  type        = string
  default     = "dagligbackup"
}

variable "max_backups" {
  description = "Max antal backuper som sparas"
  type        = number
  default     = 5
}

variable "test_files" {
  description = "Testfiler som skapas i källmappen"
  type        = list(string)
  default     = ["rapport.txt", "kunder.txt", "anteckningar.txt"]
}