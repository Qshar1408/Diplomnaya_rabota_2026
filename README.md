# Дипломный практикум в Yandex.Cloud

## Грибанов Антон. FOPS-31.

  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://developer.hashicorp.com/terraform/language/backend) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)
3. Создайте конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.
4. Создайте VPC с подсетями в разных зонах доступности.
5. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
6. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://developer.hashicorp.com/terraform/language/backend) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий, стейт основной конфигурации сохраняется в бакете или Terraform Cloud
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

### Деплой инфраструктуры в terraform pipeline

1. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ на 80 порту к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ на 80 порту к тестовому приложению.
5. Atlantis или terraform cloud или ci/cd-terraform
---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---

# Решение

## ЗАДАНИЕ 1. Создание облачной инфраструктуры

### 1.1. Создаем сервисный аккаунт. Подготавливаем backend.

Конфиги [Bucket](https://github.com/Qshar1408/Diplomnaya_rabota_2026/tree/main/bucket)

<details>
 <summary>main.tf</summary>   

    terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
     local = {
      source = "hashicorp/local"
      version = "~> 2.4"
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

provider "local" {
  # Конфигурация не требуется для провайдера local
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

# Создание файла backend.hcl с ключами
resource "local_file" "backend_hcl" {
  filename = "${path.module}/backend.hcl"
  content  = <<-EOT
    access_key = "${yandex_iam_service_account_static_access_key.sa_key.access_key}"
    secret_key = "${yandex_iam_service_account_static_access_key.sa_key.secret_key}"
  EOT
  
  file_permission = "0600"  # Только владелец может читать/писать
  
  # Зависит от создания ключей
  depends_on = [yandex_iam_service_account_static_access_key.sa_key]
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

</details>

<details>
 <summary>variables.tf</summary>

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
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9YRaPI5Y4FrDzkjpBIzWxrb2Bi4bDb5fmCCSLXpQO6 qshar@qsharpcub05"
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
variable "ssh_user" {
  description = "SSH user name"
  type        = string
  default     = "qshar"
}

variable "public_key_path" {
  description = "Path to public SSH key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

</details>

### 1.2. Выполняем Terraform plan:

<details>
 <summary>Terraform plan</summary>

terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.backend_hcl will be created
  + resource "local_file" "backend_hcl" {
      + content              = (sensitive value)
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0600"
      + filename             = "./backend.hcl"
      + id                   = (known after apply)
    }

  # yandex_iam_service_account.gribanov_diplom will be created
  + resource "yandex_iam_service_account" "gribanov_diplom" {
      + created_at         = (known after apply)
      + description        = "Service account for diploma project"
      + folder_id          = (known after apply)
      + id                 = (known after apply)
      + labels             = (known after apply)
      + name               = "gribanov-diplom"
      + service_account_id = (known after apply)
    }

  # yandex_iam_service_account_static_access_key.sa_key will be created
  + resource "yandex_iam_service_account_static_access_key" "sa_key" {
      + access_key                   = (known after apply)
      + created_at                   = (known after apply)
      + description                  = "Static access keys for S3"
      + encrypted_secret_key         = (known after apply)
      + id                           = (known after apply)
      + key_fingerprint              = (known after apply)
      + output_to_lockbox_version_id = (known after apply)
      + secret_key                   = (sensitive value)
      + service_account_id           = (known after apply)
    }

  # yandex_resourcemanager_folder_iam_binding.storage_admin will be created
  + resource "yandex_resourcemanager_folder_iam_binding" "storage_admin" {
      + folder_id = "b1g3sfourkjnlhsdmlut"
      + members   = [
          + (known after apply),
        ]
      + role      = "storage.admin"
    }

  # yandex_storage_bucket.diplom_bucket will be created
  + resource "yandex_storage_bucket" "diplom_bucket" {
      + acl                   = "private"
      + bucket                = "gribanov-diplom"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = (known after apply)
      + force_destroy         = true
      + id                    = (known after apply)
      + policy                = (known after apply)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)

      + anonymous_access_flags {
          + list = false
          + read = false
        }

      + grant (known after apply)

      + versioning {
          + enabled = true
        }
    }

  # yandex_storage_object.terraform_tfvars will be created
  + resource "yandex_storage_object" "terraform_tfvars" {
      + acl          = "private"
      + bucket       = "gribanov-diplom"
      + content_type = (known after apply)
      + id           = (known after apply)
      + key          = "terraform.tfvars"
      + source       = "./image.jpg"
    }

Plan: 6 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + access_key         = (sensitive value)
  + bucket_name        = "gribanov-diplom"
  + secret_key         = (sensitive value)
  + service_account_id = (known after apply)
╷
│ Warning: Argument is deprecated
│ 
│   with yandex_storage_bucket.diplom_bucket,
│   on main.tf line 77, in resource "yandex_storage_bucket" "diplom_bucket":
│   77:   acl      = "private"
│ 
│ Use `yandex_storage_bucket_grant` instead.
│ 
│ (and one more similar warning elsewhere)
╵

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply"
now.

</details>

### 1.3. Выполняем Terraform apply:

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_001.png)

### 1.4. Проверяем, что у нас получилось в итоге:

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_002.png)

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_003.png)

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_004.png)

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_005.png)

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_006.png)


### 1.5. Теперь создаём VPC с подсетями:

```bash

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
```

### 1.6. Проверяем, что получилось:

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_007.png)

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_008.png)

### 1.7. Проверяем, что можем удалить:

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_009.png)


## ЗАДАНИЕ 2. Создание Kubernetes кластера

### 2.1. Подготавливаем всё необходимое ддля сборки Kubernetes кластера.

#### Конфиги: 

<details>
<summary>cloud-init.tf</summary> 

```yaml
users:
  - name: qshar
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${vms_ssh_root_key}
package_update: true
package_upgrade: false

</details> ```

<details>
<summary>main.tf</summary>  

```yaml  
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
     local = {
      source = "hashicorp/local"
      version = "~> 2.4"
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

provider "local" {
  # Конфигурация не требуется для провайдера local
}

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

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

#Network Load 
# Создаем статические IP-адреса
resource "yandex_vpc_address" "grafana_ip" {
  name = "grafana-lb-ip"
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

resource "yandex_vpc_address" "web_app_ip" {
  name = "web-app-lb-ip"
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

# Мастер-узел
resource "yandex_compute_instance" "master" {
  name        = "gribanov-master"
  zone        = "ru-central1-d"  # Мастер в зоне d 
  platform_id = "standard-v2"    # 

  resources {
    cores  = 2
    memory = 6
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 50
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_d.id  #  подсеть в зоне d
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.vms_ssh_root_key}"
  }
  scheduling_policy {
    preemptible = true
    }
}

# Воркеры
resource "yandex_compute_instance" "worker" {
  count       = 4
  name        = "gribanov-worker-${count.index + 1}"
  platform_id = "standard-v2"
  zone        = count.index == 0 ? "ru-central1-a" : "ru-central1-b" 
 
    scheduling_policy {
    preemptible = true
  }

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 50
    }
  }

  network_interface {
    subnet_id = count.index == 0 ? yandex_vpc_subnet.subnet_a.id : yandex_vpc_subnet.subnet_b.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.vms_ssh_root_key}"
  }
}

# ЦГ для Grafana (воркеры 1 и 2)
resource "yandex_lb_target_group" "grafana_workers" {
  name = "gribanov-grafana-workers-tg"

  dynamic "target" {
    for_each = slice(yandex_compute_instance.worker, 0, 2) # Берем первые 2 воркера
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

# ЦГ для Web App (воркеры 3 и 4)
resource "yandex_lb_target_group" "web_workers" {
  name = "gribanov-web-workers-tg"

  dynamic "target" {
    for_each = slice(yandex_compute_instance.worker, 2, 4) # Берем последние 2 воркера
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

#  балансировщики разные целевые группы
resource "yandex_lb_network_load_balancer" "grafana_lb" {
  name = "gribanov-grafana-nlb"

  listener {
    name        = "grafana-listener"
    port        = 80        # внешний — 80
    target_port = 30080     # NodePort Grafana

    external_address_spec {
      address    = yandex_vpc_address.grafana_ip.external_ipv4_address[0].address
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.grafana_workers.id

    healthcheck {
      name = "grafana-hc"
      http_options {
        port = 30080
        path = "/api/health"
      }
    }
  }
}

resource "yandex_lb_network_load_balancer" "web_app_lb" {
  name = "gribanov-web-app-nlb"

  listener {
    name        = "web-app-listener"
    port        = 80        
    target_port = 30081    

    external_address_spec {
      address    = yandex_vpc_address.web_app_ip.external_ipv4_address[0].address
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.web_workers.id

    healthcheck {
      name = "web-app-hc"
      http_options {
        port = 30081
        path = "/"
      }
    }
  }
}

# Вывод IP-адресов балансировщиков
output "grafana_lb_ip" {
  value = yandex_vpc_address.grafana_ip.external_ipv4_address[0].address
}

output "web_app_lb_ip" {
  value = yandex_vpc_address.web_app_ip.external_ipv4_address[0].address
}
output "master_public_ip" {
  value = yandex_compute_instance.master.network_interface.0.nat_ip_address
}

output "worker_public_ips" {
  value = yandex_compute_instance.worker[*].network_interface.0.nat_ip_address
}

output "master_private_ip" {
  value = yandex_compute_instance.master.network_interface.0.ip_address
}

output "worker_private_ips" {
  value = yandex_compute_instance.worker[*].network_interface.0.ip_address
}

</details>```

<details>
 <summary>variables.tf</summary> 

```yaml  
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
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9YRaPI5Y4FrDzkjpBIzWxrb2Bi4bDb5fmCCSLXpQO6 qshar@qsharpcub05"
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
  default     = "qshar"
}

variable "public_key_path" {
  description = "Path to public SSH key"
  type        = string
  default     = "/home/qshar/.ssh/id_rsa.pub"
}

variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
  default     = ""  # Заполните здесь
}
</details>```

### 2.2. Выполняем Terraform plan:

<details>
 <summary>Terraform plan</summary>

terraform plan
data.yandex_compute_image.ubuntu: Reading...
data.yandex_compute_image.ubuntu: Read complete after 0s [id=fd8t9g30r3pc23et5krl]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.master will be created
  + resource "yandex_compute_instance" "master" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = "qshar:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9YRaPI5Y4FrDzkjpBIzWxrb2Bi4bDb5fmCCSLXpQO6 qshar@qsharpcub05"
        }
      + name                      = "gribanov-master"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-d"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8t9g30r3pc23et5krl"
              + name        = (known after apply)
              + size        = 50
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index          = (known after apply)
          + ip_address     = (known after apply)
          + ipv4           = true
          + ipv6           = (known after apply)
          + ipv6_address   = (known after apply)
          + mac_address    = (known after apply)
          + nat            = true
          + nat_ip_address = (known after apply)
          + nat_ip_version = (known after apply)
          + subnet_id      = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 6
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_compute_instance.worker[0] will be created
  + resource "yandex_compute_instance" "worker" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = "qshar:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9YRaPI5Y4FrDzkjpBIzWxrb2Bi4bDb5fmCCSLXpQO6 qshar@qsharpcub05"
        }
      + name                      = "gribanov-worker-1"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-a"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8t9g30r3pc23et5krl"
              + name        = (known after apply)
              + size        = 50
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index          = (known after apply)
          + ip_address     = (known after apply)
          + ipv4           = true
          + ipv6           = (known after apply)
          + ipv6_address   = (known after apply)
          + mac_address    = (known after apply)
          + nat            = true
          + nat_ip_address = (known after apply)
          + nat_ip_version = (known after apply)
          + subnet_id      = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_compute_instance.worker[1] will be created
  + resource "yandex_compute_instance" "worker" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = "qshar:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9YRaPI5Y4FrDzkjpBIzWxrb2Bi4bDb5fmCCSLXpQO6 qshar@qsharpcub05"
        }
      + name                      = "gribanov-worker-2"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-b"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8t9g30r3pc23et5krl"
              + name        = (known after apply)
              + size        = 50
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index          = (known after apply)
          + ip_address     = (known after apply)
          + ipv4           = true
          + ipv6           = (known after apply)
          + ipv6_address   = (known after apply)
          + mac_address    = (known after apply)
          + nat            = true
          + nat_ip_address = (known after apply)
          + nat_ip_version = (known after apply)
          + subnet_id      = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_compute_instance.worker[2] will be created
  + resource "yandex_compute_instance" "worker" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = "qshar:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9YRaPI5Y4FrDzkjpBIzWxrb2Bi4bDb5fmCCSLXpQO6 qshar@qsharpcub05"
        }
      + name                      = "gribanov-worker-3"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-b"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8t9g30r3pc23et5krl"
              + name        = (known after apply)
              + size        = 50
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index          = (known after apply)
          + ip_address     = (known after apply)
          + ipv4           = true
          + ipv6           = (known after apply)
          + ipv6_address   = (known after apply)
          + mac_address    = (known after apply)
          + nat            = true
          + nat_ip_address = (known after apply)
          + nat_ip_version = (known after apply)
          + subnet_id      = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_compute_instance.worker[3] will be created
  + resource "yandex_compute_instance" "worker" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hardware_generation       = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = "qshar:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN9YRaPI5Y4FrDzkjpBIzWxrb2Bi4bDb5fmCCSLXpQO6 qshar@qsharpcub05"
        }
      + name                      = "gribanov-worker-4"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v2"
      + status                    = (known after apply)
      + zone                      = "ru-central1-b"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8t9g30r3pc23et5krl"
              + name        = (known after apply)
              + size        = 50
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + metadata_options (known after apply)

      + network_interface {
          + index          = (known after apply)
          + ip_address     = (known after apply)
          + ipv4           = true
          + ipv6           = (known after apply)
          + ipv6_address   = (known after apply)
          + mac_address    = (known after apply)
          + nat            = true
          + nat_ip_address = (known after apply)
          + nat_ip_version = (known after apply)
          + subnet_id      = (known after apply)
        }

      + placement_policy (known after apply)

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # yandex_lb_network_load_balancer.grafana_lb will be created
  + resource "yandex_lb_network_load_balancer" "grafana_lb" {
      + allow_zonal_shift   = (known after apply)
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "gribanov-grafana-nlb"
      + region_id           = (known after apply)
      + type                = "external"

      + attached_target_group {
          + target_group_id = (known after apply)

          + healthcheck {
              + healthy_threshold   = 2
              + interval            = 2
              + name                = "grafana-hc"
              + timeout             = 1
              + unhealthy_threshold = 2

              + http_options {
                  + path = "/api/health"
                  + port = 30080
                }
            }
        }

      + listener {
          + name        = "grafana-listener"
          + port        = 80
          + protocol    = (known after apply)
          + target_port = 30080

          + external_address_spec {
              + address    = (known after apply)
              + ip_version = "ipv4"
            }
        }
    }

  # yandex_lb_network_load_balancer.web_app_lb will be created
  + resource "yandex_lb_network_load_balancer" "web_app_lb" {
      + allow_zonal_shift   = (known after apply)
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "gribanov-web-app-nlb"
      + region_id           = (known after apply)
      + type                = "external"

      + attached_target_group {
          + target_group_id = (known after apply)

          + healthcheck {
              + healthy_threshold   = 2
              + interval            = 2
              + name                = "web-app-hc"
              + timeout             = 1
              + unhealthy_threshold = 2

              + http_options {
                  + path = "/"
                  + port = 30081
                }
            }
        }

      + listener {
          + name        = "web-app-listener"
          + port        = 80
          + protocol    = (known after apply)
          + target_port = 30081

          + external_address_spec {
              + address    = (known after apply)
              + ip_version = "ipv4"
            }
        }
    }

  # yandex_lb_target_group.grafana_workers will be created
  + resource "yandex_lb_target_group" "grafana_workers" {
      + created_at      = (known after apply)
      + description     = (known after apply)
      + folder_id       = (known after apply)
      + id              = (known after apply)
      + labels          = (known after apply)
      + name            = "gribanov-grafana-workers-tg"
      + region_id       = (known after apply)
      + target_group_id = (known after apply)

      + target {
          + address   = (known after apply)
          + subnet_id = (known after apply)
        }
      + target {
          + address   = (known after apply)
          + subnet_id = (known after apply)
        }
    }

  # yandex_lb_target_group.web_workers will be created
  + resource "yandex_lb_target_group" "web_workers" {
      + created_at      = (known after apply)
      + description     = (known after apply)
      + folder_id       = (known after apply)
      + id              = (known after apply)
      + labels          = (known after apply)
      + name            = "gribanov-web-workers-tg"
      + region_id       = (known after apply)
      + target_group_id = (known after apply)

      + target {
          + address   = (known after apply)
          + subnet_id = (known after apply)
        }
      + target {
          + address   = (known after apply)
          + subnet_id = (known after apply)
        }
    }

  # yandex_vpc_address.grafana_ip will be created
  + resource "yandex_vpc_address" "grafana_ip" {
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + labels              = (known after apply)
      + name                = "grafana-lb-ip"
      + reserved            = (known after apply)
      + used                = (known after apply)

      + external_ipv4_address {
          + address                  = (known after apply)
          + ddos_protection_provider = (known after apply)
          + outgoing_smtp_capability = (known after apply)
          + zone_id                  = "ru-central1-a"
        }
    }

  # yandex_vpc_address.web_app_ip will be created
  + resource "yandex_vpc_address" "web_app_ip" {
      + created_at          = (known after apply)
      + deletion_protection = (known after apply)
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + labels              = (known after apply)
      + name                = "web-app-lb-ip"
      + reserved            = (known after apply)
      + used                = (known after apply)

      + external_ipv4_address {
          + address                  = (known after apply)
          + ddos_protection_provider = (known after apply)
          + outgoing_smtp_capability = (known after apply)
          + zone_id                  = "ru-central1-a"
        }
    }

  # yandex_vpc_network.network will be created
  + resource "yandex_vpc_network" "network" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "gribanov-network"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet_a will be created
  + resource "yandex_vpc_subnet" "subnet_a" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.0.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.subnet_b will be created
  + resource "yandex_vpc_subnet" "subnet_b" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.0.1.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # yandex_vpc_subnet.subnet_d will be created
  + resource "yandex_vpc_subnet" "subnet_d" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-d"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.0.2.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-d"
    }

Plan: 15 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + grafana_lb_ip      = (known after apply)
  + master_private_ip  = (known after apply)
  + master_public_ip   = (known after apply)
  + web_app_lb_ip      = (known after apply)
  + worker_private_ips = [
      + (known after apply),
      + (known after apply),
      + (known after apply),
      + (known after apply),
    ]
  + worker_public_ips  = [
      + (known after apply),
      + (known after apply),
      + (known after apply),
      + (known after apply),
    ]

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply"
now.

</details>

### 2.3. Проверяем, что получилось:

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_010.png)

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_011.png)

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_012.png)

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_013.png)

![Diplomnaya_rabota_2026](https://github.com/Qshar1408/Diplomnaya_rabota_2026/blob/main/img/diplom_014.png)



## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)

