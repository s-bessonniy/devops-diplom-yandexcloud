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

variable "service_account_name" {
  type        = string
  default     = "service-editor"
  description = "service account name"
}

variable "service_account_role" {
  type        = string
  default     = "editor"
  description = "service account role"
}

variable "diplom_backet" {
  type        = string
  default     = "diplom-backet"
  description = "backet"
}
