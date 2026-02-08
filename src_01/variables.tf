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
  default     = "ssh-ed25519 ************************* qshar@qsharpcub05"
  description = "ssh-keygen -t ed25519"
 }

variable "access_key" {
  description = "Access key для S3-хранилища Яндекс Облака"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_key" {
  description = "Secret key для S3-хранилища Яндекс Облака"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_user" {
  description = "SSH user name"
  type        = string
  default     = "ubuntu"
}

variable "public_key_path" {
  description = "Path to public SSH key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}