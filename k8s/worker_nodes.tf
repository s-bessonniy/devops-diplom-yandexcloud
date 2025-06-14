data "yandex_compute_image" "ubuntu-worker" {
  family = var.vm_image_worker
}

resource "yandex_compute_instance" "worker-nodes" {
  name        = "${var.worker_node_names}-${count.index + 1}"
  hostname    = "${var.worker_node_names}-${count.index + 1}"
  zone        = "${var.subnet-zones[count.index]}"
  metadata    = var.ssh_root_key
  platform_id = var.nodes_platform_id
  count = var.worker_nodes_size
  labels = {
  index = "${var.worker_node_names}-${count.index + 1}"
  }

  resources {
    cores         = var.nodes_resources.worker_nodes_resources.cores
    memory        = var.nodes_resources.worker_nodes_resources.memory
    core_fraction = var.nodes_resources.worker_nodes_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu-worker.image_id
      type     = var.boot_disk_worker_nodes[0].type
      size     = var.boot_disk_worker_nodes[0].size
    }
  }

  scheduling_policy {
    preemptible = var.vm_nat
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnets[count.index].id
    nat       = var.vm_nat
  }
}
