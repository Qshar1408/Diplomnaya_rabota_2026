variable "yc_cloud_id" {
  default = "b1g1ap2fp1jt638alsl9"
}

variable "yc_folder_id" {
  default = "b1g3sfourkjnlhsdmlut"
}

variable "yc_zone" {
  default = "ru-central1-a"
}


variable "ssh_username" {
  description = "Username for SSH access to the VM"
  type        = string
  default     = "qshar"  
}

 variable "vms_ssh_root_key" {
  type        = string
  default     = "ssh-ed25519 *************************************** qshar@qsharpcub05"
  description = "ssh-keygen -t ed25519"
 }

variable "s3_access_key" {
  description = "Existing S3 access key"
  type        = string
  sensitive   = true
  default     = ""  
}

variable "s3_secret_key" {
  description = "Existing S3 secret key"
  type        = string
  sensitive   = true
  default     = ""  
}