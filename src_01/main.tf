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

#  backend "s3" {
#  endpoint = "https://storage.yandexcloud.net"
#  bucket     = "gribanov-diplom"
#  key        = "terraform.tfstate"
#  region     = "ru-central1"
  
#  access_key = ""  # backend.hcl
#  secret_key = ""
  
#  skip_region_validation      = true
#  skip_credentials_validation = true
  
#    }

# Сеть
#resource "yandex_vpc_network" "default" {
#  name = "gribanov-net"
#}

# Создание VPC сети
resource "yandex_vpc_network" "network" {
  name = "gribanov-network"                   
}

# Подсеть в зоне ru-central1-a
resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

# Подсеть в зоне ru-central1-b
resource "yandex_vpc_subnet" "subnet_b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

# Подсеть в зоне ru-central1-d
resource "yandex_vpc_subnet" "subnet_d" {
  name           = "subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}
