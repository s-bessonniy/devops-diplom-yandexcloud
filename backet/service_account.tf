# create service account
resource "yandex_iam_service_account" "service-editor" {
  name        = var.service_account_name
  folder_id   = var.folder_id
}

# create role
resource "yandex_resourcemanager_folder_iam_member" "service-editor-role" {
  folder_id = var.folder_id
  role      = var.service_account_role
  member    = "serviceAccount:${yandex_iam_service_account.service-editor.id}"
}

#create static key
resource "yandex_iam_service_account_static_access_key" "service-editor-key" {
  service_account_id = yandex_iam_service_account.service-editor.id
}
