terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">=1.8.4"
}


provider "yandex" {
  # token     = var.yc_token  
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
  service_account_key_file = file(".authorized_key.json")
  
}
# Создание сервисного аккаунта gribanov-diplom
resource "yandex_iam_service_account" "gribanov_diplom" {
  name        = "gribanov-diplom"
  description = "Service account for diploma project"
}

# Назначение роли storage.editor
resource "yandex_resourcemanager_folder_iam_binding" "storage_admin" {
  folder_id = var.yc_folder_id
  role      = "storage.admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.gribanov_diplom.id}"
  ]
}

# Создание статических ключей доступа
resource "yandex_iam_service_account_static_access_key" "sa_key" {
  service_account_id = yandex_iam_service_account.gribanov_diplom.id
  description        = "Static access keys for S3"
}

# Отдельный провайдер для Object Storage с использованием созданных ключей
provider "yandex" {
  alias              = "storage"
  service_account_key_file = file(".authorized_key.json")
  cloud_id           = var.yc_cloud_id
  folder_id          = var.yc_folder_id
  storage_access_key = yandex_iam_service_account_static_access_key.sa_key.access_key
  storage_secret_key = yandex_iam_service_account_static_access_key.sa_key.secret_key
}

# Создание S3 бакета
resource "yandex_storage_bucket" "diplom_bucket" {
  provider = yandex.storage
  bucket   = "gribanov-diplom"
  acl      = "private"
  force_destroy = true

  anonymous_access_flags {
    read = false
    list = false
  }

  versioning {
    enabled = true
  }
}

# грузим объект в бакете
resource "yandex_storage_object" "terraform_tfvars" {
  provider = yandex.storage
  bucket   = yandex_storage_bucket.diplom_bucket.bucket
  key      = "terraform.tfvars"
  source   = "./image.jpg"
  acl      = "private"
}

# Outputs
output "service_account_id" {
  value = yandex_iam_service_account.gribanov_diplom.id
}

output "access_key" {
  value     = yandex_iam_service_account_static_access_key.sa_key.access_key
  sensitive = true
}

output "secret_key" {
  value     = yandex_iam_service_account_static_access_key.sa_key.secret_key
  sensitive = true
}

output "bucket_name" {
  value = yandex_storage_bucket.diplom_bucket.bucket
}