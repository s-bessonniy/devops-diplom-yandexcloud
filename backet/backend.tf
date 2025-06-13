#create backet
resource "yandex_storage_bucket" "diplom-bucket" {
  bucket     = var.diplom_backet
  access_key = yandex_iam_service_account_static_access_key.service-editor-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.service-editor-key.secret_key

  anonymous_access_flags {
    read = false
    list = false
  }

  force_destroy = true

provisioner "local-exec" {
  command = "echo export ACCESS_KEY=${yandex_iam_service_account_static_access_key.service-editor-key.access_key} > ./backend.tfvars"
}

provisioner "local-exec" {
  command = "echo export SECRET_KEY=${yandex_iam_service_account_static_access_key.service-editor-key.secret_key} >> ./backend.tfvars"
}
}
