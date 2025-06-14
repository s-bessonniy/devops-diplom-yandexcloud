###cloud vars
variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
  #default = ""
  #sensitive = true
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
  #default = ""
  #sensitive = true
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
  #default = ""
  #sensitive = true
}

variable "ssh_root_key" {
  description = "metadata for all vms"
  type        = map(string)
  default     = {
    serial-port-enable = "1"
    ssh-keys           = "ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMIgCTAknACY9siTMrK+ozJsJoFis+9ePIUyAC8YYd/K s_yaremko@Ubuntu-50Gb"
  }
}


variable "vpc_name" {
  type        = string
  default     = "diplom-network"
  description = "VPC network&subnet name"
}

variable "subnet-zones" {
  type    = list(string)
  default = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
}

variable "cidr" {
  type    = map(list(string))
  default = {
    stage = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"]    
  }
}

variable "vm_image_master" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "yandex_compute_image_master"
}

variable "vm_image_worker" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "yandex_compute_image_worker"
}

variable "worker_node_names" {
  type        = string
  default     = "worker-node"
  description = "names worker nodes"
}

variable "master_node_names" {
  type        = string
  default     = "master-node"
  description = "names worker nodes"
}

variable "worker_nodes_size" {
  default     = 3
  description = "worker nodes size"
}

variable "master_nodes_size" {
  default     = 1
  description = "worker nodes size"
}

variable "nodes_platform_id" {
  type        = string
  default     = "standard-v2"
  description = "yandex_compute_platform_id"
}

variable "nodes_resources" {
  description = "Resources for all nodes"
  type        = map(map(number))
  default     = {
    master_node_resources = {
      cores         = 2
      memory        = 2
      core_fraction = 20
    }
    worker_nodes_resources = {
      cores         = 2
      memory        = 2
      core_fraction = 20
    }
  }
}

variable "boot_disk_master_nodes" {
  type        = list(object({
    size = number
    type = string
    }))
    default = [ {
    size = 10
    type = "network-hdd"
  }]
}

variable "boot_disk_worker_nodes" {
  type        = list(object({
    size = number
    type = string
    }))
    default = [ {
    size = 10
    type = "network-hdd"
  }]
}

variable "vm_nat" {
  type = bool
  default = true
}

variable "exclude_ansible" {
  type        = bool
  default     = false
}
