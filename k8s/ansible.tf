resource "local_file" "hosts_cfg_kubespray" {
  count = var.exclude_ansible ? 0 : 1

  content  = templatefile("${path.module}/hosts.tftpl", {
    workers = yandex_compute_instance.worker-nodes
    masters = yandex_compute_instance.master-nodes
  })
  filename = "./kubespray/inventory/hosts.yaml"
}
